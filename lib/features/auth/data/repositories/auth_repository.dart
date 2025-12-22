import '../../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LoginResponse> authenticate(LoginRequest request) async {
    final result = await _apiClient.postJson(
      'Login/authenticate',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(result);
  }
}
