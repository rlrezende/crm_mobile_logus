import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/storage/token_storage.dart';
import 'features/alerts/data/repositories/alert_repository.dart';
import 'features/alerts/presentation/pages/dashboard_page.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/data/repositories/customer_dashboard_repository.dart';
import 'features/suitability/data/repositories/suitability_repository.dart';
import 'features/suitability/presentation/controllers/suitability_controller.dart';

class LogusCrmApp extends StatelessWidget {
  const LogusCrmApp({
    super.key,
    required this.config,
    required this.apiClient,
    required this.authRepository,
    required this.tokenStorage,
    required this.biometricAuthService,
    required this.alertRepository,
  });

  final AppConfig config;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final BiometricAuthService biometricAuthService;
  final AlertRepository alertRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: config),
        Provider.value(value: apiClient),
        Provider.value(value: alertRepository),
        Provider(
          create: (_) => SuitabilityRepository(apiClient: apiClient),
        ),
        Provider(
          create: (_) => CustomerDashboardRepository(apiClient: apiClient),
        ),
        Provider.value(value: tokenStorage),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authRepository: authRepository,
            tokenStorage: tokenStorage,
            biometricAuthService: biometricAuthService,
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SuitabilityController(
            repository: context.read<SuitabilityRepository>(),
          ),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (_, controller, __) {
          return MaterialApp(
            title: 'Logus CRM Mobile',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF01579B)),
              useMaterial3: true,
            ),
            home: _resolveHome(controller),
          );
        },
      ),
    );
  }

  Widget _resolveHome(AuthController controller) {
    if (controller.status == AuthStatus.authenticated) {
      return const DashboardPage();
    }
    return const LoginPage();
  }
}
