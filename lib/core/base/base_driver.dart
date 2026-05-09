abstract class BaseDriver {
  String get providerName;
  bool get isInitialized;

  Future<void> initialize(Map<String, String> credentials);
  Future<bool> validateCredentials();
  void dispose();
}