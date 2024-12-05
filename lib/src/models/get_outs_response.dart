class GetOutsResponse {
  final int credits;
  final List<OutEntry> outs;
  final String status;
  final String topHash;
  final bool untrusted;

  GetOutsResponse({
    required this.credits,
    required this.outs,
    required this.status,
    required this.topHash,
    required this.untrusted,
  });

  factory GetOutsResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('credits') ||
        json['credits'] == null ||
        json['credits'] is! int) {
      throw Exception("Invalid 'credits' field in response.");
    }
    if (!json.containsKey('outs') ||
        json['outs'] == null ||
        json['outs'] is! List) {
      throw Exception("Invalid 'outs' field in response.");
    }
    if (!json.containsKey('status') ||
        json['status'] == null ||
        json['status'] is! String) {
      throw Exception("Invalid 'status' field in response.");
    }
    if (!json.containsKey('top_hash') ||
        json['top_hash'] == null ||
        json['top_hash'] is! String) {
      throw Exception("Invalid 'top_hash' field in response.");
    }
    if (!json.containsKey('untrusted') ||
        json['untrusted'] == null ||
        json['untrusted'] is! bool) {
      throw Exception("Invalid 'untrusted' field in response.");
    }

    final outsList = (json['outs'] as List).map((outJson) {
      if (outJson is Map<String, dynamic>) {
        return OutEntry.fromJson(outJson);
      } else {
        throw Exception("Invalid format for 'outs' entry.");
      }
    }).toList();

    return GetOutsResponse(
      credits: json['credits'] as int,
      outs: outsList,
      status: json['status'] as String,
      topHash: json['top_hash'] as String,
      untrusted: json['untrusted'] as bool,
    );
  }
}

class OutEntry {
  final int height;
  final String key;
  final String mask;
  final String txid;
  final bool unlocked;

  OutEntry({
    required this.height,
    required this.key,
    required this.mask,
    required this.txid,
    required this.unlocked,
  });

  factory OutEntry.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('height') ||
        json['height'] == null ||
        json['height'] is! int) {
      throw Exception("Invalid 'height' field in out entry.");
    }
    if (!json.containsKey('key') ||
        json['key'] == null ||
        json['key'] is! String) {
      throw Exception("Invalid 'key' field in out entry.");
    }
    if (!json.containsKey('mask') ||
        json['mask'] == null ||
        json['mask'] is! String) {
      throw Exception("Invalid 'mask' field in out entry.");
    }
    if (!json.containsKey('txid') ||
        json['txid'] == null ||
        json['txid'] is! String) {
      throw Exception("Invalid 'txid' field in out entry.");
    }
    if (!json.containsKey('unlocked') ||
        json['unlocked'] == null ||
        json['unlocked'] is! bool) {
      throw Exception("Invalid 'unlocked' field in out entry.");
    }

    return OutEntry(
      height: json['height'] as int,
      key: json['key'] as String,
      mask: json['mask'] as String,
      txid: json['txid'] as String,
      unlocked: json['unlocked'] as bool,
    );
  }
}
