import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

String _hmacSha256Hex(List<int> key, List<int> message) {
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(message);
  return digest.toString();
}

List<int> _hmacSha256(List<int> key, List<int> message) {
  final hmac = Hmac(sha256, key);
  return hmac.convert(message).bytes;
}

String _formatDate(int timestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Map<String, String> buildDnspodHeaders({
  required String secretId,
  required String secretKey,
  required String action,
  required Map<String, dynamic> payload,
  String service = 'dnspod',
  String host = 'dnspod.tencentcloudapi.com',
  String version = '2021-03-23',
  String region = 'ap-guangzhou',
}) {
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final date = _formatDate(timestamp);

  const httpRequestMethod = 'POST';
  const canonicalUri = '/';
  const canonicalQueryString = '';
  const contentType = 'application/json; charset=utf-8';

  final payloadString = jsonEncode(payload);
  final hashedRequestPayload = sha256.convert(utf8.encode(payloadString)).toString();

  final canonicalHeaders = 'content-type:$contentType\nhost:$host\nx-tc-action:${action.toLowerCase()}\n';
  const signedHeaders = 'content-type;host;x-tc-action';

  final canonicalRequest = '$httpRequestMethod\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders$signedHeaders\n$hashedRequestPayload';

  final credentialScope = '$date/$service/tc3_request';
  final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();

  const algorithm = 'TC3-HMAC-SHA256';
  final stringToSign = '$algorithm\n$timestamp\n$credentialScope\n$hashedCanonicalRequest';

  final secretDate = _hmacSha256(utf8.encode('TC3$secretKey'), utf8.encode(date));
  final secretService = _hmacSha256(secretDate, utf8.encode(service));
  final secretSigning = _hmacSha256(secretService, utf8.encode('tc3_request'));
  final signature = _hmacSha256Hex(secretSigning, utf8.encode(stringToSign));

  final authorization = 'TC3-HMAC-SHA256 Credential=$secretId/$credentialScope, '
      'SignedHeaders=$signedHeaders, Signature=$signature';

  return {
    'Content-Type': contentType,
    'Host': host,
    'X-TC-Action': action,
    'X-TC-Version': version,
    'X-TC-Timestamp': timestamp.toString(),
    'X-TC-Region': region,
    'Authorization': authorization,
  };
}