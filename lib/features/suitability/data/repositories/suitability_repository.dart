import 'package:crm_mobile_logus/core/network/api_client.dart';

import '../models/suitability_models.dart';

class SuitabilityRepository {
  SuitabilityRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  Future<SuitabilityStatus> fetchStatus() async {
    final json = await _client.getJson('suitability/status');
    return SuitabilityStatus.fromJson(json);
  }

  Future<SuitabilityQuestionnaire> fetchQuestionnaire() async {
    final json = await _client.getJson('suitability/questionnaire');
    return SuitabilityQuestionnaire.fromJson(json);
  }

  Future<SuitabilitySubmissionResult> submitAnswers({
    required String questionnaireId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final payload = {
      'questionnaireId': questionnaireId,
      'answers': answers,
    };
    final json = await _client.postJson('suitability/submissions', data: payload);
    return SuitabilitySubmissionResult.fromJson(json);
  }
}
