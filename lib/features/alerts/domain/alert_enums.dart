import '../../../core/utils/json_utils.dart';

enum AlertType {
  procuracaoVencida('PROCURACAO_VENCIDA'),
  suitabilityVencido('SUITABILITY_VENCIDO'),
  aniversario('ANIVERSARIO'),
  outro('OUTRO');

  const AlertType(this.apiValue);
  final String apiValue;

  static const _map = {
    'PROCURACAO_VENCIDA': AlertType.procuracaoVencida,
    '1': AlertType.procuracaoVencida,
    'SUITABILITY_VENCIDO': AlertType.suitabilityVencido,
    '2': AlertType.suitabilityVencido,
    'ANIVERSARIO': AlertType.aniversario,
    '3': AlertType.aniversario,
    'OUTRO': AlertType.outro,
    '99': AlertType.outro,
  };

  static AlertType fromJson(dynamic value) {
    return resolveEnum(value, _map) ?? AlertType.outro;
  }

  String get label {
    switch (this) {
      case AlertType.procuracaoVencida:
        return 'Procuração vencida';
      case AlertType.suitabilityVencido:
        return 'Suitability vencido';
      case AlertType.aniversario:
        return 'Aniversário';
      case AlertType.outro:
        return 'Outro';
    }
  }
}

enum AlertSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const AlertSeverity(this.apiValue);
  final String apiValue;

  static const _map = {
    'LOW': AlertSeverity.low,
    '1': AlertSeverity.low,
    'MEDIUM': AlertSeverity.medium,
    '2': AlertSeverity.medium,
    'HIGH': AlertSeverity.high,
    '3': AlertSeverity.high,
  };

  static AlertSeverity fromJson(dynamic value) {
    return resolveEnum(value, _map) ?? AlertSeverity.low;
  }

  String get label {
    switch (this) {
      case AlertSeverity.low:
        return 'Baixo';
      case AlertSeverity.medium:
        return 'Médio';
      case AlertSeverity.high:
        return 'Alto';
    }
  }
}

enum AlertStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  snoozed('SNOOZED'),
  ignored('IGNORED');

  const AlertStatus(this.apiValue);
  final String apiValue;

  static const _map = {
    'PENDING': AlertStatus.pending,
    '1': AlertStatus.pending,
    'IN_PROGRESS': AlertStatus.inProgress,
    '2': AlertStatus.inProgress,
    'RESOLVED': AlertStatus.resolved,
    '3': AlertStatus.resolved,
    'SNOOZED': AlertStatus.snoozed,
    '4': AlertStatus.snoozed,
    'IGNORED': AlertStatus.ignored,
    '5': AlertStatus.ignored,
  };

  static AlertStatus fromJson(dynamic value) {
    return resolveEnum(value, _map) ?? AlertStatus.pending;
  }

  String get label {
    switch (this) {
      case AlertStatus.pending:
        return 'Pendente';
      case AlertStatus.inProgress:
        return 'Em andamento';
      case AlertStatus.resolved:
        return 'Resolvido';
      case AlertStatus.snoozed:
        return 'Adiado';
      case AlertStatus.ignored:
        return 'Ignorado';
    }
  }
}

enum AlertListPeriod {
  all('ALL'),
  overdue('OVERDUE'),
  nextSeven('NEXT_7'),
  today('TODAY');

  const AlertListPeriod(this.apiValue);
  final String apiValue;
}

enum NotificationDeliveryMode {
  imediato('IMEDIATO'),
  digest('DIGEST');

  const NotificationDeliveryMode(this.apiValue);
  final String apiValue;

  static const _map = {
    'IMEDIATO': NotificationDeliveryMode.imediato,
    'DIGEST': NotificationDeliveryMode.digest,
  };

  static NotificationDeliveryMode fromJson(dynamic value) {
    return resolveEnum(value, _map) ?? NotificationDeliveryMode.imediato;
  }

  String get label {
    switch (this) {
      case NotificationDeliveryMode.imediato:
        return 'Imediato';
      case NotificationDeliveryMode.digest:
        return 'Resumo diário';
    }
  }
}
