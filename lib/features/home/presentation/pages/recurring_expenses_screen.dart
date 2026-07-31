import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:drip_wallet/features/home/presentation/widgets/edit_recurring_transaction_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/add_recurring_expense_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringExpensesScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const RecurringExpensesScreen({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  List<Map<String, dynamic>> _recurringExpenses = [];
  bool _isLoading = true;
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRecurringExpenses();
  }

  Future<void> _loadRecurringExpenses() async {
    try {
      final user = getIt<SupabaseClient>().auth.currentUser;
      if (user == null) return;

      final datasource = getIt<FinanceRemoteDataSource>();
      final recurringList = await datasource.getRecurringTransactionsForMonth(
        user.id,
        widget.selectedMonth,
      );

      // Filtrar solo gastos
      final expenses = recurringList.where((r) => r['type'] == 'expense').toList();

      double total = 0.0;
      for (var expense in expenses) {
        total += (expense['amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _recurringExpenses = expenses;
          _totalExpenses = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando gastos regulares: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRecurring(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto regular'),
        content: const Text('¿Estás seguro de que deseas eliminar este gasto regular?'),
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
          const SnackBar(content: Text('Gasto regular eliminado')),
        );
        _loadRecurringExpenses();
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
          'Gastos Regulares',
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
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
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
                            '\$${_totalExpenses.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List of Recurring Expenses
                    if (_recurringExpenses.isEmpty)
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
                              'No hay gastos regulares',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los gastos regulares que agregues aparecerán aquí',
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
                          _recurringExpenses.length,
                          (index) {
                            final expense = _recurringExpenses[index];
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
                                            expense['description'] as String? ?? 'Gasto',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Desde: ${DateTime.parse(expense['start_date']).toLocal().toString().split(' ')[0]}',
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
                                          '\$${(expense['amount'] as num).toDouble().toStringAsFixed(2)}',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.error,
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
                                                        expense['id'] as String,
                                                    recurringData: {
                                                      ...expense,
                                                      'category':
                                                          expense['category'] ??
                                                              'Otro',
                                                    },
                                                    onSuccess: _loadRecurringExpenses,
                                                  ),
                                                );
                                              },
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => _deleteRecurring(expense['id'] as String),
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
        backgroundColor: theme.colorScheme.error,
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
            builder: (context) => AddRecurringExpenseModal(
              onSuccess: _loadRecurringExpenses,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
