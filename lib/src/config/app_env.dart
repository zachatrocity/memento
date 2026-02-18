enum AppEnv {
  dev,
  stage,
  prod;

  static AppEnv fromString(String value) {
    return switch (value.toLowerCase()) {
      'dev' => AppEnv.dev,
      'stage' => AppEnv.stage,
      'prod' => AppEnv.prod,
      _ => AppEnv.dev,
    };
  }
}
