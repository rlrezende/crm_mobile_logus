import '../../../../core/utils/json_utils.dart';
import '../../domain/alert_enums.dart';

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
  final Map<AlertType, int> byType;
  final Map<AlertStatus, int> byStatus;

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      totalActive: (json['totalAtivos'] as num?)?.toInt() ??
          (json['TotalAtivos'] as num?)?.toInt() ??
          0,
      critical: (json['criticos'] as num?)?.toInt() ??
          (json['Criticos'] as num?)?.toInt() ??
          0,
      overdueSevenDays: (json['vencidosHaMaisDeSeteDias'] as num?)?.toInt() ??
          (json['VencidosHaMaisDeSeteDias'] as num?)?.toInt() ??
          0,
      nextSevenDays: (json['proximosSeteDias'] as num?)?.toInt() ??
          (json['ProximosSeteDias'] as num?)?.toInt() ??
          0,
      byType: decodeEnumCounts(
        json['alertasPorTipo'] ?? json['AlertasPorTipo'],
        AlertType.values.asValueMap(),
      ),
      byStatus: decodeEnumCounts(
        json['alertasPorStatus'] ?? json['AlertasPorStatus'],
        AlertStatus.values.asValueMap(),
      ),
    );
  }
}

extension _EnumListMapper<T extends Enum> on List<T> {
  Map<String, T> asValueMap() {
    final map = <String, T>{};
    for (final entry in this) {
      if (entry is AlertType) {
        map[entry.apiValue] = entry;
      } else if (entry is AlertStatus) {
        map[entry.apiValue] = entry;
      }
    }
    return map;
  }
}
