import 'package:flutter/material.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:drip_wallet/features/home/presentation/widgets/edit_recurring_transaction_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/add_recurring_income_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringIncomeScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const RecurringIncomeScreen({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<RecurringIncomeScreen> createState() => _RecurringIncomeScreenState();
}

class _RecurringIncomeScreenState extends State<RecurringIncomeScreen> {
  List<Map<String, dynamic>> _recurringIncome = [];
  bool _isLoading = true;
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRecurringIncome();
  }

  Future<void> _loadRecurringIncome() async {
    try {
      final user = getIt<SupabaseClient>().auth.currentUser;
      if (user == null) return;

      final datasource = getIt<FinanceRemoteDataSource>();
      final recurringList = await datasource.getRecurringTransactionsForMonth(
        user.id,
        widget.selectedMonth,
      );

      // Filtrar solo ingresos
      final income = recurringList.where((r) => r['type'] == 'income').toList();

      double total = 0.0;
      for (var item in income) {
        total += (item['amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _recurringIncome = income;
          _totalIncome = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando ingresos regulares: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRecurring(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingreso regular'),
        content: const Text('¿Estás seguro de que deseas eliminar este ingreso regular?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final datasource = getIt<FinanceRemoteDataSource>();
      await datasource.deleteRecurringTransaction(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingreso regular eliminado')),
        );
        _loadRecurringIncome();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ingresos Regulares',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0066FF),
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0066FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total este mes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_totalIncome.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List of Recurring Income
                    if (_recurringIncome.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ingresos regulares',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los ingresos regulares que agregues aparecerán aquí',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: List.generate(
                          _recurringIncome.length,
                          (index) {
                            final income = _recurringIncome[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            income['description'] as String? ?? 'Ingreso',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Desde: ${DateTime.parse(income['start_date']).toLocal().toString().split(' ')[0]}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${(income['amount'] as num).toDouble().toStringAsFixed(2)}',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder: (context) =>
                                                      EditRecurringTransactionModal(
                                                    recurringId:
                                                        income['id'] as String,
                                                    recurringData: {
                                                      ...income,
                                                      'category':
                                                          income['category'] ??
                                                              'Otro',
                                                    },
                                                    onSuccess: _loadRecurringIncome,
                                                  ),
                                                );
                                              },
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => _deleteRecurring(income['id'] as String),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (context) => AddRecurringIncomeModal(
              onSuccess: _loadRecurringIncome,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
