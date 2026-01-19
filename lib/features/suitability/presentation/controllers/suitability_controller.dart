import 'package:flutter/foundation.dart';

import '../../data/models/suitability_models.dart';
import '../../data/repositories/suitability_repository.dart';

class SuitabilityController extends ChangeNotifier {
  SuitabilityController({required this.repository});

  final SuitabilityRepository repository;

  SuitabilityStatus? _status;
  SuitabilityQuestionnaire? _questionnaire;
  final Map<String, String> _selectedOptions = {};
  bool _statusLoading = false;
  bool _questionnaireLoading = false;
  bool _submitting = false;
  String? _errorMessage;

  SuitabilityStatus? get status => _status;
  SuitabilityQuestionnaire? get questionnaire => _questionnaire;
  bool get isStatusLoading => _statusLoading;
  bool get isQuestionnaireLoading => _questionnaireLoading;
  bool get isSubmitting => _submitting;
  String? get errorMessage => _errorMessage;
  Map<String, String> get selectedOptions => Map.unmodifiable(_selectedOptions);

  Future<void> ensureStatusLoaded() async {
    if (_status != null || _statusLoading) {
      return;
    }
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    _statusLoading = true;
    notifyListeners();

    try {
      _status = await repository.fetchStatus();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Não foi possível verificar o status do suitability.';
    } finally {
      _statusLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestionnaire() async {
    _questionnaireLoading = true;
    notifyListeners();

    try {
      _questionnaire = await repository.fetchQuestionnaire();
      _selectedOptions.clear();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Não foi possível carregar o questionário.';
    } finally {
      _questionnaireLoading = false;
      notifyListeners();
    }
  }

  void selectOption(String questionId, String optionId) {
    _selectedOptions[questionId] = optionId;
    notifyListeners();
  }

  bool get canSubmit {
    final current = _questionnaire;
    if (current == null) {
      return false;
    }
    return current.questions.every((q) => !q.required || _selectedOptions.containsKey(q.id));
  }

  Future<bool> submitAnswers() async {
    final current = _questionnaire;
    if (current == null) {
      throw StateError('Questionário não carregado.');
    }
    if (!canSubmit) {
      _errorMessage = 'Responda todas as perguntas obrigatórias.';
      notifyListeners();
      return false;
    }

    final answers = _selectedOptions.entries
        .map(
          (entry) => {
            'questionId': entry.key,
            'optionId': entry.value,
          },
        )
        .toList();

    _submitting = true;
    notifyListeners();

    try {
      await repository.submitAnswers(
        questionnaireId: current.id,
        answers: answers,
      );
      await refreshStatus();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = 'Não foi possível enviar suas respostas.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
