class LoginResponse {
  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final UserProfile user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: UserProfile.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'usuario': user.toJson(),
      };
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.active,
    required this.person,
    required this.profile,
  });

  final String id;
  final String username;
  final String email;
  final bool active;
  final PersonProfile person;
  final PerfilProfile profile;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['nomeUsuario'] as String,
      email: json['email'] as String,
      active: json['ativo'] as bool,
      person: PersonProfile.fromJson(json['pessoa'] as Map<String, dynamic>),
      profile: PerfilProfile.fromJson(json['perfil'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeUsuario': username,
        'email': email,
        'ativo': active,
        'pessoa': person.toJson(),
        'perfil': profile.toJson(),
      };
}

class PersonProfile {
  PersonProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory PersonProfile.fromJson(Map<String, dynamic> json) {
    return PersonProfile(
      id: json['id'] as String,
      name: json['nome'] as String,
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': name,
        'email': email,
      };
}

class PerfilProfile {
  PerfilProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.modules,
  });

  final String id;
  final String name;
  final String description;
  final List<ModuloProfile> modules;

  factory PerfilProfile.fromJson(Map<String, dynamic> json) {
    final modulesJson = json['modulos'] as List<dynamic>? ?? [];
    return PerfilProfile(
      id: json['id'] as String,
      name: json['nome'] as String,
      description: json['descricao'] as String? ?? '',
      modules: modulesJson
          .map((module) => ModuloProfile.fromJson(module as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': name,
        'descricao': description,
        'modulos': modules.map((module) => module.toJson()).toList(),
      };
}

class ModuloProfile {
  ModuloProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String name;
  final String description;
  final bool canView;
  final bool canEdit;
  final bool canDelete;

  factory ModuloProfile.fromJson(Map<String, dynamic> json) {
    return ModuloProfile(
      id: json['id'] as String,
      name: json['nome'] as String,
      description: json['descricao'] as String? ?? '',
      canView: json['podeVisualizar'] as bool? ?? false,
      canEdit: json['podeEditar'] as bool? ?? false,
      canDelete: json['podeExcluir'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': name,
        'descricao': description,
        'podeVisualizar': canView,
        'podeEditar': canEdit,
        'podeExcluir': canDelete,
      };
}
