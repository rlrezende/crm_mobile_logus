import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../models/alert.dart';
import '../models/alert_filters.dart';
import '../models/alert_list_result.dart';
import '../models/alert_summary.dart';
import '../models/notification_preference.dart';

class AlertRepository {
  AlertRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AlertSummary> fetchSummary() async {
    final result = await _apiClient.getJson('Alerts/summary');
    return AlertSummary.fromJson(result);
  }

  Future<AlertListResult> fetchAlerts({
    AlertFilters filters = const AlertFilters(),
  }) async {
    final result = await _apiClient.getJson(
      'Alerts',
      queryParameters: filters.toQueryParameters(),
    );
    final rawItems = result['items'] ?? result['itemsDto'] ?? result['alerts'];
    final items = unwrapList(rawItems)
        .whereType<Map<String, dynamic>>()
        .map(Alert.fromJson)
        .toList();
    final total = (result['totalItems'] as num?)?.toInt() ?? items.length;
    return AlertListResult(totalItems: total, items: items);
  }

  Future<Alert> resolveAlert(String id) async {
    final result = await _apiClient.patchJson('Alerts/$id/resolve');
    return Alert.fromJson(result);
  }

  Future<Alert> ignoreAlert(String id) async {
    final result = await _apiClient.patchJson('Alerts/$id/ignore');
    return Alert.fromJson(result);
  }

  Future<Alert> snoozeAlert(String id, {required int days}) async {
    final result = await _apiClient.patchJson(
      'Alerts/$id/snooze',
      data: {'days': days},
    );
    return Alert.fromJson(result);
  }

  Future<List<NotificationPreference>> fetchNotificationPreferences() async {
    final items = await _apiClient.getJsonList('notification-preferences/me');
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationPreference.fromJson)
        .toList();
  }

  Future<void> saveNotificationPreferences(
    List<NotificationPreference> preferences,
  ) {
    final payload = preferences.map((pref) => pref.toJson()).toList();
    return _apiClient.putJson(
      'notification-preferences/me',
      data: payload,
    );
  }
}
