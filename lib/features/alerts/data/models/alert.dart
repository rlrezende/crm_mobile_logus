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

T? _access<T>(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key] as T?;
  }
  final pascalKey = '${key[0].toUpperCase()}${key.substring(1)}';
  if (json.containsKey(pascalKey)) {
    return json[pascalKey] as T?;
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
    final channels = unwrapList(json['channelsSent'] ?? json['ChannelsSent']).map((e) => e.toString()).toList();
    return Alert(
      id: _access<String>(json, 'id') ?? '',
      personId: _access<String>(json, 'pessoaId') ?? '',
      clientName: _access<String>(json, 'clienteNome') ??
          (json['pessoa']?['nome'] as String? ?? ''),
      type: AlertType.fromJson(json['type'] ?? json['Type']),
      title: _access<String>(json, 'title') ?? '',
      description: _access<String>(json, 'description'),
      referenceDate: _parseDate(json['referenceDate'] ?? json['ReferenceDate']) ?? DateTime.now().toUtc(),
      severity: AlertSeverity.fromJson(json['severity'] ?? json['Severity']),
      status: AlertStatus.fromJson(json['status'] ?? json['Status']),
      createdDate: _parseDate(json['createdDate'] ?? json['CreatedDate']) ?? DateTime.now().toUtc(),
      updatedDate: _parseDate(json['updatedDate'] ?? json['UpdatedDate']),
      snoozedUntil: _parseDate(json['snoozedUntil'] ?? json['SnoozedUntil']),
      channelsSent: channels,
      daysFromReference: (json['daysFromReference'] as num? ??
              json['DaysFromReference'] as num?)
          ?.toInt(),
      quietHoursActive: (json['quietHoursActive'] as bool?) ??
          (json['QuietHoursActive'] as bool?) ??
          false,
    );
  }
}
