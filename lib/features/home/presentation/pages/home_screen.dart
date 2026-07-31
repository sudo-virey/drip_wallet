import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/edit_expense_transaction_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/edit_income_transaction_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/expense_transaction_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_balance_card.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_header_section.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_month_selector.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_recent_transactions_section.dart';
import 'package:drip_wallet/features/home/presentation/widgets/home_recurring_transactions_section.dart';
import 'package:drip_wallet/features/home/presentation/widgets/income_transaction_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;

  final List<String> _months = const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<FinanceBloc>().add(LoadDashboard(authState.user.id));
      }
    });
  }

  void _changeMonth(int deltaMonths) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + deltaMonths);
    });

    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<FinanceBloc>().add(
            LoadDashboardForMonth(
              profileId: user.id,
              month: _selectedMonth,
            ),
          );
    }
  }

  void _showIncomeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => const IncomeTransactionModal(),
    );
  }

  void _showExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => const ExpenseTransactionModal(),
    );
  }

  void _showTransactionOptions(TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF0066FF)),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditTransactionModal(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(transaction);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionModal(TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        if (transaction.type == 'income') {
          return EditIncomeTransactionModal(transaction: transaction);
        }
        return EditExpenseTransactionModal(transaction: transaction);
      },
    );
  }

  void _showDeleteConfirmation(TransactionEntity transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: Text(
          '¿Deseas eliminar "${transaction.title}"? Será opacada pero permanecerá en el registro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final user = supabase.Supabase.instance.client.auth.currentUser;
              if (user != null) {
                context.read<FinanceBloc>().add(
                      DeleteTransaction(
                        profileId: user.id,
                        transactionId: transaction.id,
                      ),
                    );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Transacción eliminada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated) {
            context.read<FinanceBloc>().add(LoadDashboard(authState.user.id));
          }
        },
        child: BlocListener<FinanceBloc, FinanceState>(
          listener: (context, state) {
            if (state is FinanceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (state is TransactionAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ ${state.transaction.title} added'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) {
              if (state is FinanceLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is FinanceError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                    ],
                  ),
                );
              }

              if (state is! DashboardLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final dashboard = state.dashboard;
              final user = supabase.Supabase.instance.client.auth.currentUser;
              final fullName = user?.userMetadata?['name'] as String? ?? 'Usuario';
              final firstName = fullName.split(' ').first.toLowerCase();
              final greeting = user != null ? 'Hola $firstName' : 'Hola';

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: RefreshIndicator(
                  onRefresh: () async {
                    final activeUser = supabase.Supabase.instance.client.auth.currentUser;
                    if (activeUser != null) {
                      context.read<FinanceBloc>().refreshView(
                            target: FinanceViewTarget.home,
                            profileId: activeUser.id,
                            month: _selectedMonth,
                          );
                    }
                    await Future<void>.delayed(const Duration(milliseconds: 300));
                  },
                  child: Column(
                    children: [
                      HomeHeaderSection(
                        greeting: greeting,
                        accentColor: context.dripTheme.primaryColor,
                      ),
                      HomeMonthSelector(
                        selectedMonth: _selectedMonth,
                        months: _months,
                        onPrevious: () => _changeMonth(-1),
                        onNext: () => _changeMonth(1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeBalanceCard(
                              dashboard: dashboard,
                              onSettingsTap: () => context.push('/budget-setup'),
                            ),
                            const SizedBox(height: 32),
                            HomeRecurringTransactionsSection(
                              selectedMonth: _selectedMonth,
                            ),
                            const SizedBox(height: 32),
                            HomeRecentTransactionsSection(
                              dashboard: dashboard,
                              onSeeAll: () => context.push('/history'),
                              onLongPressTransaction: _showTransactionOptions,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: HomeQuickActions(
        onIncomePressed: _showIncomeModal,
        onExpensePressed: _showExpenseModal,
      ),
    );
  }
}
