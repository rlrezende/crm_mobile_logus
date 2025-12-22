class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.logNetworkTraffic,
  });

  factory AppConfig.fromEnv() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5283/api',
    );
    const logNetworkTraffic = bool.fromEnvironment('LOG_NETWORK', defaultValue: false);

    return const AppConfig(
      apiBaseUrl: apiBaseUrl,
      logNetworkTraffic: logNetworkTraffic,
    );
  }

  final String apiBaseUrl;
  final bool logNetworkTraffic;
}
