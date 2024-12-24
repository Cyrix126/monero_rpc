import 'dart:convert';

// Only import digest_auth if credentials are needed.
// This is optional; you can leave the import and just skip using it if username/password are null.
import 'package:digest_auth/digest_auth.dart';
import 'package:http/http.dart' as http;

import 'models/get_outs_response.dart';

class DaemonRpc {
  final String rpcUrl;
  final String? username;
  final String? password;
  final http.Client client;
  late final String baseUrl;

  DaemonRpc(this.client, this.rpcUrl, {String? username, String? password})
      : username =
            (username != null && username.trim().isNotEmpty) ? username : null,
        password =
            (password != null && password.trim().isNotEmpty) ? password : null {
    // Extract base URL from the rpcUrl.
    final Uri rpcUri = Uri.parse(rpcUrl);
    baseUrl = '${rpcUri.scheme}://${rpcUri.authority}';
  }

  /// Perform a JSON-RPC call.  If username and password are provided, use
  /// digest authentication.  Otherwise, just do a single request without auth.
  Future<Map<String, dynamic>> call(
      String method, Map<String, dynamic> params) async {
    final String rpcUrl = this.rpcUrl;

    // If credentials not provided, just try one request without auth.
    if (username == null || password == null) {
      final response = await client.post(
        Uri.parse(rpcUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': '0',
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('RPC call failed: ${response.body}');
      }

      final Map<String, dynamic> result = jsonDecode(response.body);
      if (result['error'] != null) {
        throw Exception('RPC Error: ${result['error']}');
      }

      return result['result'];
    }

    // Digest authentication flow if credentials are available.
    final DigestAuth digestAuth = DigestAuth(username!, password!);

    // Initial request to get the `WWW-Authenticate` header.
    final initialResponse = await client.post(
      Uri.parse(rpcUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': '0',
        'method': method,
        'params': params,
      }),
    );

    if (initialResponse.statusCode != 401 ||
        !initialResponse.headers.containsKey('www-authenticate')) {
      throw Exception('Unexpected response: ${initialResponse.body}');
    }

    // Extract Digest details from `WWW-Authenticate` header.
    final String authInfo = initialResponse.headers['www-authenticate']!;
    digestAuth.initFromAuthorizationHeader(authInfo);

    // Create Authorization header for the second request.
    String uri = Uri.parse(rpcUrl).path;
    String authHeader = digestAuth.getAuthString('POST', uri);

    // Make the authenticated request.
    final authenticatedResponse = await client.post(
      Uri.parse(rpcUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': '0',
        'method': method,
        'params': params,
      }),
    );

    if (authenticatedResponse.statusCode != 200) {
      throw Exception('RPC call failed: ${authenticatedResponse.body}');
    }

    final Map<String, dynamic> result = jsonDecode(authenticatedResponse.body);
    if (result['error'] != null) {
      throw Exception('RPC Error: ${result['error']}');
    }

    return result['result'];
  }

  /// Perform a direct HTTP POST request to an endpoint.
  ///
  /// If credentials are provided, use digest authentication.
  Future<Map<String, dynamic>> postToEndpoint(
      String endpoint, Map<String, dynamic> params) async {
    final fullUrl = '$baseUrl$endpoint';

    // Initial request
    final response = await client.post(
      Uri.parse(fullUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );

    // If 200 response, return decoded body
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    // Only proceed with auth if credentials provided and got 401
    if ((username == null || password == null) || response.statusCode != 401) {
      throw Exception('Call to $endpoint failed: ${response.body}');
    }

    if (!response.headers.containsKey('www-authenticate')) {
      throw Exception(
          'Authentication required but no WWW-Authenticate header received');
    }

    // With credentials, proceed with digest authentication.
    final DigestAuth digestAuth = DigestAuth(username!, password!);
    final String authInfo = response.headers['www-authenticate']!;
    digestAuth.initFromAuthorizationHeader(authInfo);

    // Create Authorization header for the second request.
    String uri = Uri.parse(fullUrl).path;
    String authHeader = digestAuth.getAuthString('POST', uri);

    // Make the authenticated request.
    final authenticatedResponse = await client.post(
      Uri.parse(fullUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode(params),
    );

    if (authenticatedResponse.statusCode != 200) {
      throw Exception(
          'Call to $endpoint failed: ${authenticatedResponse.body}');
    }

    return jsonDecode(authenticatedResponse.body) as Map<String, dynamic>;
  }

  Future<GetOutsResponse> getOut(int index) async {
    final response = await postToEndpoint('/get_outs', {
      'get_txid': true,
      'outputs': [
        {'index': index},
      ],
    });

    // Now deserialize into our model.
    return GetOutsResponse.fromJson(response);
  }

  /// Get a list of outputs by their absolute key offsets.
  ///
  /// The key offsets parameter is a list of integers representing the absolute
  /// key offsets of the outputs to retrieve.  Critically, the key_offsets as
  /// would be deserialized from a transaction are relative.  Use the
  /// convertRelativeToAbsolute helper function to convert the relative offsets
  /// from a parsed tx to the absolute ones needed by /get_outs..
  Future<GetOutsResponse> getOuts(List<int> keyOffsets) async {
    final outputs = keyOffsets.map((offset) => {'index': offset}).toList();

    final response = await postToEndpoint('/get_outs', {
      'get_txid': true,
      'outputs': outputs,
    });

    return GetOutsResponse.fromJson(response);
  }

  /// Raw request ready for a JSON-RPC call with authentication if the Authorization value is provided
  ///
  /// The raw request without authentication can be used to retrieve the Authenticate response header
  /// needed to generate the Authorization value.
  static String rawRequestRpc(
      Uri rpcUri, String method, Map<String, dynamic> params,
      [String? authHeaderValue]) {
    final body = jsonEncode(
        {"jsonrpc": "2.0", "id": "0", "method": method, "params": params});
    final authHeader =
        (authHeaderValue != null) ? 'Authorization: $authHeaderValue\r\n' : '';
    return 'POST /json_rpc HTTP/1.1\r\n'
        'Host: ${rpcUri.host}\r\n'
        '$authHeader'
        'Content-Type: application/json\r\n'
        'Content-Length: ${body.length}\r\n'
        '\r\n'
        '$body';
  }
}
