## 1.3.1

- Fix get_outs with an unauthenticated node.

## 1.3.0

- Make RPC digest authentication optional and update demo to use public node.

## 1.2.0

- Add helper functions for /get_outs: getOut and getOuts with response model.
- Add utility function for converting relative key offsets (as would be parsed 
  from a transaction) to absolute key offsets (as would be used in /get_outs).

## 1.1.0

- Support direct endpoints (eg. /get_transactions vs. /json_rpc).

## 1.0.0

- Initial version.
- Monero JSON-RPC API wrapper in Dart.
