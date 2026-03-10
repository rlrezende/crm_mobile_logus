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
    final classesJson = _readList(_readValue(json, 'classes'));
    return InvestmentDashboardData(
      benchmark: (_readValue(json, 'benchmark') as String?) ?? 'CDI',
      asOf: _parseDate(_readValue(json, 'asOf')),
      portfolio: (_readValue(json, 'portfolio') as String?) ?? '',
      totalValue: _toDoubleNullable(_readValue(json, 'totalValue')),
      returns: InvestmentReturns.fromJson(_readMap(_readValue(json, 'returns'))),
      volatility90Days: _toDoubleNullable(_readValue(json, 'volatility90Days')),
      classes: classesJson
          .whereType<Map>()
          .map((item) => InvestmentClass.fromJson(item.cast<String, dynamic>()))
          .toList(),
      contributions: ContributionSeries.fromJson(_readMap(_readValue(json, 'contributions'))),
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
      month: ReturnMetric.fromJson(_readMap(_readValue(json, 'month'))),
      ytd: ReturnMetric.fromJson(_readMap(_readValue(json, 'ytd'))),
      twelveMonths: ReturnMetric.fromJson(_readMap(_readValue(json, 'twelveMonths'))),
      sinceInception: ReturnMetric.fromJson(_readMap(_readValue(json, 'sinceInception'))),
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
      available: (_readValue(json, 'available') as bool?) ?? true,
      value: _toDoubleNullable(_readValue(json, 'value')),
      percent: _toDoubleNullable(_readValue(json, 'percent')),
      benchmark: _toDoubleNullable(_readValue(json, 'benchmark')),
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
    final assetsJson = _readList(_readValue(json, 'assets'));
    return InvestmentClass(
      name: (_readValue(json, 'name') as String?) ?? 'Classe',
      value: _toDoubleNullable(_readValue(json, 'value')),
      percent: _toDoubleNullable(_readValue(json, 'percent')),
      monthContribution: _toDoubleNullable(_readValue(json, 'monthContribution')),
      ytdContribution: _toDoubleNullable(_readValue(json, 'ytdContribution')),
      monthReturnPercent: _toDoubleNullable(_readValue(json, 'monthReturnPercent')),
      ytdReturnPercent: _toDoubleNullable(_readValue(json, 'ytdReturnPercent')),
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
      name: (_readValue(json, 'name') as String?) ?? 'Ativo',
      value: _toDoubleNullable(_readValue(json, 'value')),
      portfolioPercent: _toDoubleNullable(_readValue(json, 'portfolioPercent')),
      monthReturnPercent: _toDoubleNullable(_readValue(json, 'monthReturnPercent')),
      ytdReturnPercent: _toDoubleNullable(_readValue(json, 'ytdReturnPercent')),
      liquidity: _readValue(json, 'liquidity') as String?,
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
    final monthJson = _readList(_readValue(json, 'month'));
    final ytdJson = _readList(_readValue(json, 'ytd'));
    return ContributionSeries(
      monthTotal: _toDoubleNullable(_readValue(json, 'monthTotal')),
      ytdTotal: _toDoubleNullable(_readValue(json, 'ytdTotal')),
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
      name: (_readValue(json, 'name') as String?) ?? '',
      value: _toDoubleNullable(_readValue(json, 'value')) ?? 0,
      start: _toDoubleNullable(_readValue(json, 'start')) ?? 0,
      end: _toDoubleNullable(_readValue(json, 'end')) ?? 0,
      isTotal: (_readValue(json, 'isTotal') as bool?) ?? false,
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

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry('$key', mapValue));
  }
  return const {};
}

List<dynamic> _readList(dynamic value) {
  if (value == null) {
    return const [];
  }
  if (value is List<dynamic>) {
    return value;
  }
  final map = _readMap(value);
  if (map.isNotEmpty) {
    final values = map[r'$values'];
    if (values != null) {
      return _readList(values);
    }
    final items = map['items'] ?? map['itemsDto'];
    if (items != null) {
      return _readList(items);
    }
  }
  return const [];
}

dynamic _readValue(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }

  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
