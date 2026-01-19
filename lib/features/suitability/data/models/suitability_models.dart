class SuitabilityQuestionnaire {
  SuitabilityQuestionnaire({
    required this.id,
    required this.key,
    required this.name,
    required this.version,
    required this.validityDays,
    required this.sections,
    required this.questions,
  });

  final String id;
  final String key;
  final String name;
  final int version;
  final int validityDays;
  final List<SuitabilitySection> sections;
  final List<SuitabilityQuestion> questions;

  factory SuitabilityQuestionnaire.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SuitabilitySection.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final questionsJson = (json['questions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SuitabilityQuestion.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return SuitabilityQuestionnaire(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      validityDays: json['validityDays'] as int? ?? 730,
      sections: sectionsJson,
      questions: questionsJson,
    );
  }
}

class SuitabilitySection {
  SuitabilitySection({
    required this.id,
    required this.key,
    required this.title,
    required this.order,
    this.description,
  });

  final String id;
  final String key;
  final String title;
  final int order;
  final String? description;

  factory SuitabilitySection.fromJson(Map<String, dynamic> json) {
    return SuitabilitySection(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}

class SuitabilityQuestion {
  SuitabilityQuestion({
    required this.id,
    required this.key,
    required this.prompt,
    required this.type,
    required this.required,
    required this.order,
    required this.options,
    this.sectionId,
    this.description,
  });

  final String id;
  final String key;
  final String prompt;
  final String type;
  final bool required;
  final int order;
  final String? sectionId;
  final String? description;
  final List<SuitabilityOption> options;

  bool get isSingleChoice => type.toLowerCase() == 'singlechoice';
  bool get isMultipleChoice => type.toLowerCase() == 'multiplechoice';

  factory SuitabilityQuestion.fromJson(Map<String, dynamic> json) {
    final optionsJson = (json['options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SuitabilityOption.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return SuitabilityQuestion(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      type: json['type'] as String? ?? 'SingleChoice',
      required: json['required'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      sectionId: json['sectionId'] as String?,
      description: json['description'] as String?,
      options: optionsJson,
    );
  }
}

class SuitabilityOption {
  SuitabilityOption({
    required this.id,
    required this.key,
    required this.label,
    required this.order,
  });

  final String id;
  final String key;
  final String label;
  final int order;

  factory SuitabilityOption.fromJson(Map<String, dynamic> json) {
    return SuitabilityOption(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }
}

class SuitabilityStatus {
  SuitabilityStatus({
    required this.needsRenewal,
    this.submissionId,
    this.questionnaireId,
    this.questionnaireVersion,
    this.score,
    this.classification,
    this.signedAt,
    this.expiresAt,
  });

  final bool needsRenewal;
  final String? submissionId;
  final String? questionnaireId;
  final int? questionnaireVersion;
  final double? score;
  final String? classification;
  final DateTime? signedAt;
  final DateTime? expiresAt;

  factory SuitabilityStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value != null ? DateTime.tryParse(value)?.toLocal() : null;

    return SuitabilityStatus(
      needsRenewal: json['needsRenewal'] as bool? ?? true,
      submissionId: json['submissionId'] as String?,
      questionnaireId: json['questionnaireId'] as String?,
      questionnaireVersion: json['questionnaireVersion'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      classification: json['classification'] as String?,
      signedAt: parseDate(json['signedAt'] as String?),
      expiresAt: parseDate(json['expiresAt'] as String?),
    );
  }
}

class SuitabilitySubmissionResult {
  SuitabilitySubmissionResult({
    required this.submissionId,
    required this.score,
    required this.classification,
    required this.signedAt,
    required this.expiresAt,
  });

  final String submissionId;
  final double score;
  final String classification;
  final DateTime signedAt;
  final DateTime expiresAt;

  factory SuitabilitySubmissionResult.fromJson(Map<String, dynamic> json) {
    return SuitabilitySubmissionResult(
      submissionId: json['submissionId'] as String,
      score: (json['score'] as num).toDouble(),
      classification: json['classification'] as String? ?? '',
      signedAt: DateTime.parse(json['signedAt'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
    );
  }
}
