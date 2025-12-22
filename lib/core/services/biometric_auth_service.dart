import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuthentication})
      : _localAuth = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  bool get _isSupportedPlatform => !kIsWeb;

  Future<bool> isAvailable() async {
    if (!_isSupportedPlatform) {
      return false;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> authenticate({String? reason}) async {
    if (!_isSupportedPlatform) {
      return false;
    }
    try {
      final available = await isAvailable();
      if (!available) {
        return false;
      }
      return _localAuth.authenticate(
        localizedReason: reason ?? 'Confirme sua identidade para continuar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
