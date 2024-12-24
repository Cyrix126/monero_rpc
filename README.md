# `monero_rpc`

Monero JSON-RPC API wrapper in Dart.

## Getting started

```
dart pub add monero_rpc
```

## Usage

```
import 'package:http/http.dart';
import 'package:monero_rpc/src/daemon_rpc.dart';

void main() async {
  final daemonRpc = DaemonRpc(Client(),
    'http://localhost:18081/json_rpc', // Replace with your Monero daemon URL.
    username: 'user', // Replace with your username.
    password: 'password', // Replace with your password.
  );

  try {
    final result = await daemonRpc.call('get_info', {});
    print('get_info response:');
    print(result);
  } catch (e) {
    print('Error: $e');
  }
}
```
