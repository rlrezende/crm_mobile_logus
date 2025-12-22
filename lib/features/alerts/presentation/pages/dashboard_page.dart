import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/summary_card.dart';
import '../../../auth/data/models/login_response.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/models/consolidated_report.dart';
import '../../../dashboard/data/models/customer_overview.dart';
import '../../../dashboard/data/repositories/customer_dashboard_repository.dart';
import '../../data/models/alert.dart';
import '../../data/models/alert_summary.dart';
import '../../domain/alert_enums.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<CustomerDashboardOverview> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<CustomerDashboardOverview> _loadOverview() {
    return context.read<CustomerDashboardRepository>().fetchOverview();
  }

  Future<void> _refresh() async {
    setState(() {
      _overviewFuture = _loadOverview();
    });
    await _overviewFuture;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<CustomerDashboardOverview>(
            future: _overviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Não foi possível carregar seu painel.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final overview = snapshot.data!;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _HeroHeader(
                    user: user,
                    consolidated: overview.consolidatedReport,
                    onLogout: () => context.read<AuthController>().logout(),
                  ),
                  if (overview.consolidatedReport != null) ...[
                    const SizedBox(height: 16),
                    _ConsolidatedSection(report: overview.consolidatedReport!),
                  ],
                  const SizedBox(height: 16),
                  _AlertHighlights(alerts: overview.recentAlerts),
                  const SizedBox(height: 16),
                  _AlertSummarySection(summary: overview.alertSummary),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
final NumberFormat _percentFormatter = NumberFormat.decimalPattern('pt_BR');

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.user,
    required this.consolidated,
    required this.onLogout,
  });

  final UserProfile? user;
  final ConsolidatedReport? consolidated;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final totalApplied = consolidated?.totalApplied ?? 0;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/fundo_logus.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logus_logo.png',
                height: 48,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              const Spacer(),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                color: Colors.white,
                tooltip: 'Sair',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Olá, ${user?.person.name ?? 'cliente Logus'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe seus alertas e investimentos em um só lugar.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patrimônio sob gestão',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(totalApplied),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (consolidated?.currentYear.variationPercent != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Rentabilidade do ano: ${_formatPercent(consolidated!.currentYear.variationPercent)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertHighlights extends StatelessWidget {
  const _AlertHighlights({required this.alerts});

  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified, color: Colors.green),
                const SizedBox(height: 8),
                Text(
                  'Tudo em ordem!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text('Nenhum alerta exige sua atenção neste momento.'),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return SizedBox(
            width: 260,
            child: Card(
              color: _alertCardColor(alert.type, context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _alertIcon(alert.type),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _alertHeadline(alert),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description ?? 'Acesse para verificar os detalhes.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: alerts.length.clamp(0, 10),
      ),
    );
  }
}

class _AlertSummarySection extends StatelessWidget {
  const _AlertSummarySection({required this.summary});

