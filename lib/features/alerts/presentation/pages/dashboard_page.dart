import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/data/models/investment_dashboard.dart';
import '../../../dashboard/data/repositories/customer_dashboard_repository.dart';

enum DashboardBenchmark {
  cdi(label: 'CDI', apiValue: 'cdi'),
  ibovespa(label: 'Ibovespa', apiValue: 'ibovespa'),
  ipca(label: 'IPCA', apiValue: 'ipca');

  const DashboardBenchmark({
    required this.label,
    required this.apiValue,
  });

  final String label;
  final String apiValue;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardBenchmark _selectedBenchmark = DashboardBenchmark.cdi;
  late Future<InvestmentDashboardData> _dashboardFuture;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<InvestmentDashboardData> _loadDashboard() {
    return context.read<CustomerDashboardRepository>().fetchInvestmentDashboard(
          benchmark: _selectedBenchmark.apiValue,
        );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
  }

  void _onBenchmarkChanged(DashboardBenchmark benchmark) {
    if (_selectedBenchmark == benchmark) {
      return;
    }
    setState(() {
      _selectedBenchmark = benchmark;
      _touchedPieIndex = -1;
      _dashboardFuture = _loadDashboard();
    });
  }

  void _openClassOverview(List<InvestmentClass> classes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetClassOverviewPage(classes: classes),
      ),
    );
  }

  void _openClassAssets(InvestmentClass classData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassAssetsPage(classData: classData),
      ),
    );
  }

  void _openContribution(InvestmentDashboardData dashboard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerformanceContributionPage(dashboard: dashboard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: FutureBuilder<InvestmentDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível carregar os dados financeiros.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dashboard = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _InvestorHeader(
                    customerName: user?.person.name ?? 'Cliente',
                    portfolio: dashboard.portfolio,
                    asOf: dashboard.asOf,
                    onLogout: () => context.read<AuthController>().logout(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _BenchmarkSelector(
                      selected: _selectedBenchmark,
                      onChanged: _onBenchmarkChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _PrimaryMetricsPanel(
                      dashboard: dashboard,
                      benchmarkLabel: _selectedBenchmark.label,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _AllocationCard(
                      dashboard: dashboard,
                      touchedIndex: _touchedPieIndex,
                      onTouch: (index, openDetails) {
                        setState(() => _touchedPieIndex = index);
                        if (openDetails &&
                            index >= 0 &&
                            index < dashboard.classes.length) {
                          _openClassAssets(dashboard.classes[index]);
                        }
                      },
                      onOpenOverview: () => _openClassOverview(dashboard.classes),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ActionButtons(
                      onOpenClasses: () => _openClassOverview(dashboard.classes),
                      onOpenContribution: () => _openContribution(dashboard),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvestorHeader extends StatelessWidget {
  const _InvestorHeader({
    required this.customerName,
    required this.portfolio,
    required this.asOf,
    required this.onLogout,
  });

  final String customerName;
  final String portfolio;
  final DateTime? asOf;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final dateLabel = asOf == null
        ? 'Sem data de referência'
        : 'Ref. ${DateFormat('dd/MM/yyyy').format(asOf!)}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1F3E),
            Color(0xFF143D6A),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logus_mark.png',
                height: 36,
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
          const SizedBox(height: 20),
          Text(
            'Olá, $customerName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Painel financeiro do investidor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(label: portfolio.isEmpty ? 'Sem portfolio' : portfolio),
              _HeaderChip(label: dateLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BenchmarkSelector extends StatelessWidget {
  const _BenchmarkSelector({
    required this.selected,
    required this.onChanged,
  });

  final DashboardBenchmark selected;
  final ValueChanged<DashboardBenchmark> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DFE8)),
      ),
      child: Row(
        children: DashboardBenchmark.values
            .map(
              (option) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: selected == option ? const Color(0xFF0E4A87) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: selected == option ? Colors.white : const Color(0xFF203552),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PrimaryMetricsPanel extends StatelessWidget {
  const _PrimaryMetricsPanel({
    required this.dashboard,
    required this.benchmarkLabel,
  });

  final InvestmentDashboardData dashboard;
  final String benchmarkLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF102F57),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valor consolidado da carteira',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(dashboard.totalValue),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: 'Mês',
                primary: _formatPercent(dashboard.returns.month.percent, withSignal: true),
                secondary: _formatCurrency(dashboard.returns.month.value),
                benchmark: '$benchmarkLabel: ${_formatPercent(dashboard.returns.month.benchmark)}',
                accent: _performanceColor(dashboard.returns.month.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: 'YTD',
                primary: _formatPercent(dashboard.returns.ytd.percent, withSignal: true),
                secondary: _formatCurrency(dashboard.returns.ytd.value),
                benchmark: '$benchmarkLabel: ${_formatPercent(dashboard.returns.ytd.benchmark)}',
                accent: _performanceColor(dashboard.returns.ytd.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: '12 Meses',
                primary: _formatPercent(dashboard.returns.twelveMonths.percent, withSignal: true),
                secondary: null,
                benchmark: null,
                accent: _performanceColor(dashboard.returns.twelveMonths.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: 'Desde o início',
                primary: dashboard.returns.sinceInception.available
                    ? _formatPercent(dashboard.returns.sinceInception.percent, withSignal: true)
                    : 'Não disponível',
                secondary: dashboard.returns.sinceInception.available
                    ? _formatCurrency(dashboard.returns.sinceInception.value)
                    : null,
                benchmark: dashboard.returns.sinceInception.available
                    ? '$benchmarkLabel: ${_formatPercent(dashboard.returns.sinceInception.benchmark)}'
                    : 'Checar disponibilidade na Comdinheiro',
                accent: _performanceColor(dashboard.returns.sinceInception.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: 'Volatilidade (90 dias)',
                primary: _formatPercent(dashboard.volatility90Days),
                secondary: null,
                benchmark: null,
                accent: const Color(0xFF006E6D),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double _cardWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width - 32;
  return width >= 740 ? (width - 20) / 3 : (width - 10) / 2;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.primary,
    this.secondary,
    this.benchmark,
    required this.accent,
  });

  final String title;
  final String primary;
  final String? secondary;
  final String? benchmark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF53637A),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              secondary!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2B3E59),
                  ),
            ),
          ],
          if (benchmark != null) ...[
            const SizedBox(height: 6),
            Text(
              benchmark!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7A8F),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.dashboard,
    required this.touchedIndex,
    required this.onTouch,
    required this.onOpenOverview,
  });

  final InvestmentDashboardData dashboard;
  final int touchedIndex;
  final void Function(int index, bool openDetails) onTouch;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final classes = dashboard.classes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alocação por classe de ativo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17375B),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque no gráfico para abrir os investimentos da classe.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7A8F)),
          ),
          const SizedBox(height: 14),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Não há dados de classe disponíveis para este cliente.'),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                              onTouch(-1, false);
                              return;
                            }
                            final index = response!.touchedSection!.touchedSectionIndex;
                            final openDetails = event is FlTapUpEvent;
                            onTouch(index, openDetails);
                          },
                        ),
                        sections: List.generate(classes.length, (index) {
                          final classItem = classes[index];
                          final isTouched = index == touchedIndex;
                          final color = _chartPalette[index % _chartPalette.length];
                          final percentValue = classItem.percent ?? 0;
                          final radius = isTouched ? 82.0 : 72.0;
                          return PieChartSectionData(
                            value: percentValue <= 0 ? 0.001 : percentValue,
                            color: color,
                            radius: radius,
                            title: percentValue <= 0 ? '' : '${percentValue.toStringAsFixed(2)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: ListView.separated(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final item = classes[index];
                        final color = _chartPalette[index % _chartPalette.length];
                        return InkWell(
                          onTap: () => onTouch(index, true),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        '${_formatCurrency(item.value, compact: true)} • ${_formatPercent(item.percent)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF6B7A8F),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenOverview,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Ver abertura por classe'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onOpenClasses,
    required this.onOpenContribution,
  });

  final VoidCallback onOpenClasses;
  final VoidCallback onOpenContribution;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenClasses,
            icon: const Icon(Icons.pie_chart_outline),
            label: const Text('Classes e ativos'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onOpenContribution,
            icon: const Icon(Icons.waterfall_chart),
            label: const Text('Contribuição'),
          ),
        ),
      ],
    );
  }
}

