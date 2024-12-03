import 'package:monero_rpc/src/daemon_rpc.dart';

void main() async {
  final daemonRpc = DaemonRpc(
    'http://localhost:18081/json_rpc', // Replace with your Monero daemon URL.
    username: 'user', // Replace with your username.
    password: 'password', // Replace with your password.
  );

  try {
    // Call get_info via /json_rpc.
    final infoResult = await daemonRpc.call('get_info', {});
    print('get_info response:');
    print(infoResult);

    // Call get_transactions via direct endpoint.
    final txsResult = await daemonRpc.postToEndpoint('/get_transactions', {
      'txs_hashes': [
        'd6e48158472848e6687173a91ae6eebfa3e1d778e65252ee99d7515d63090408'
      ],
      'decode_as_json': true,
    });
    print('get_transactions response:');
    print(txsResult);
  } catch (e) {
    print('Error: $e');
  }
}
