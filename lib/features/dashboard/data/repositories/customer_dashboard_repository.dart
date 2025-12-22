import 'dart:developer' as developer;

import '../../../../core/network/api_client.dart';
import '../models/customer_overview.dart';

class CustomerDashboardRepository {
  CustomerDashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CustomerDashboardOverview> fetchOverview() async {
    final result = await _apiClient.getJson('customer/overview');
    developer.log('Customer overview payload', name: 'Dashboard', error: result);
    return CustomerDashboardOverview.fromJson(result);
  }
}
