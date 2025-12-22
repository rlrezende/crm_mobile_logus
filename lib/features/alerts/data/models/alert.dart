import '../../../../core/utils/json_utils.dart';
import '../../domain/alert_enums.dart';

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class Alert {
  Alert({
    required this.id,
    required this.personId,
    required this.clientName,
    required this.type,
    required this.title,
    required this.referenceDate,
    required this.severity,
    required this.status,
    required this.createdDate,
    this.description,
    this.updatedDate,
    this.snoozedUntil,
    this.channelsSent = const [],
    this.daysFromReference,
    this.quietHoursActive = false,
  });

  final String id;
  final String personId;
  final String clientName;
  final AlertType type;
  final String title;
  final String? description;
  final DateTime referenceDate;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime createdDate;
  final DateTime? updatedDate;
  final DateTime? snoozedUntil;
  final List<String> channelsSent;
  final int? daysFromReference;
  final bool quietHoursActive;

  factory Alert.fromJson(Map<String, dynamic> json) {
    final channels = unwrapList(json['channelsSent']).map((e) => e.toString()).toList();
    return Alert(
      id: json['id'] as String,
      personId: json['pessoaId'] as String,
      clientName: json['clienteNome'] as String? ?? json['pessoa']?['nome'] as String? ?? '',
      type: AlertType.fromJson(json['type']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      referenceDate: _parseDate(json['referenceDate']) ?? DateTime.now().toUtc(),
      severity: AlertSeverity.fromJson(json['severity']),
      status: AlertStatus.fromJson(json['status']),
      createdDate: _parseDate(json['createdDate']) ?? DateTime.now().toUtc(),
      updatedDate: _parseDate(json['updatedDate']),
      snoozedUntil: _parseDate(json['snoozedUntil']),
      channelsSent: channels,
      daysFromReference: (json['daysFromReference'] as num?)?.toInt(),
      quietHoursActive: json['quietHoursActive'] as bool? ?? false,
    );
  }
}
