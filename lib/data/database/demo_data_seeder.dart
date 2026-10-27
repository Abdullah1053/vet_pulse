class DemoDataSeeder {
  DemoDataSeeder._();

  /// Strict no-op in production: guarantees fresh installation has 0 demo records.
  static Future<void> seedIfEmpty() async {}

  /// Strict no-op in production.
  static Future<void> resetDemoData() async {}

  /// Strict no-op in production.
  static Future<void> populateDemoData() async {}
}
