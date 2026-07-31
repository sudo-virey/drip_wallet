// lib/features/home/presentation/pages/home_screen.dart
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/new_expense_modal.dart';
import 'package:drip_wallet/features/home/presentation/widgets/edit_transaction_modal.dart';
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

  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Builder(
          builder: (context) {
            String greeting = 'Hola';
            final user = supabase.Supabase.instance.client.auth.currentUser;
            if (user != null) {
              final fullName = user.userMetadata?['name'] as String? ?? 'Usuario';
              final firstName = fullName.split(' ').first.toLowerCase();
              greeting = 'Hola $firstName';
            }
            return Text(
              greeting,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066FF),
              ),
            );
          },
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              Icons.notifications_none,
              color: context.dripTheme.primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
      // BlocListener<AuthBloc> escucha cambios de autenticación
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          // Cuando el usuario se autentica, cargar el dashboard
          if (authState is Authenticated) {
            context.read<FinanceBloc>().add(LoadDashboard(authState.user.id));
          }
        },
        // BlocListener<FinanceBloc> para mostrar snackbars de éxito/error
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
          // BlocBuilder<FinanceBloc> para mostrar el contenido según el estado
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) {
              if (state is FinanceLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is DashboardLoaded) {
                final dashboard = state.dashboard;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMonthSelector(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceCard(context, dashboard),
                            const SizedBox(height: 32),
                            _buildRecentTransactionsHeader(),
                            const SizedBox(height: 16),
                            _buildTransactionsList(dashboard),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
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

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade500,
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
            builder: (context) => const NewExpenseModal(),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final monthYear = '${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    final isCurrentMonth = _selectedMonth.year == DateTime.now().year && _selectedMonth.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                  // Cargar datos del mes seleccionado
                  final user = supabase.Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context.read<FinanceBloc>().add(
                      LoadDashboardForMonth(
                        profileId: user.id,
                        month: _selectedMonth,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF0066FF)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                monthYear,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              if (isCurrentMonth)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Mes actual',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                  // Cargar datos del mes seleccionado
                  final user = supabase.Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context.read<FinanceBloc>().add(
                      LoadDashboardForMonth(
                        profileId: user.id,
                        month: _selectedMonth,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF0066FF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardEntity dashboard) {
    final double spent = dashboard.totalExpense;
    final double budget = dashboard.budgetLimit;
    final double available = dashboard.balance;
    final double progressPercentage = budget > 0 ? spent / budget : 0;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF001F3F).withValues(alpha: 0.9),
                const Color(0xFF004B87).withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001F3F).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'SALDO DISPONIBLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB0D4FF),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${available.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gastado',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB0D4FF)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${spent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Presupuesto',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB0D4FF)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${budget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                // Barra de fondo VERDE (presupuesto disponible)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2ECC71), // Verde
                    ),
                  ),
                ),
                // Barra ROJA superpuesta (gasto actual)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFE74C3C), // Rojo
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => context.push('/budget-setup'),
            child: const Icon(
              Icons.settings_outlined,
              size: 24,
              color: Color(0xFFB0D4FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transacciones Recientes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Ver Todo',
            style: TextStyle(
              color: Color(0xFF0066FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showTransactionOptions(BuildContext context, TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF0066FF)),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditTransactionModal(context, transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, transaction);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionModal(BuildContext context, TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => EditTransactionModal(transaction: transaction),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TransactionEntity transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: Text('¿Deseas eliminar "${transaction.title}"? Será opacada pero permanecerá en el registro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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

  Widget _buildTransactionsList(DashboardEntity dashboard) {
    if (dashboard.recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        dashboard.recentTransactions.length,
        (index) {
          final transaction = dashboard.recentTransactions[index];

          // Mapear categoría a icono
          final iconMap = {
            'Food': Icons.restaurant,
            'Transit': Icons.directions_car,
            'Bills': Icons.receipt,
            'Shop': Icons.shopping_bag,
            'Home': Icons.home,
            'Fun': Icons.sentiment_satisfied,
            'Other': Icons.more_horiz,
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onLongPress: () => _showTransactionOptions(context, transaction),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconMap[transaction.category] ?? Icons.shopping_cart,
                        color: const Color(0xFF001F3F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${transaction.type == 'expense' ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: transaction.type == 'expense' ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
