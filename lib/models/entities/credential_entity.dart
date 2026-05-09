class CredentialEntity {
  final String provider;
  final String apiKey;
  final String? apiSecret;
  final String? email;

  CredentialEntity({
    required this.provider,
    required this.apiKey,
    this.apiSecret,
    this.email,
  });
}