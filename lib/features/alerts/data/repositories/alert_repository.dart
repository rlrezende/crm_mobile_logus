import '../../../../core/network/api_client.dart';
import '../models/alert_summary.dart';

class AlertRepository {
  AlertRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AlertSummary> fetchSummary() async {
    final result = await _apiClient.getJson('Alerts/summary');
    return AlertSummary.fromJson(result);
  }
}
