import 'dart:convert';

import 'package:digest_auth/digest_auth.dart';
import 'package:http/http.dart' as http;

class DaemonRpc {
  final String rpcUrl;
  final String username;
  final String password;
  late final String baseUrl;

  DaemonRpc(this.rpcUrl, {required this.username, required this.password}) {
    // Extract base URL from the rpcUrl.
    final Uri rpcUri = Uri.parse(rpcUrl);
    baseUrl = '${rpcUri.scheme}://${rpcUri.authority}';
  }

  /// Perform a JSON-RPC call with Digest Authentication.
  Future<Map<String, dynamic>> call(
      String method, Map<String, dynamic> params) async {
    final http.Client client = http.Client();
    final DigestAuth digestAuth = DigestAuth(username, password);

    // Use rpcUrl directly.
    final String rpcUrl = this.rpcUrl;

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

  /// Perform a direct HTTP POST request with Digest Authentication.
  Future<Map<String, dynamic>> postToEndpoint(
      String endpoint, Map<String, dynamic> params) async {
    final http.Client client = http.Client();
    final DigestAuth digestAuth = DigestAuth(username, password);

    final fullUrl = '$baseUrl$endpoint';

    // Initial request to get the `WWW-Authenticate` header.
    final initialResponse = await client.post(
      Uri.parse(fullUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(params),
    );

    if (initialResponse.statusCode != 401 ||
        !initialResponse.headers.containsKey('www-authenticate')) {
      throw Exception('Unexpected response: ${initialResponse.body}');
    }

    // Extract Digest details from `WWW-Authenticate` header.
    final String authInfo = initialResponse.headers['www-authenticate']!;
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

    final Map<String, dynamic> result = jsonDecode(authenticatedResponse.body);

    return result;
  }
}
