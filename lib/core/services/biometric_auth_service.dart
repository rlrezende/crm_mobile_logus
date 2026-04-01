import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind {
  none,
  face,
  fingerprint,
  generic,
}

class BiometricAvailability {
  const BiometricAvailability({
    required this.available,
    required this.kind,
  });

  const BiometricAvailability.unavailable()
      : available = false,
        kind = BiometricKind.none;

  final bool available;
  final BiometricKind kind;
}

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuthentication})
      : _localAuth = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  bool get _isSupportedPlatform => !kIsWeb;

  Future<BiometricAvailability> getAvailability() async {
    if (!_isSupportedPlatform) {
      return const BiometricAvailability.unavailable();
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      if (!canCheck || !supported) {
        return const BiometricAvailability.unavailable();
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return const BiometricAvailability.unavailable();
      }

      return BiometricAvailability(
        available: true,
        kind: _resolveKind(availableBiometrics),
      );
    } on PlatformException {
      return const BiometricAvailability.unavailable();
    } on MissingPluginException {
      return const BiometricAvailability.unavailable();
    }
  }

  Future<bool> isAvailable() async {
    final availability = await getAvailability();
    return availability.available;
  }

  Future<bool> authenticate({String? reason}) async {
    if (!_isSupportedPlatform) {
      return false;
    }

    try {
      final availability = await getAvailability();
      if (!availability.available) {
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

  BiometricKind _resolveKind(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricKind.face;
    }

    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricKind.fingerprint;
    }

    if (availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.weak)) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return BiometricKind.face;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.generic;
    }

    return BiometricKind.generic;
  }
}