class AssetClassOverviewPage extends StatelessWidget {
  const AssetClassOverviewPage({
    super.key,
    required this.classes,
  });

  final List<InvestmentClass> classes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abertura da Classe de Ativos'),
      ),
      body: classes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Não há classes de ativo disponíveis para exibição.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final item = classes[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFDCE4ED)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassAssetsPage(classData: item),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _InfoPill(
                                label: 'Valor',
                                value: _formatCurrency(item.value),
                              ),
                              _InfoPill(
                                label: 'Mês',
                                value:
                                    '${_formatCurrency(item.monthContribution)} • ${_formatPercent(item.monthReturnPercent, withSignal: true)}',
                              ),
                              _InfoPill(
                                label: 'YTD',
                                value:
                                    '${_formatCurrency(item.ytdContribution)} • ${_formatPercent(item.ytdReturnPercent, withSignal: true)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
            ),
    );
  }
}

class ClassAssetsPage extends StatelessWidget {
  const ClassAssetsPage({
    super.key,
    required this.classData,
  });

  final InvestmentClass classData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classData.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10335E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPillDark(
                  label: 'Valor',
                  value: _formatCurrency(classData.value),
                ),
                _InfoPillDark(
                  label: '% Carteira',
                  value: _formatPercent(classData.percent),
                ),
                _InfoPillDark(
                  label: 'Retorno Mês',
                  value:
                      '${_formatCurrency(classData.monthContribution)} • ${_formatPercent(classData.monthReturnPercent, withSignal: true)}',
                ),
                _InfoPillDark(
                  label: 'Retorno YTD',
                  value:
                      '${_formatCurrency(classData.ytdContribution)} • ${_formatPercent(classData.ytdReturnPercent, withSignal: true)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Investimentos da classe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (classData.assets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Não há ativos detalhados para esta classe.'),
            )
          else
            ...classData.assets.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFDCE4ED)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _InfoPill(label: 'Valor', value: _formatCurrency(asset.value)),
                            _InfoPill(label: '% Carteira', value: _formatPercent(asset.portfolioPercent)),
                            _InfoPill(
                              label: 'Mês',
                              value: _formatPercent(asset.monthReturnPercent, withSignal: true),
                            ),
                            _InfoPill(
                              label: 'YTD',
                              value: _formatPercent(asset.ytdReturnPercent, withSignal: true),
                            ),
                            if ((asset.liquidity ?? '').trim().isNotEmpty)
                              _InfoPill(label: 'Liquidez', value: asset.liquidity!.trim()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PerformanceContributionPage extends StatelessWidget {
  const PerformanceContributionPage({
    super.key,
    required this.dashboard,
  });

  final InvestmentDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Contribuição Financeira'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContributionChartCard(
            title: 'Contribuição Financeira no Mês',
            points: dashboard.contributions.month,
            total: dashboard.contributions.monthTotal,
          ),
          const SizedBox(height: 14),
          _ContributionChartCard(
            title: 'Contribuição Financeira no Ano (YTD)',
            points: dashboard.contributions.ytd,
            total: dashboard.contributions.ytdTotal,
          ),
        ],
      ),
    );
  }
}

