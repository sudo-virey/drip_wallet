// lib/features/history/presentation/pages/history_screen.dart
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/core/utils/icon_converter.dart';
import 'package:drip_wallet/core/services/report_service.dart';
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
  late final ReportService _reportService;

  // Cargar categorías dinámicamente desde la BD
  List<Map<String, dynamic>> _categories = [];
  final List<String> _dateFilterOptions = [
    'Hoy',
    'Esta Semana',
    'Este Mes',
    'Últimos 3 Meses',
    'Este Año',
    'Todas'
  ];

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
    _loadCategories();
    
    // Cargar transacciones del mes actual para History
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final now = DateTime.now();
        context.read<FinanceBloc>().add(
          LoadHistoryForMonth(
            profileId: authState.user.id,
            month: now,
          ),
        );
      }
    });
  }

  /// Cargar categorías dinámicamente desde la BD
  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      
      final response = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .order('name');
      
      if (mounted) {
        final List<Map<String, dynamic>> uniqueCategories = [];
        final Set<String> seenNames = {};
        
        for (final category in response) {
          final name = category['name'] as String;
          if (!seenNames.contains(name)) {
            uniqueCategories.add(category);
            seenNames.add(name);
          }
        }
        
        setState(() {
          _categories = uniqueCategories;
        });
      }
    } catch (e) {
      print('ERROR cargando categorías: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is HistoryLoaded) {
            final allTransactions = state.transactions;

            final filteredTransactions = _applyFilters(allTransactions);

            final Map<String, List<TransactionEntity>> groupedTxs = {};
            for (var tx in filteredTransactions) {
              final dateKey = _formatDateHeader(tx.date);
              groupedTxs.putIfAbsent(dateKey, () => []).add(tx);
            }

            final sortedDateKeys = groupedTxs.keys.toList();
            sortedDateKeys.sort((a, b) {
              final dateA = _extractDateFromKey(a);
              final dateB = _extractDateFromKey(b);
              return dateB.compareTo(dateA);
            });

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFilters()),
                if (filteredTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No hay transacciones',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          for (final dateKey in sortedDateKeys) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateKey,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(
                                  groupedTxs[dateKey]!.length,
                                  (txIndex) {
                                    final tx = groupedTxs[dateKey]![txIndex];
                                    final icon = stringToIconData(tx.icon ?? 'category');
                                    final isExpense = tx.type == 'expense';
                                    final amountColor = isExpense ? Colors.red : Colors.green;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outlineVariant,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: isExpense
                                                    ? Colors.red.withOpacity(0.1)
                                                    : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  icon,
                                                  color: isExpense
                                                      ? Theme.of(context).colorScheme.error
                                                      : Theme.of(context).colorScheme.secondary,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${tx.category} • ${_formatTime(tx.date)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: amountColor,
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
                            ),
                          ],
                        ],
                      ),
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

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateAndShareReport,
        icon: const Icon(Icons.download),
        label: const Text('Descargar Reporte'),
      ),
    );
  }

  Future<void> _generateAndShareReport() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final now = DateTime.now();
    final financeState = context.read<FinanceBloc>().state;

    if (financeState is! HistoryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando datos...')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando reporte...')),
      );

      // Separar transacciones en ingresos y gastos
      final transactions = financeState.transactions;
      final incomes = transactions.where((t) => t.type == 'income').toList();
      final expenses = transactions.where((t) => t.type == 'expense').toList();

      // Para este ejemplo, consideramos todos los expenses como variables
      // En una implementación real, se diferenciarían por categoría o tabla
      final variableExpenses = expenses
          .map((tx) => {
                'title': tx.title,
                'amount': tx.amount,
                'category': tx.category,
              })
          .toList();

      final totalIncome = incomes.fold<double>(0, (sum, tx) => sum + tx.amount);
      final totalVariableExpenses = expenses.fold<double>(0, (sum, tx) => sum + tx.amount);

      // Obtener presupuesto del mes actual (necesitaría venir del dashboard)
      // Por ahora usamos 0 como placeholder
      const budgetLimit = 0.0;

      final file = await _reportService.generateAccountStatement(
        month: now,
        budgetLimit: budgetLimit,
        totalIncome: totalIncome,
        totalFixedExpenses: 0, // No hay gastos fijos en este flujo aún
        totalVariableExpenses: totalVariableExpenses,
        fixedExpenses: [],
        variableExpenses: variableExpenses,
      );

      await _reportService.shareReport(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar reporte: $e')),
        );
      }
    }
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Category Filters (Horizontal scroll)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "Todas las Categorías" button
                _buildCategoryButton(
                  label: 'Todas',
                  isSelected: _selectedCategory == 'Todas las Categorías',
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Todas las Categorías';
                    });
                  },
                ),
                // Individual category buttons
                ...List.generate(
                  _categories.length,
                  (index) {
                    final category = _categories[index];
                    final categoryName = category['name'] as String;
                    final isSelected = _selectedCategory == categoryName;
                    
                    return _buildCategoryButton(
                      label: categoryName,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategory = categoryName;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Date Filter Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => _showDateFilterMenu(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      color: context.dripTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateFilter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Construir botón de categoría
  Widget _buildCategoryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? context.dripTheme.primaryColor
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar menú de filtro de fecha
  void _showDateFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Seleccionar Período',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _dateFilterOptions.length,
              itemBuilder: (context, index) {
                final option = _dateFilterOptions[index];
                final isSelected = _selectedDateFilter == option;
                
                return ListTile(
                  title: Text(option),
                  leading: isSelected
                      ? Icon(Icons.check_circle,
                          color: context.dripTheme.primaryColor)
                      : Icon(Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () {
                    setState(() => _selectedDateFilter = option);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Aplicar filtros de categoría y fecha a las transacciones
  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions) {
    return transactions.where((tx) {
      // Filtro de categoría
      final categoryMatches = _selectedCategory == 'Todas las Categorías' ||
          tx.category == _selectedCategory;

      // Filtro de fecha
      final dateMatches = _isWithinDateRange(tx.date);

      return categoryMatches && dateMatches;
    }).toList();
  }

  /// Verificar si una fecha está dentro del rango seleccionado
  bool _isWithinDateRange(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);

    switch (_selectedDateFilter) {
      case 'Hoy':
        return txDate == today;

      case 'Esta Semana':
        // Lunes de esta semana
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        // Domingo de esta semana (o próximo domingo si hoy es domingo)
        final weekEnd = today.add(Duration(days: 7 - today.weekday));
        // Incluir desde lunes hasta domingo (inclusive)
        return !txDate.isBefore(weekStart) && !txDate.isAfter(weekEnd);

      case 'Este Mes':
        return date.month == now.month && date.year == now.year;

      case 'Últimos 3 Meses':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return !date.isBefore(threeMonthsAgo) && !date.isAfter(now);

      case 'Este Año':
        return date.year == now.year;

      case 'Todas':
        return true;

      default:
        return true;
    }
  }

  /// Extraer fecha de la clave del header para ordenar
  DateTime _extractDateFromKey(String key) {
    try {
      // Parsear fechas como "TODAY, OCT 24", "YESTERDAY, OCT 24", "OCT 24"
      final parts = key.split(', ');
      final dateStr = parts.length > 1 ? parts[1] : key;
      
      final now = DateTime.now();
      final monthDayParts = dateStr.split(' ');
      
      if (monthDayParts.length == 2) {
        final monthStr = monthDayParts[0];
        final dayStr = monthDayParts[1];
        
        final months = [
          'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
        ];
        
        final monthIndex = months.indexOf(monthStr);
        final day = int.tryParse(dayStr) ?? 1;
        
        if (monthIndex >= 0) {
          return DateTime(now.year, monthIndex + 1, day);
        }
      }
    } catch (e) {
      print('Error parsing date key: $key - $e');
    }
    
    return DateTime.now();
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
      return 'HOY, ${months[date.month - 1]} ${date.day}';
    } else if (dateOnly == yesterday) {
      return 'AYER, ${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  /// Formatear hora de la transacción (ej: "2:30 PM")
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
