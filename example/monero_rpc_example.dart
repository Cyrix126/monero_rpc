import 'dart:convert';

import 'package:http/http.dart';
import 'package:monero_rpc/src/daemon_rpc.dart';
import 'package:monero_rpc/src/utils.dart';

void main() async {
  // Authenticated example:
  // final daemonRpc = DaemonRpc(Client(),
  //   'http://localhost:18081/json_rpc', // Replace with your Monero daemon URL.
  //   username: 'user', // Replace with your username.
  //   password: 'password', // Replace with your password.
  // );
  final client = Client();
  final daemonRpc =
      DaemonRpc(client, 'http://monero.stackwallet.com:18081/json_rpc');

  try {
    // Call get_info via /json_rpc.
    final infoResult = await daemonRpc.call('get_info', {});
    print('get_info response:');
    print(infoResult);
    print("\n\n\n");

    // Call get_transactions via direct endpoint.
    final txsResult = await daemonRpc.postToEndpoint('/get_transactions', {
      'txs_hashes': [
        'bb2bc1506c3793f4dce9eea951546f6e7388b21764beebe69ae9590d65a66649'
      ],
      'decode_as_json': true,
    });
    print('get_transactions response:');
    print(txsResult);
    print("\n\n\n");

    // Call get_outs via direct endpoint.
    final outsResponse = await daemonRpc.postToEndpoint(
      '/get_outs',
      {
        'get_txid': true,
        'outputs': [
          {'index': 5164903},
        ],
      },
    );
    print('get_outs response:');
    print(jsonEncode(outsResponse));

    // Call get_outs via helper method.
    try {
      final getOutResult = await daemonRpc.getOut(5164903);
      print('Height: ${getOutResult.outs.first.height}');
      print('TxID: ${getOutResult.outs.first.txid}');
    } catch (e) {
      print('Error: $e');
    }

    // Call get_outs via helper method with list of relative key offsets (as
    // deserialized from a transaction).
    try {
      final getOutsResult =
          await daemonRpc.getOuts(convertRelativeToAbsolute([5164903, 123]));
      print('Height: ${getOutsResult.outs.first.height}');
      print('TxID: ${getOutsResult.outs.first.txid}');
      print('Height: ${getOutsResult.outs.last.height}');
      print('TxID: ${getOutsResult.outs.last.txid}');
    } catch (e) {
      print('Error: $e');
    }
  } catch (e) {
    print('Error: $e');
  }
}
