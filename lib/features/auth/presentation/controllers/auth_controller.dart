import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/auth_session.dart';

enum AuthStatus {
  unauthenticated,
  loading,
  authenticated,
  needsBiometrics,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required BiometricAuthService biometricAuthService,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _tokenStorage = tokenStorage,
        _biometricAuthService = biometricAuthService,
        _apiClient = apiClient {
    _bootstrap();
  }

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final BiometricAuthService _biometricAuthService;
  final ApiClient _apiClient;

  AuthStatus status = AuthStatus.unauthenticated;
  String? errorMessage;
  AuthSession? _cachedSession;
  AuthSession? _activeSession;
  bool _biometricsAvailable = false;

  UserProfile? get currentUser => _activeSession?.user;
  String? get lastUsedEmail => _cachedSession?.email;
  bool get isLoading => status == AuthStatus.loading;
  bool get canUseBiometrics => _biometricsAvailable && _cachedSession != null;

  Future<void> _bootstrap() async {
    _biometricsAvailable = await _biometricAuthService.isAvailable();
    final storedSession = await _tokenStorage.readSession();

    if (storedSession != null && !_isExpired(storedSession.expiresAt)) {
      _cachedSession = storedSession;
      if (_biometricsAvailable) {
        status = AuthStatus.needsBiometrics;
      } else {
        _activateSession(storedSession);
      }
    } else if (storedSession != null) {
      await _tokenStorage.clearSession();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      errorMessage = 'Informe login e senha para continuar.';
      notifyListeners();
      return;
    }

    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.authenticate(
        LoginRequest(email: email, password: password),
      );
      final session = AuthSession(email: email, response: response);
      await _tokenStorage.saveSession(session);
      _cachedSession = session;
      _activateSession(session);
    } catch (error) {
      errorMessage = _mapError(error);
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> authenticateWithBiometrics() async {
    if (!canUseBiometrics) {
      errorMessage = 'Biometria indisponível neste dispositivo.';
      notifyListeners();
      return;
    }

    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    final approved = await _biometricAuthService.authenticate(
      reason: 'Confirme com Face ID / biometria para acessar o CRM Logus',
    );

    if (!approved) {
      status = AuthStatus.needsBiometrics;
      errorMessage = 'Autenticação biométrica cancelada.';
      notifyListeners();
      return;
    }

    final session = _cachedSession;
    if (session == null) {
      status = AuthStatus.unauthenticated;
      errorMessage = 'Nenhuma sessão salva. Faça login com usuário e senha.';
      notifyListeners();
      return;
    }

    if (_isExpired(session.expiresAt)) {
      await _tokenStorage.clearSession();
      _cachedSession = null;
      status = AuthStatus.unauthenticated;
      errorMessage = 'Sessão expirada. Realize o login novamente.';
      notifyListeners();
      return;
    }

    _activateSession(session);
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
    _cachedSession = null;
    _activeSession = null;
    _apiClient.updateAuthToken(null);
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  void _activateSession(AuthSession session) {
    _apiClient.updateAuthToken(session.token);
    _activeSession = session;
    status = AuthStatus.authenticated;
    errorMessage = null;
    notifyListeners();
  }

  bool _isExpired(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    return expiresAt.toUtc().isBefore(now);
  }

  String _mapError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Usuário ou senha inválidos.';
      }
      return error.message;
    }
    return 'Não foi possível autenticar. Verifique sua conexão.';
  }
}