  final AlertSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo dos seus alertas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SummaryCard(
                title: 'Ativos',
                value: summary.totalActive.toString(),
                icon: Icons.notifications_active_outlined,
              ),
              SummaryCard(
                title: 'Críticos',
                value: summary.critical.toString(),
                icon: Icons.warning_amber_rounded,
              ),
              SummaryCard(
                title: 'Vencidos +7 dias',
                value: summary.overdueSevenDays.toString(),
                icon: Icons.schedule,
              ),
              SummaryCard(
                title: 'Próximos 7 dias',
                value: summary.nextSevenDays.toString(),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.byStatus.entries
                .map(
                  (entry) => Chip(
                    avatar: const Icon(Icons.circle, size: 12),
                    label: Text('${entry.key.label}: ${entry.value}'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ConsolidatedSection extends StatelessWidget {
  const _ConsolidatedSection({required this.report});

  final ConsolidatedReport report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance consolidada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                report.portfolio,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo total'),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatCurrency(report.totalApplied),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Retorno 12 meses'),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatPercent(report.lastTwelveMonthsReturn ?? report.currentYear.variationPercent),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PerformanceChart(report: report),
              if (report.monthClosed != null) ...[
                const SizedBox(height: 16),
                _MonthlyComparison(
                  current: report.currentMonth,
                  previous: report.monthClosed!,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricChip(
                    label: 'Volatilidade 90 dias',
                    value: report.volatility90Days == null
                        ? '--'
                        : '${report.volatility90Days!.toStringAsFixed(2)}%',
                  ),
                  _MetricChip(
                    label: 'Índice Sharpe CDI',
                    value: report.sharpeIndex == null ? '--' : report.sharpeIndex!.toStringAsFixed(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({required this.report});

  final ConsolidatedReport report;

  @override
  Widget build(BuildContext context) {
    try {
      final points = [
        _PerformancePoint(
          label: 'Mês',
          value: report.currentMonth.variationPercent,
          comparison: report.monthClosed?.variationPercent,
          comparisonLabel: report.monthClosed != null ? 'Mês anterior' : null,
          benchmark: report.currentMonth.benchmark,
        ),
        _PerformancePoint(
          label: 'Ano',
          value: report.currentYear.variationPercent,
          benchmark: report.currentYear.benchmark,
        ),
        _PerformancePoint(
          label: '12 meses',
          value: report.lastTwelveMonthsReturn ?? 0,
          benchmark: null,
        ),
      ];

      final theme = Theme.of(context);
      final rodMatrix = <List<_RodInfo>>[];
      final allValues = <double>[];

      final barGroups = List.generate(points.length, (index) {
        final point = points[index];
        final rods = point.buildRods(theme);
        rodMatrix.add(rods);
        allValues.addAll(rods.map((r) => r.value));
        return BarChartGroupData(
          x: index,
          barsSpace: 10,
          barRods: rods
              .map(
                (rod) => BarChartRodData(
                  toY: rod.value,
                  borderRadius: BorderRadius.circular(6),
                  width: 14,
                  color: rod.color,
                ),
              )
              .toList(),
        );
      });

      final minY = math.min(0, allValues.reduce(math.min)) - 0.5;
      final maxY = math.max(0, allValues.reduce(math.max)) + 0.5;

      return SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            minY: minY,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(10),
                tooltipRoundedRadius: 8,
                getTooltipColor: (group) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final point = points[group.x.toInt()];
                  final rodInfo = rodMatrix[groupIndex][rodIndex];
                  return BarTooltipItem(
                    '${point.label} • ${rodInfo.label}\n${_formatPercent(rodInfo.value)}',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(points[index].label),
                    );
                  },
                ),
              ),
            ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
    } catch (error, stackTrace) {
      developer.log(
        'Erro ao montar gráfico de performance',
        name: 'Dashboard',
        error: error,
        stackTrace: stackTrace,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Não foi possível renderizar o gráfico de performance.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MonthlyComparison extends StatelessWidget {
  const _MonthlyComparison({
    required this.current,
    required this.previous,
  });

  final ConsolidatedSection current;
  final ConsolidatedSection previous;

  @override
  Widget build(BuildContext context) {
    final delta = current.variationPercent - previous.variationPercent;
    final deltaColor = delta >= 0 ? Colors.green[700] : Colors.red[600];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativo mensal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MonthlyBlock(label: 'Mês atual', section: current)),
              const SizedBox(width: 12),
              Expanded(child: _MonthlyBlock(label: 'Mês anterior', section: previous)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Variação vs mês anterior: ${_formatSignedPercent(delta)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBlock extends StatelessWidget {
  const _MonthlyBlock({required this.label, required this.section});

  final String label;
  final ConsolidatedSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            _formatPercent(section.variationPercent),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(section.income),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _PerformancePoint {
  _PerformancePoint({
    required this.label,
    required this.value,
    this.comparison,
    this.comparisonLabel,
    this.benchmark,
  });

  final String label;
  final double value;
  final double? comparison;
  final String? comparisonLabel;
  final double? benchmark;

  List<_RodInfo> buildRods(ThemeData theme) {
    final rods = <_RodInfo>[
      _RodInfo(
        label: 'Você',
        value: value,
        color: theme.colorScheme.primary,
      ),
    ];
    if (comparison != null) {
      rods.add(
        _RodInfo(
          label: comparisonLabel ?? 'Comparativo',
          value: comparison!,
          color: theme.colorScheme.tertiary,
        ),
      );
    }
    if (benchmark != null) {
      rods.add(
        _RodInfo(
          label: 'Benchmark',
          value: benchmark!,
          color: theme.colorScheme.secondary,
        ),
      );
    }
    return rods;
  }
}

class _RodInfo {
  _RodInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

Color _alertCardColor(AlertType type, BuildContext context) {
  switch (type) {
    case AlertType.procuracaoVencida:
      return Colors.red.shade50;
    case AlertType.suitabilityVencido:
      return Colors.orange.shade50;
    case AlertType.aniversario:
      return Colors.lightBlue.shade50;
    case AlertType.outro:
      return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}

IconData _alertIcon(AlertType type) {
  switch (type) {
    case AlertType.procuracaoVencida:
      return Icons.gavel_outlined;
    case AlertType.suitabilityVencido:
      return Icons.verified_user_outlined;
    case AlertType.aniversario:
      return Icons.cake_outlined;
    case AlertType.outro:
      return Icons.notifications_outlined;
  }
}

String _alertHeadline(Alert alert) {
  switch (alert.type) {
    case AlertType.procuracaoVencida:
      return 'Sua procuração precisa ser renovada.';
    case AlertType.suitabilityVencido:
      return 'Revisite seu perfil de investidor.';
    case AlertType.aniversario:
      return 'Parabéns! Hoje é dia especial.';
    case AlertType.outro:
      return alert.title.isNotEmpty ? alert.title : 'Alerta importante do CRM.';
  }
}

String _formatCurrency(double value) {
  return _currencyFormatter.format(value);
}

String _formatPercent(double value) {
  return '${_percentFormatter.format(value)}%';
}

String _formatSignedPercent(double value) {
  final formatted = _percentFormatter.format(value.abs());
  final sign = value >= 0 ? '+' : '-';
  return '$sign$formatted%';
}
