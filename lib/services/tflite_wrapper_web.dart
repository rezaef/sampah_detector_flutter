class Interpreter {
  static Future<Interpreter> fromAsset(String assetKey) {
    throw UnsupportedError('TFLite is not available on web.');
  }

  void run(Object input, Object output) {}

  void close() {}
}
