import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewExpenseModal extends StatefulWidget {
  const NewExpenseModal({super.key});

  @override
  State<NewExpenseModal> createState() => _NewExpenseModalState();
}

class _NewExpenseModalState extends State<NewExpenseModal> {
  late DripFormController _formController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  double _amount = 0.0;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';

  // Categorías cargadas dinámicamente desde la BD
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    _formController = DripFormController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController.addListener(_updateAmount);
    _loadCategories();
  }

  /// Cargar categorías dinámicamente desde la BD
  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      print('DEBUG new_expense_modal: Iniciando carga de categorías...');
      
      // Primero: Ver TODOS los registros sin filtro
      final allCategories = await supabaseClient
          .from('categories')
          .select('*');
      print('DEBUG: Total categorías sin filtro: ${(allCategories as List).length}');
      print('DEBUG: Datos completos: $allCategories');
      
      // Cargar gastos
      final expenseResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'expense')
          .order('name');
      print('DEBUG: Gastos cargados: ${(expenseResponse as List).length} items');
      print('DEBUG: Datos gastos: $expenseResponse');
      
      // Cargar ingresos
      final incomeResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'income')
          .order('name');
      print('DEBUG: Ingresos cargados: ${(incomeResponse as List).length} items');
      print('DEBUG: Datos ingresos: $incomeResponse');
      
      if (mounted) {
        setState(() {
          _expenseCategories = (expenseResponse as List)
              .map((e) => {
                'name': e['name'] as String,
                'icon': _iconFromString(e['icon'] as String),
              })
              .toList();
          
          _incomeCategories = (incomeResponse as List)
              .map((e) => {
                'name': e['name'] as String,
                'icon': _iconFromString(e['icon'] as String),
              })
              .toList();
          
          print('DEBUG: Categorías procesadas - Expense: ${_expenseCategories.length}, Income: ${_incomeCategories.length}');
          
          // Establecer primera categoría por defecto
          if (_expenseCategories.isNotEmpty) {
            _selectedCategory = _expenseCategories[0]['name'] as String;
          }
        });
      }
    } catch (e, stackTrace) {
      print('ERROR CRÍTICO cargando categorías: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Convertir nombre de icono a IconData
  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'receipt':
        return Icons.receipt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'attach_money':
        return Icons.attach_money;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'favorite':
        return Icons.favorite;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.shopping_cart;
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Actualizar _amount cuando el usuario escribe en el TextField
  void _updateAmount() {
    setState(() {
      _amount = double.tryParse(_amountController.text) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = _selectedType == 'income';
    final titleText = isIncome ? 'Nuevo Ingreso' : 'Nuevo Gasto';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    titleText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'expense';
                              if (_expenseCategories.isNotEmpty) {
                                _selectedCategory = _expenseCategories[0]['name'] as String;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == 'expense'
                                  ? Colors.red.shade500
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_down,
                                  color: _selectedType == 'expense'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Gasto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == 'expense'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'income';
                              if (_incomeCategories.isNotEmpty) {
                                _selectedCategory = _incomeCategories[0]['name'] as String;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == 'income'
                                  ? Colors.green.shade500
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: _selectedType == 'income'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ingreso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == 'income'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount Input
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'MONTO',
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$',
                              style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _amountController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    fontSize: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Category Selection
                  Text(
                    'Categoría',
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _selectedType == 'income'
                        ? _incomeCategories.length
                        : _expenseCategories.length,
                    itemBuilder: (context, index) {
                      final categories = _selectedType == 'income'
                          ? _incomeCategories
                          : _expenseCategories;
                      final category = categories[index];
                      final isSelected = _selectedCategory == category['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(
                            () => _selectedCategory = category['name'],
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category['icon'],
                                color:
                                    isSelected ? Colors.white : Colors.black,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Description Field
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'p.ej., Compras de la semana',
                      labelText: 'Descripción',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Field
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha',
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedDate.day == DateTime.now().day
                                    ? 'Hoy'
                                    : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DripButton(
                      onPressed: _saveExpense,
                      label: _selectedType == 'income' ? 'Guardar Ingreso' : 'Guardar Gasto',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Guardar la transacción y disparar evento del FinanceBloc
  void _saveExpense() {
    // Validar monto
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener userId del AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Preparar datos de la transacción
    final transactionData = {
      'title': _selectedCategory,
      'category': _selectedCategory,
      'amount': _amount,
      'type': _selectedType,
      'date': _selectedDate,
      'description': _descriptionController.text,
    };

    // Disparar evento AddTransaction
    context.read<FinanceBloc>().add(
      AddTransaction(
        profileId: authState.user.id,
        transactionData: transactionData,
      ),
    );

    // Cerrar modal
    Navigator.pop(context);
  }
}
