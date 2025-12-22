import 'alert.dart';

class AlertListResult {
  AlertListResult({
    required this.totalItems,
    required this.items,
  });

  final int totalItems;
  final List<Alert> items;
}
