import '../../domain/alert_enums.dart';

class AlertFilters {
  const AlertFilters({
    this.type,
    this.severity,
    this.status,
    this.period = AlertListPeriod.all,
    this.clientQuery,
    this.page = 1,
    this.pageSize = 20,
  });

  final AlertType? type;
  final AlertSeverity? severity;
  final AlertStatus? status;
  final AlertListPeriod period;
  final String? clientQuery;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (type != null) {
      params['type'] = type!.apiValue;
    }
    if (severity != null) {
      params['severity'] = severity!.apiValue;
    }
    if (status != null) {
      params['status'] = status!.apiValue;
    }
    if (clientQuery?.isNotEmpty ?? false) {
      params['clientQuery'] = clientQuery;
    }
    if (period != AlertListPeriod.all) {
      params['period'] = period.apiValue;
    }
    return params;
  }
}
