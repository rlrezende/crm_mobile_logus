import 'dart:developer' as developer;

import '../../../../core/network/api_client.dart';
import '../models/investment_dashboard.dart';
import '../models/customer_overview.dart';

class CustomerDashboardRepository {
  CustomerDashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CustomerDashboardOverview> fetchOverview() async {
    final result = await _apiClient.getJson('customer/overview');
    developer.log('Customer overview payload', name: 'Dashboard', error: result);
    return CustomerDashboardOverview.fromJson(result);
  }

  Future<InvestmentDashboardData> fetchInvestmentDashboard({
    required String benchmark,
  }) async {
    final result = await _apiClient.getJson(
      'customer/investment-dashboard',
      queryParameters: {'benchmark': benchmark},
    );
    developer.log('Investment dashboard payload', name: 'Dashboard', error: result);
    return InvestmentDashboardData.fromJson(result);
  }
}
