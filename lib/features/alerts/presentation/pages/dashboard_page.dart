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
  bool _hideValues = true;

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
                        'NÃ£o foi possÃ­vel carregar os dados financeiros.',
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
                    hideValues: _hideValues,
                    onToggleValues: () => setState(() => _hideValues = !_hideValues),
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
                      asOf: dashboard.asOf,
                      hideValues: _hideValues,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _AllocationCard(
                      dashboard: dashboard,
                      touchedIndex: _touchedPieIndex,
                      hideValues: _hideValues,
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
    required this.hideValues,
    required this.onToggleValues,
    required this.onLogout,
  });

  final String customerName;
  final bool hideValues;
  final VoidCallback onToggleValues;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(customerName);

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
                'assets/images/logus_logo.png',
                height: 28,
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleValues,
                icon: Icon(
                  hideValues ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                color: Colors.white,
                tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
              ),
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
            'Olá, $firstName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
    required this.asOf,
    required this.hideValues,
  });

  final InvestmentDashboardData dashboard;
  final String benchmarkLabel;
  final DateTime? asOf;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final dateLabel = asOf == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(asOf!);
    final yearLabel = (asOf ?? DateTime.now()).year.toString();
    final isIbovespa = benchmarkLabel.toLowerCase() == 'ibovespa';
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Valor consolidado da carteira',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                hideValues ? '••••' : _formatCurrency(dashboard.totalValue),
                textAlign: TextAlign.center,
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
                primary: hideValues
                    ? '••••'
                    : _formatPercent(dashboard.returns.month.percent, withSignal: true),
                secondary:
                    hideValues ? '••••' : _formatCurrency(dashboard.returns.month.value),
                benchmark: hideValues
                    ? '$benchmarkLabel: ••••'
                    : '$benchmarkLabel: ${_formatPercent(isIbovespa ? dashboard.returns.month.benchmark?.abs() : dashboard.returns.month.benchmark)}',
                accent: _performanceColor(dashboard.returns.month.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: yearLabel,
                primary: hideValues
                    ? '••••'
                    : _formatPercent(dashboard.returns.ytd.percent, withSignal: true),
                secondary: hideValues ? '••••' : _formatCurrency(dashboard.returns.ytd.value),
                benchmark: hideValues
                    ? '$benchmarkLabel: ••••'
                    : '$benchmarkLabel: ${_formatPercent(isIbovespa ? dashboard.returns.ytd.benchmark?.abs() : dashboard.returns.ytd.benchmark)}',
                accent: _performanceColor(dashboard.returns.ytd.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: '12 Meses',
                primary: hideValues
                    ? '••••'
                    : _formatPercent(dashboard.returns.twelveMonths.percent, withSignal: true),
                secondary: hideValues
                    ? '••••'
                    : _formatCurrency(dashboard.returns.twelveMonths.value),
                benchmark: hideValues
                    ? '$benchmarkLabel: ••••'
                    : '$benchmarkLabel: ${_formatPercent(isIbovespa ? dashboard.returns.twelveMonths.benchmark?.abs() : dashboard.returns.twelveMonths.benchmark)}',
                accent: _performanceColor(dashboard.returns.twelveMonths.percent),
              ),
            ),
            SizedBox(
              width: _cardWidth(context),
              child: _MetricCard(
                title: 'Volatilidade (90 dias)',
                primary: hideValues ? '••••' : _formatPercent(dashboard.volatility90Days),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF0E4A87),
                  fontWeight: FontWeight.w700,
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
                    color: const Color(0xFF0E4A87),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (benchmark != null) ...[
            const SizedBox(height: 6),
            Text(
              benchmark!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0E4A87),
                    fontWeight: FontWeight.w700,
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
    required this.hideValues,
    required this.onTouch,
    required this.onOpenOverview,
  });

  final InvestmentDashboardData dashboard;
  final int touchedIndex;
  final bool hideValues;
  final void Function(int index, bool openDetails) onTouch;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final classes = dashboard.classes.where((item) => !_isTotalCarteira(item.name)).toList();
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
            'AlocaÃ§Ã£o por classe de ativo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17375B),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque no grÃ¡fico ou na legenda para ver os investimentos da classe.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7A8F)),
          ),
          const SizedBox(height: 14),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('NÃ£o hÃ¡ dados de classe disponÃ­veis para este cliente.'),
            )
          else ...[
            Center(
              child: SizedBox(
                height: 220,
                width: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 34,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
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
                        title: hideValues || percentValue <= 0
                            ? ''
                            : '${percentValue.toStringAsFixed(2)}%',
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
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                                hideValues
                                    ? '•••• ••••'
                                    : '${_formatCurrency(item.value, compact: true)} â€¢ ${_formatPercent(item.percent)}',
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
            label: const Text('ContribuiÃ§Ã£o'),
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
    final visibleClasses = classes.where((item) => !_isHiddenClassName(item.name)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Abertura da Classe de Ativos',
          style: TextStyle(color: Color(0xFF0E4A87)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0E4A87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: visibleClasses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('NÃ£o hÃ¡ classes de ativo disponÃ­veis para exibiÃ§Ã£o.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleClasses.length,
              itemBuilder: (context, index) {
                final item = visibleClasses[index];
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
                                        color: const Color(0xFF0E4A87),
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
                                value: _formatReturnLines(
                                  nominal: item.monthContribution,
                                  percent: item.monthReturnPercent,
                                ),
                              ),
                              _InfoPill(
                                label: 'Retorno Ano',
                                value: _formatReturnLines(
                                  nominal: item.ytdContribution,
                                  percent: item.ytdReturnPercent,
                                ),
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
      appBar: AppBar(
        title: Text(
          classData.name,
          style: const TextStyle(color: Color(0xFF0E4A87)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0E4A87)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
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
                  value: _formatReturnLines(
                    nominal: classData.monthContribution,
                    percent: classData.monthReturnPercent,
                  ),
                ),
                _InfoPillDark(
                  label: 'Retorno Ano',
                  value: _formatReturnLines(
                    nominal: classData.ytdContribution,
                    percent: classData.ytdReturnPercent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Investimentos da classe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0E4A87),
                ),
          ),
          const SizedBox(height: 10),
          if (classData.assets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('NÃ£o hÃ¡ ativos detalhados para esta classe.'),
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
                                color: const Color(0xFF0E4A87),
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
                              value: _formatReturnLines(
                                nominal: _nominalFromBase(
                                  asset.value,
                                  asset.monthReturnPercent,
                                ),
                                percent: asset.monthReturnPercent,
                              ),
                            ),
                            _InfoPill(
                              label: 'Retorno Ano',
                              value: _formatReturnLines(
                                nominal: _nominalFromBase(
                                  asset.value,
                                  asset.ytdReturnPercent,
                                ),
                                percent: asset.ytdReturnPercent,
                              ),
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
        title: const Text('Performance ContribuiÃ§Ã£o Financeira'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContributionChartCard(
            title: 'ContribuiÃ§Ã£o Financeira no MÃªs',
            points: dashboard.contributions.month,
            total: dashboard.contributions.monthTotal,
          ),
          const SizedBox(height: 14),
          _ContributionChartCard(
            title: 'ContribuiÃ§Ã£o Financeira no Ano (YTD)',
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
          _ContributionBarChart(points: points),
          const SizedBox(height: 8),
          Text(
            'Total: ${_formatCurrency(total)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17375B),
                ),
          ),
        ],
      ),
    );
  }
}

class _ContributionBarChart extends StatelessWidget {
  const _ContributionBarChart({required this.points});

  final List<WaterfallPoint> points;

  @override
  Widget build(BuildContext context) {
    final rows = points.where((point) => !point.isTotal).toList();
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Sem dados de contribuiÃ§Ã£o para este perÃ­odo.'),
      );
    }

    final maxAbs = rows.map((row) => row.value.abs()).fold<double>(0, math.max);

    return Column(
      children: rows
          .map(
            (row) => _ContributionBarRow(
              label: row.name,
              value: row.value,
              maxAbs: maxAbs,
            ),
          )
          .toList(),
    );
  }
}

class _ContributionBarRow extends StatelessWidget {
  const _ContributionBarRow({
    required this.label,
    required this.value,
    required this.maxAbs,
  });

  final String label;
  final double value;
  final double maxAbs;

  @override
  Widget build(BuildContext context) {
    final barColor = value >= 0 ? const Color(0xFF198754) : const Color(0xFFD94841);
    final valueLabel = _formatCurrencyCompact(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              _shortLabel(label, maxLength: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF40546F),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = (constraints.maxWidth - 1) / 2;
                final width = maxAbs <= 0 ? 0 : (value.abs() / maxAbs) * halfWidth;
                return Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: value < 0 ? width : 0,
                          height: 10,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color: const Color(0xFFE4EAF1),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: value > 0 ? width : 0,
                          height: 10,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              valueLabel,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
            ),
          ),
        ],
      ),
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
  return '${value.substring(0, maxLength - 1)}â€¦';
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return name;
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  return parts.isEmpty ? trimmed : parts.first;
}

bool _isTotalCarteira(String name) {
  final normalized = _normalizeLabel(name);
  return normalized.contains('total da carteira') || normalized.contains('total carteira');
}

bool _isHiddenClassName(String name) {
  return _isTotalCarteira(name) || _isCaixaBloqueado(name);
}

bool _isCaixaBloqueado(String name) {
  final normalized = _normalizeLabel(name);
  return normalized.contains('caixa bloqueado') || normalized.contains('caixa bloqueada');
}

String _formatReturnLines({double? nominal, double? percent}) {
  final nominalLabel = _formatCurrency(nominal);
  final percentLabel = _formatPercent(percent, withSignal: true);
  return '$nominalLabel\n$percentLabel';
}

double? _nominalFromBase(double? baseValue, double? percent) {
  if (baseValue == null || percent == null) {
    return null;
  }
  return baseValue * percent / 100;
}

String _normalizeLabel(String value) {
  var result = value.toLowerCase();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'è': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ò': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  replacements.forEach((key, replacement) {
    result = result.replaceAll(key, replacement);
  });
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  return result;
}