class _ContributionChartCard extends StatelessWidget {
  const _ContributionChartCard({
    required this.title,
    required this.points,
    required this.total,
  });

  final String title;
  final List<WaterfallPoint> points;
  final double? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valores em R\$',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7A8F),
                ),
          ),
          const SizedBox(height: 14),
          _ContributionWaterfallChart(points: points),
          const SizedBox(height: 8),
          Text(
            'Total: ${_formatCurrency(total)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17375B),
                ),
          ),
          const SizedBox(height: 12),
          _ContributionBreakdown(points: points),
        ],
      ),
    );
  }
}

class _ContributionWaterfallChart extends StatelessWidget {
  const _ContributionWaterfallChart({required this.points});

  final List<WaterfallPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Sem dados de contribuição para este período.'),
      );
    }

    final rangeValues = points.expand((p) => [p.start, p.end]).toList();
    final minValue = math.min<double>(0.0, rangeValues.reduce(math.min));
    final maxValue = math.max<double>(0.0, rangeValues.reduce(math.max));
    final delta = (maxValue - minValue).abs();
    final extra = delta == 0 ? 1 : delta * 0.18;
    final minY = minValue - extra;
    final maxY = maxValue + extra;
    final interval = _axisInterval(minY, maxY);

    final chartWidth = math.max(320.0, points.length * 72.0);

    final barGroups = List.generate(points.length, (index) {
      final point = points[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: point.start,
            toY: point.end,
            width: 22,
            color: point.isTotal
                ? const Color(0xFF44546A)
                : point.value >= 0
                    ? const Color(0xFF198754)
                    : const Color(0xFFD94841),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 280,
        child: BarChart(
          BarChartData(
            minY: minY,
            maxY: maxY,
            barGroups: barGroups,
            gridData: FlGridData(
              horizontalInterval: interval,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE4EAF1),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatCurrencyCompact(value),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF5F6F86)),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 64,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      child: Transform.rotate(
                        angle: -0.58,
                        child: SizedBox(
                          width: 66,
                          child: Text(
                            _shortLabel(points[index].name, maxLength: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4F6079),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContributionBreakdown extends StatelessWidget {
  const _ContributionBreakdown({required this.points});

  final List<WaterfallPoint> points;

  @override
  Widget build(BuildContext context) {
    final rows = points.where((point) => !point.isTotal).toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleRows = rows.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhamento por classe',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C3554),
              ),
        ),
        const SizedBox(height: 8),
        ...visibleRows.map(
          (point) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: point.value >= 0 ? const Color(0xFF198754) : const Color(0xFFD94841),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF40546F),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCurrency(point.value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: point.value >= 0 ? const Color(0xFF1D7E4B) : const Color(0xFFB7423C),
                      ),
                ),
              ],
            ),
          ),
        ),
        if (rows.length > visibleRows.length)
          Text(
            '+${rows.length - visibleRows.length} classes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7A8F),
                ),
          ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7A8F)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoPillDark extends StatelessWidget {
  const _InfoPillDark({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

const List<Color> _chartPalette = [
  Color(0xFF275DAD),
  Color(0xFF00A39A),
  Color(0xFF2E8B57),
  Color(0xFFE07A21),
  Color(0xFFC44569),
  Color(0xFF5D4E9D),
  Color(0xFF587291),
  Color(0xFF7A8C3B),
];

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final NumberFormat _currencyCompactFormatter = NumberFormat.compactCurrency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final NumberFormat _percentFormatter = NumberFormat.decimalPatternDigits(
  locale: 'pt_BR',
  decimalDigits: 2,
);

String _formatCurrency(double? value, {bool compact = false}) {
  if (value == null) {
    return '--';
  }
  return compact ? _currencyCompactFormatter.format(value) : _currencyFormatter.format(value);
}

String _formatCurrencyCompact(double value) {
  return _currencyCompactFormatter.format(value);
}

String _formatPercent(double? value, {bool withSignal = false}) {
  if (value == null) {
    return '--';
  }
  final abs = _percentFormatter.format(value.abs());
  if (!withSignal) {
    return '$abs%';
  }
  final sign = value >= 0 ? '+' : '-';
  return '$sign$abs%';
}

Color _performanceColor(double? value) {
  if (value == null) {
    return const Color(0xFF17375B);
  }
  if (value >= 0) {
    return const Color(0xFF1D7E4B);
  }
  return const Color(0xFFB7423C);
}

double _axisInterval(double minY, double maxY) {
  final delta = (maxY - minY).abs();
  if (delta <= 1000) return 250;
  if (delta <= 5000) return 1000;
  if (delta <= 20000) return 5000;
  if (delta <= 100000) return 20000;
  return 50000;
}

String _shortLabel(String value, {int maxLength = 16}) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 1)}…';
}
