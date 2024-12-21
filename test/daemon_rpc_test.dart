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
}
