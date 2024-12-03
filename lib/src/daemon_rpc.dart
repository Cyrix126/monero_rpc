import 'dart:convert';
import 'dart:math' as math;

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// HTTP Digest authentication.
///
/// Adapted from https://github.com/dart-lang/http/issues/605#issue-963962341.
///
/// Created because http_auth was not working for Monero daemon RPC responses.
///
/// This could be spun out into its own package ("digest_auth", anyone?).
class DigestAuth {
  final String username;
  final String password;
  String? realm;
  String? nonce;
  String? uri;
  String? qop = "auth";

  DigestAuth(this.username, this.password);

  /// Initialize Digest parameters from the `WWW-Authenticate` header.
  void initFromAuthorizationHeader(String authInfo) {
    final Map<String, String>? values = _splitAuthenticateHeader(authInfo);
    if (values != null) {
      realm = values['realm'];
      nonce = values['nonce'];
    }
  }

  /// Generate the Digest Authorization header.
  String getAuthString(String method, String uri, int nonceCount) {
    this.uri = uri;
    String cnonce = _computeCnonce();
    String nc = _formatNonceCount(nonceCount);

    String ha1 = md5Hash("$username:$realm:$password");
    String ha2 = md5Hash("$method:$uri");
    String response = md5Hash("$ha1:$nonce:$nc:$cnonce:$qop:$ha2");

    return 'Digest username="$username", realm="$realm", nonce="$nonce", uri="$uri", qop=$qop, nc=$nc, cnonce="$cnonce", response="$response"';
  }

  /// Helper to parse the `WWW-Authenticate` header.
  Map<String, String>? _splitAuthenticateHeader(String? header) {
    if (header == null || !header.startsWith('Digest ')) {
      return null;
    }
    String token = header.substring(7); // remove 'Digest '
    final Map<String, String> result = {};

    final components = token.split(',').map((token) => token.trim());
    for (final component in components) {
      final kv = component.split('=');
      result[kv[0]] = kv.getRange(1, kv.length).join('=').replaceAll('"', '');
    }
    return result;
  }

  /// Helper to compute a random cnonce.
  String _computeCnonce() {
    final math.Random rnd = math.Random();
    final List<int> values = List<int>.generate(16, (i) => rnd.nextInt(256));
    return hex.encode(values);
  }

  /// Helper to format the nonce count.
  String _formatNonceCount(int count) =>
      count.toRadixString(16).padLeft(8, '0');

  /// Compute the MD5 hash of a string.
  String md5Hash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }
}

class DaemonRpc {
  final String rpcUrl;
  final String username;
  final String password;

  DaemonRpc(this.rpcUrl, {required this.username, required this.password});

  /// Perform a JSON-RPC call with Digest Authentication.
  Future<Map<String, dynamic>> call(
      String method, Map<String, dynamic> params) async {
    final http.Client client = http.Client();
    final DigestAuth digestAuth = DigestAuth(username, password);

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
    int nonceCount = 1; // Start with 1 and increment for subsequent requests.
    String authHeader = digestAuth.getAuthString('POST', uri, nonceCount);

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
}
