import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/alert_summary.dart';
import '../../data/repositories/alert_repository.dart';
import '../../../../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<AlertSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = context.read<AlertRepository>().fetchSummary();
  }

  Future<void> _refresh() {
    final future = context.read<AlertRepository>().fetchSummary();
    setState(() {
      _summaryFuture = future;
    });
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas do CRM'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: auth.isLoading ? null : auth.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  title: Text(
                    user.person.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${user.email}\nPerfil: ${user.profile.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FutureBuilder<AlertSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Não foi possível carregar os alertas.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}'),
                    ],
                  );
                }

                final summary = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: _cardWidth(context),
                          child: SummaryCard(
                            title: 'Alertas ativos',
                            value: summary.totalActive.toString(),
                            icon: Icons.notifications_active_outlined,
                          ),
                        ),
                        SizedBox(
                          width: _cardWidth(context),
                          child: SummaryCard(
                            title: 'Críticos',
                            value: summary.critical.toString(),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                        SizedBox(
                          width: _cardWidth(context),
                          child: SummaryCard(
                            title: 'Vencidos +7 dias',
                            value: summary.overdueSevenDays.toString(),
                            icon: Icons.schedule,
                          ),
                        ),
                        SizedBox(
                          width: _cardWidth(context),
                          child: SummaryCard(
                            title: 'Próximos 7 dias',
                            value: summary.nextSevenDays.toString(),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Alertas por tipo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: summary.byType.entries
                          .map(
                            (entry) => Chip(
                              avatar: const Icon(Icons.category_outlined, size: 16),
                              label: Text('${entry.key}: ${entry.value}'),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alertas por status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: summary.byStatus.entries
                          .map(
                            (entry) => Chip(
                              avatar: const Icon(Icons.flag_outlined, size: 16),
                              label: Text('${entry.key}: ${entry.value}'),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return (width - 16 * 2 - 12) / 2;
    }
    return width - 32;
  }
}
