class InvestmentDashboardData {
  InvestmentDashboardData({
    required this.benchmark,
    required this.asOf,
    required this.portfolio,
    required this.totalValue,
    required this.returns,
    required this.volatility90Days,
    required this.classes,
    required this.contributions,
  });

  final String benchmark;
  final DateTime? asOf;
  final String portfolio;
  final double? totalValue;
  final InvestmentReturns returns;
  final double? volatility90Days;
  final List<InvestmentClass> classes;
  final ContributionSeries contributions;

  factory InvestmentDashboardData.fromJson(Map<String, dynamic> json) {
    final classesJson = json['classes'] as List<dynamic>? ?? const [];
    return InvestmentDashboardData(
      benchmark: (json['benchmark'] as String?) ?? 'CDI',
      asOf: _parseDate(json['asOf']),
      portfolio: (json['portfolio'] as String?) ?? '',
      totalValue: _toDoubleNullable(json['totalValue']),
      returns: InvestmentReturns.fromJson((json['returns'] as Map?)?.cast<String, dynamic>() ?? const {}),
      volatility90Days: _toDoubleNullable(json['volatility90Days']),
      classes: classesJson
          .whereType<Map>()
          .map((item) => InvestmentClass.fromJson(item.cast<String, dynamic>()))
          .toList(),
      contributions: ContributionSeries.fromJson(
        (json['contributions'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class InvestmentReturns {
  InvestmentReturns({
    required this.month,
    required this.ytd,
    required this.twelveMonths,
    required this.sinceInception,
  });

  final ReturnMetric month;
  final ReturnMetric ytd;
  final ReturnMetric twelveMonths;
  final ReturnMetric sinceInception;

  factory InvestmentReturns.fromJson(Map<String, dynamic> json) {
    return InvestmentReturns(
      month: ReturnMetric.fromJson((json['month'] as Map?)?.cast<String, dynamic>() ?? const {}),
      ytd: ReturnMetric.fromJson((json['ytd'] as Map?)?.cast<String, dynamic>() ?? const {}),
      twelveMonths: ReturnMetric.fromJson(
        (json['twelveMonths'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      sinceInception: ReturnMetric.fromJson(
        (json['sinceInception'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class ReturnMetric {
  ReturnMetric({
    required this.available,
    this.value,
    this.percent,
    this.benchmark,
  });

  final bool available;
  final double? value;
  final double? percent;
  final double? benchmark;

  factory ReturnMetric.fromJson(Map<String, dynamic> json) {
    return ReturnMetric(
      available: (json['available'] as bool?) ?? true,
      value: _toDoubleNullable(json['value']),
      percent: _toDoubleNullable(json['percent']),
      benchmark: _toDoubleNullable(json['benchmark']),
    );
  }
}

class InvestmentClass {
  InvestmentClass({
    required this.name,
    this.value,
    this.percent,
    this.monthContribution,
    this.ytdContribution,
    this.monthReturnPercent,
    this.ytdReturnPercent,
    required this.assets,
  });

  final String name;
  final double? value;
  final double? percent;
  final double? monthContribution;
  final double? ytdContribution;
  final double? monthReturnPercent;
  final double? ytdReturnPercent;
  final List<InvestmentAsset> assets;

  factory InvestmentClass.fromJson(Map<String, dynamic> json) {
    final assetsJson = json['assets'] as List<dynamic>? ?? const [];
    return InvestmentClass(
      name: (json['name'] as String?) ?? 'Classe',
      value: _toDoubleNullable(json['value']),
      percent: _toDoubleNullable(json['percent']),
      monthContribution: _toDoubleNullable(json['monthContribution']),
      ytdContribution: _toDoubleNullable(json['ytdContribution']),
      monthReturnPercent: _toDoubleNullable(json['monthReturnPercent']),
      ytdReturnPercent: _toDoubleNullable(json['ytdReturnPercent']),
      assets: assetsJson
          .whereType<Map>()
          .map((item) => InvestmentAsset.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class InvestmentAsset {
  InvestmentAsset({
    required this.name,
    this.value,
    this.portfolioPercent,
    this.monthReturnPercent,
    this.ytdReturnPercent,
    this.liquidity,
  });

  final String name;
  final double? value;
  final double? portfolioPercent;
  final double? monthReturnPercent;
  final double? ytdReturnPercent;
  final String? liquidity;

  factory InvestmentAsset.fromJson(Map<String, dynamic> json) {
    return InvestmentAsset(
      name: (json['name'] as String?) ?? 'Ativo',
      value: _toDoubleNullable(json['value']),
      portfolioPercent: _toDoubleNullable(json['portfolioPercent']),
      monthReturnPercent: _toDoubleNullable(json['monthReturnPercent']),
      ytdReturnPercent: _toDoubleNullable(json['ytdReturnPercent']),
      liquidity: json['liquidity'] as String?,
    );
  }
}

class ContributionSeries {
  ContributionSeries({
    this.monthTotal,
    this.ytdTotal,
    required this.month,
    required this.ytd,
  });

  final double? monthTotal;
  final double? ytdTotal;
  final List<WaterfallPoint> month;
  final List<WaterfallPoint> ytd;

  factory ContributionSeries.fromJson(Map<String, dynamic> json) {
    final monthJson = json['month'] as List<dynamic>? ?? const [];
    final ytdJson = json['ytd'] as List<dynamic>? ?? const [];
    return ContributionSeries(
      monthTotal: _toDoubleNullable(json['monthTotal']),
      ytdTotal: _toDoubleNullable(json['ytdTotal']),
      month: monthJson
          .whereType<Map>()
          .map((item) => WaterfallPoint.fromJson(item.cast<String, dynamic>()))
          .toList(),
      ytd: ytdJson
          .whereType<Map>()
          .map((item) => WaterfallPoint.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class WaterfallPoint {
  WaterfallPoint({
    required this.name,
    required this.value,
    required this.start,
    required this.end,
    required this.isTotal,
  });

  final String name;
  final double value;
  final double start;
  final double end;
  final bool isTotal;

  factory WaterfallPoint.fromJson(Map<String, dynamic> json) {
    return WaterfallPoint(
      name: (json['name'] as String?) ?? '',
      value: _toDoubleNullable(json['value']) ?? 0,
      start: _toDoubleNullable(json['start']) ?? 0,
      end: _toDoubleNullable(json['end']) ?? 0,
      isTotal: (json['isTotal'] as bool?) ?? false,
    );
  }
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'nd') {
      return null;
    }
    return double.tryParse(normalized.replaceAll(',', '.'));
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
