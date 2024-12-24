import 'package:http/http.dart';
import 'package:monero_rpc/src/daemon_rpc.dart';
import 'package:test/test.dart';

void main() {
  test('WalletRpc call method', () async {
    final walletRpc = DaemonRpc(
      Client(),
      'http://localhost:18081/json_rpc',
      username: 'user',
      password: 'password',
    );

    final result = await walletRpc.call('get_info', {});
    expect(result, isA<Map<String, dynamic>>());
  });
  test('Raw request without authentication', () {
    expect(
        DaemonRpc.rawRequestRpc(
            Uri.parse('http://localhost:18081'), 'get_info', {}),
        'POST /json_rpc HTTP/1.1\r\n'
        'Host: localhost\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: 58\r\n'
        '\r\n'
        '{"jsonrpc":"2.0","id":"0","method":"get_info","params":{}}');
  });
  test('Raw request with authentication', () {
    final authorizationHeaderValue =
        'Digest username="user", realm="monero-rpc", nonce="test", uri="http://localhost:18081", qop=auth, nc=00000001, cnonce="test", response="test"';
    expect(
        DaemonRpc.rawRequestRpc(Uri.parse('http://localhost:18081'), 'get_info',
            {}, authorizationHeaderValue),
        'POST /json_rpc HTTP/1.1\r\n'
        'Host: localhost\r\n'
        'Authorization: $authorizationHeaderValue\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: 58\r\n'
        '\r\n'
        '{"jsonrpc":"2.0","id":"0","method":"get_info","params":{}}');
  });
}
