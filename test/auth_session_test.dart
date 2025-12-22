import 'package:crm_mobile_logus/features/auth/data/models/login_response.dart';
import 'package:crm_mobile_logus/features/auth/domain/models/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthSession serializa e restaura corretamente', () {
    final response = LoginResponse(
      token: 'token',
      expiresAt: DateTime.utc(2030, 1, 1),
      user: UserProfile(
        id: '1',
        username: 'admin',
        email: 'admin@logus.com',
        active: true,
        person: PersonProfile(
          id: 'p1',
          name: 'Usuário Admin',
          email: 'admin@logus.com',
        ),
        profile: PerfilProfile(
          id: 'pf1',
          name: 'Administrador',
          description: 'Perfil completo',
          modules: [
            ModuloProfile(
              id: 'm1',
              name: 'Alertas',
              description: 'Dashboard de alertas',
              canView: true,
              canEdit: true,
              canDelete: false,
            ),
          ],
        ),
      ),
    );

    final session = AuthSession(email: 'admin@logus.com', response: response);
    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.email, equals(session.email));
    expect(restored.response.token, equals(response.token));
    expect(restored.user.profile.modules.first.name, equals('Alertas'));
  });
}
