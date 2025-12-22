import '../../data/models/login_response.dart';

class AuthSession {
  AuthSession({
    required this.email,
    required this.response,
  });

  final String email;
  final LoginResponse response;

  String get token => response.token;
  DateTime get expiresAt => response.expiresAt;
  UserProfile get user => response.user;

  Map<String, dynamic> toJson() => {
        'email': email,
        'response': response.toJson(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      email: json['email'] as String,
      response: LoginResponse.fromJson(json['response'] as Map<String, dynamic>),
    );
  }
}
