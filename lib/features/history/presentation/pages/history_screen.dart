// lib/features/history/presentation/pages/history_screen.dart
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedCategory = 'Todas las Categorías';
  String _selectedDateFilter = 'Este Mes';

  // Cargar categorías dinámicamente desde la BD
  List<String> _categories = ['Todas las Categorías'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Cargar dashboard con transacciones
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<FinanceBloc>().add(LoadDashboard(authState.user.id));
    }
  }

  /// Cargar categorías dinámicamente desde la BD
  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      print('DEBUG history: Iniciando carga de categorías...');
      
      // Primero: Ver TODOS los registros sin filtro
      final allResponse = await supabaseClient
          .from('categories')
          .select('*');
      print('DEBUG: Total categorías sin filtro: ${(allResponse as List).length}');
      print('DEBUG: Datos completos: $allResponse');
      
      final response = await supabaseClient
          .from('categories')
          .select('id, name, type')
          .order('name');
      
      print('DEBUG: Categorías cargadas: ${(response as List).length} items');
      print('DEBUG: Datos: $response');
      
      if (mounted) {
        final categoryNames = (response as List)
            .map((e) => e['name'] as String)
            .toSet()
            .toList();
        
        categoryNames.sort();
        
        print('DEBUG: Nombres únicos: $categoryNames');
        
        setState(() {
          _categories = ['Todas las Categorías', ...categoryNames];
          print('DEBUG: Categorías finales: $_categories');
        });
      }
    } catch (e, stackTrace) {
      print('ERROR CRÍTICO cargando categorías: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Presupuesto Familiar',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_balance_wallet,
                color: context.dripTheme.primaryColor, size: 20),
          ),
        ],
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is DashboardLoaded) {
            final dashboard = state.dashboard;
            final transactions = dashboard.recentTransactions;

            // Agrupar transacciones por fecha
            final Map<String, List<TransactionEntity>> groupedTxs = {};
            for (var tx in transactions) {
              final dateKey = _formatDateHeader(tx.date);
              groupedTxs.putIfAbsent(dateKey, () => []).add(tx);
            }

            return Column(
              children: [
                _buildFilters(),
                if (transactions.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      itemCount: groupedTxs.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = groupedTxs.keys.toList()[dateIndex];
                        final txList = groupedTxs[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Text(
                              dateKey,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Transactions for this date
                            ...List.generate(
                              txList.length,
                              (txIndex) {
                                final tx = txList[txIndex];
                                final icon =
                                    _getIconForCategory(tx.category);

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              icon,
                                              color: const Color(
                                                  0xFF001F3F),
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                tx.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${tx.category} • ${_formatTime(tx.date)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors
                                                      .grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amount
                                        Text(
                                          '${tx.type == 'expense' ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: tx.type == 'expense'
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
              ],
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
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Transactions Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.tune, color: Colors.grey.shade700, size: 24),
              ),
            ],
          ),
        ),

        // Category Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _categories.length,
                (index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.dripTheme.primaryColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black,
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
        const SizedBox(height: 12),

        // Date Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedDateFilter,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Mapear categoría a icono
  IconData _getIconForCategory(String category) {
    final iconMap = {
      'Food': Icons.restaurant,
      'Transit': Icons.directions_car,
      'Bills': Icons.receipt,
      'Shop': Icons.shopping_bag,
      'Home': Icons.home,
      'Fun': Icons.sentiment_satisfied,
      'Other': Icons.more_horiz,
    };
    return iconMap[category] ?? Icons.shopping_cart;
  }

  /// Formatear fecha para header (ej: "TODAY, OCT 24")
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];

    if (dateOnly == today) {
      return 'TODAY, ${months[date.month - 1]} ${date.day}';
    } else if (dateOnly == yesterday) {
      return 'YESTERDAY, ${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  /// Formatear hora de la transacción (ej: "2:30 PM")
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
