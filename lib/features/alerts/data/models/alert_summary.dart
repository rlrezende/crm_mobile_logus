class AlertSummary {
  AlertSummary({
    required this.totalActive,
    required this.critical,
    required this.overdueSevenDays,
    required this.nextSevenDays,
    required this.byType,
    required this.byStatus,
  });

  final int totalActive;
  final int critical;
  final int overdueSevenDays;
  final int nextSevenDays;
  final Map<String, int> byType;
  final Map<String, int> byStatus;

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> mapFromJson(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value.map(
          (key, count) => MapEntry(key, (count as num).toInt()),
        );
      }
      return {};
    }

    return AlertSummary(
      totalActive: (json['totalAtivos'] as num?)?.toInt() ?? 0,
      critical: (json['criticos'] as num?)?.toInt() ?? 0,
      overdueSevenDays:
          (json['vencidosHaMaisDeSeteDias'] as num?)?.toInt() ?? 0,
      nextSevenDays: (json['proximosSeteDias'] as num?)?.toInt() ?? 0,
      byType: mapFromJson(json['alertasPorTipo']),
      byStatus: mapFromJson(json['alertasPorStatus']),
    );
  }
}
