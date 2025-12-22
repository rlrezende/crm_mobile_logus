import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/storage/token_storage.dart';
import 'features/alerts/data/repositories/alert_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnv();
  final apiClient = ApiClient(
    baseUrl: config.apiBaseUrl,
    logNetworkTraffic: config.logNetworkTraffic,
  );
  final tokenStorage = TokenStorage();
  final authRepository = AuthRepository(apiClient: apiClient);
  final biometricService = BiometricAuthService();
  final alertRepository = AlertRepository(apiClient: apiClient);

  runApp(
    LogusCrmApp(
      config: config,
      apiClient: apiClient,
      authRepository: authRepository,
      tokenStorage: tokenStorage,
      biometricAuthService: biometricService,
      alertRepository: alertRepository,
    ),
  );
}
