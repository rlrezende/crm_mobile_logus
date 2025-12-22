class ConsolidatedSection {
  ConsolidatedSection({
    required this.income,
    required this.variationPercent,
    required this.benchmark,
  });

  final double income;
  final double variationPercent;
  final double? benchmark;

  factory ConsolidatedSection.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ConsolidatedSection(income: 0, variationPercent: 0, benchmark: null);
    }
    return ConsolidatedSection(
      income: _parseDouble(json['rendimentoRS'] ?? json['RendimentoRS']),
      variationPercent: _parseDouble(json['variacaoPorcentagem'] ?? json['VariacaoPorcentagem']),
      benchmark: json['benchmark'] == null ? null : _parseDouble(json['benchmark']),
    );
  }
}

class ConsolidatedReport {
  ConsolidatedReport({
    required this.personId,
    required this.personName,
    required this.portfolio,
    required this.totalApplied,
    required this.currentMonth,
    required this.currentYear,
    this.monthClosed,
    this.year,
    this.volatility90Days,
    this.sharpeIndex,
    this.lastTwelveMonthsReturn,
  });

  final String personId;
  final String personName;
  final String portfolio;
  final double totalApplied;
  final ConsolidatedSection currentMonth;
  final ConsolidatedSection currentYear;
  final ConsolidatedSection? monthClosed;
  final ConsolidatedSection? year;
  final double? volatility90Days;
  final double? sharpeIndex;
  final double? lastTwelveMonthsReturn;

  factory ConsolidatedReport.fromJson(Map<String, dynamic> json) {
    return ConsolidatedReport(
      personId: _string(json, 'pessoaId'),
      personName: _string(json, 'nomePessoa'),
      portfolio: _string(json, 'portfolio'),
      totalApplied: _parseDouble(json['saldoTotalAplicado'] ?? json['SaldoTotalAplicado']),
      currentMonth: ConsolidatedSection.fromJson(_map(json, 'emAndamentoMesAtual')),
      currentYear: ConsolidatedSection.fromJson(_map(json, 'emAndamentoAnoAtual')),
      monthClosed: ConsolidatedSection.fromJson(_map(json, 'mesFechado')),
      year: ConsolidatedSection.fromJson(_map(json, 'ano')),
      volatility90Days: _parseOptional(json['volatilidade90Dias'] ?? json['Volatilidade90Dias']),
      sharpeIndex: _parseOptional(json['indiceSharpeCDI'] ?? json['IndiceSharpeCDI']),
      lastTwelveMonthsReturn: _parseOptional(json['retornoUltimo12meses'] ?? json['RetornoUltimo12meses']),
    );
  }
}

String _string(Map<String, dynamic> json, String key) {
  return (json[key] ??
          json['${key[0].toUpperCase()}${key.substring(1)}'] ??
          '') as String;
}

Map<String, dynamic>? _map(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

double? _parseOptional(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }
  return null;
}
