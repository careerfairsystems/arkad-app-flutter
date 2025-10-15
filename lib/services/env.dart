class Env {
  String combainApiKey = "";
  String combainServiceToken = "";
  Env() {
    // Constructor
    combainApiKey = const String.fromEnvironment(
      'COMBAIN_API_KEY',
      defaultValue: '',
    );
    if (combainApiKey.isEmpty) {
      throw Exception("COMBAIN_API_KEY is not set");
    }
    combainServiceToken = const String.fromEnvironment(
      'COMBAIN_SERVICE_TOKEN',
      defaultValue: '',
    );
    if (combainServiceToken.isEmpty) {
      throw Exception("COMBAIN_SERVICE_TOKEN is not set");
    }
  }
}
