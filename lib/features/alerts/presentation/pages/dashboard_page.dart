import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../widgets/summary_card.dart';
import '../../../auth/data/models/login_response.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/alert.dart';
import '../../data/models/alert_filters.dart';
import '../../data/models/alert_list_result.dart';
import '../../data/models/alert_summary.dart';
import '../../domain/alert_enums.dart';
import '../../data/repositories/alert_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<AlertSummary> _summaryFuture;
  late Future<AlertListResult> _alertsFuture;
  bool _initialized = false;
  final AlertFilters _filters = const AlertFilters(pageSize: 20);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repository = context.read<AlertRepository>();
      _summaryFuture = repository.fetchSummary();
      _alertsFuture = repository.fetchAlerts(filters: _filters);
      _initialized = true;
    }
  }

  Future<void> _refresh() async {
    final repository = context.read<AlertRepository>();
    setState(() {
      _summaryFuture = repository.fetchSummary();
      _alertsFuture = repository.fetchAlerts(filters: _filters);
    });
    await Future.wait([_summaryFuture, _alertsFuture]);
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
            if (user != null) _buildUserCard(context, user),
            const SizedBox(height: 16),
            FutureBuilder<AlertSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorMessage(
                    message: 'Não foi possível carregar os dados de resumo.',
                    error: snapshot.error,
                  );
                }
                final summary = snapshot.data!;
                return _buildSummary(context, summary);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Alertas recentes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<AlertListResult>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorMessage(
                    message: 'Não foi possível carregar os alertas.',
                    error: snapshot.error,
                  );
                }
                final result = snapshot.data!;
                if (result.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Nenhum alerta encontrado.'),
                  );
                }
                return Column(
                  children: result.items.map((alert) {
                    return _AlertCard(
                      alert: alert,
                      onResolve: () => _handleAction(
                        () => context.read<AlertRepository>().resolveAlert(alert.id),
                        successMessage: 'Alerta marcado como resolvido.',
                      ),
                      onIgnore: () => _handleAction(
                        () => context.read<AlertRepository>().ignoreAlert(alert.id),
                        successMessage: 'Alerta marcado como ignorado.',
                      ),
                      onSnooze: () => _handleSnooze(alert),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserProfile user) {
    return Card(
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
    );
  }

  Widget _buildSummary(BuildContext context, AlertSummary summary) {
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
                  label: Text('${entry.key.label}: ${entry.value}'),
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
                  label: Text('${entry.key.label}: ${entry.value}'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    Future<dynamic> Function() request, {
    required String successMessage,
  }) async {
    try {
      await request();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleSnooze(Alert alert) async {
    final days = await _pickSnoozeDays();
    if (days == null) return;
    await _handleAction(
      () => context.read<AlertRepository>().snoozeAlert(
            alert.id,
            days: days,
          ),
      successMessage: 'Alerta adiado por $days dias.',
    );
  }

  Future<int?> _pickSnoozeDays() {
    return showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Adiar alerta'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(7),
            child: const Text('7 dias'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(30),
            child: const Text('30 dias'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onResolve,
    required this.onIgnore,
    required this.onSnooze,
  });

  final Alert alert;
  final VoidCallback onResolve;
  final VoidCallback onIgnore;
  final VoidCallback onSnooze;

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(alert.status.label),
                  backgroundColor: _statusColor(alert.status, context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.description ?? 'Sem descrição',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${alert.clientName}'),
            Text('Tipo: ${alert.type.label} • Severidade: ${alert.severity.label}'),
            Text('Referência: ${_formatDate(alert.referenceDate)}'),
            if (alert.daysFromReference != null)
              Text('Dias da referência: ${alert.daysFromReference}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.check),
                  label: const Text('Resolver'),
                ),
                OutlinedButton.icon(
                  onPressed: onIgnore,
                  icon: const Icon(Icons.remove_done),
                  label: const Text('Ignorar'),
                ),
                TextButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.snooze),
                  label: const Text('Adiar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _statusColor(AlertStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case AlertStatus.pending:
        return theme.colorScheme.secondaryContainer;
      case AlertStatus.inProgress:
        return theme.colorScheme.tertiaryContainer;
      case AlertStatus.resolved:
        return theme.colorScheme.primaryContainer;
      case AlertStatus.snoozed:
        return theme.colorScheme.surfaceContainerHighest;
      case AlertStatus.ignored:
        return theme.colorScheme.errorContainer;
    }
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({
    required this.message,
    this.error,
  });

  final String message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 32),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text('$error'),
        ],
      ],
    );
  }
}
