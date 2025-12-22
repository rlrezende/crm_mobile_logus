import '../../../alerts/data/models/alert.dart';
import '../../../alerts/data/models/alert_summary.dart';
import 'consolidated_report.dart';

class CustomerDashboardOverview {
  CustomerDashboardOverview({
    required this.alertSummary,
    required this.recentAlerts,
    this.consolidatedReport,
  });

  final AlertSummary alertSummary;
  final List<Alert> recentAlerts;
  final ConsolidatedReport? consolidatedReport;

  factory CustomerDashboardOverview.fromJson(Map<String, dynamic> json) {
    final alertsJson = json['alerts'] as Map<String, dynamic>? ?? {};
    final summaryJson = (alertsJson['summary'] ?? const {}) as Map<String, dynamic>;
    final recentJson = alertsJson['recent'] as List<dynamic>? ?? const [];

    return CustomerDashboardOverview(
      alertSummary: AlertSummary.fromJson(summaryJson),
      recentAlerts: recentJson
          .whereType<Map<String, dynamic>>()
          .map(Alert.fromJson)
          .toList(),
      consolidatedReport: json['consolidated'] is Map<String, dynamic>
          ? ConsolidatedReport.fromJson(json['consolidated'] as Map<String, dynamic>)
          : null,
    );
  }
}
