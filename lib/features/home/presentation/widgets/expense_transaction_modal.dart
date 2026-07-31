import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/reusable_form_components.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseTransactionModal extends StatefulWidget {
  const ExpenseTransactionModal({super.key});

  @override
  State<ExpenseTransactionModal> createState() => _ExpenseTransactionModalState();
}

class _ExpenseTransactionModalState extends State<ExpenseTransactionModal> {
  late DripFormController _formController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  double _amount = 0.0;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate;
  
  bool _isRecurring = false;
  bool _hasEndDate = false;

  List<Map<String, dynamic>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _formController = DripFormController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController.addListener(_updateAmount);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      
      final expenseResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'expense')
          .order('name');
      
      if (mounted) {
        setState(() {
          _expenseCategories = (expenseResponse as List)
              .map((e) => {
                'name': e['name'] as String,
                'icon': e['icon'] as String,
              })
              .toList();
          
          if (_expenseCategories.isNotEmpty) {
            _selectedCategory = _expenseCategories[0]['name'] as String;
          }
        });
      }
    } catch (e) {
      print('ERROR cargando categorías de gasto: $e');
    }
  }

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

  void _updateAmount() {
    setState(() {
      _amount = double.tryParse(_amountController.text) ?? 0.0;
    });
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _selectedDate.add(const Duration(days: 365)),
      firstDate: _selectedDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _endDate = pickedDate);
    }
  }

  void _submitForm() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    final user = getIt<SupabaseClient>().auth.currentUser;
    if (user == null) return;

    final datasource = getIt<FinanceRemoteDataSource>();
    
    try {
      if (_isRecurring) {
        // Crear gasto recurrente
        await datasource.addRecurringTransaction(
          user.id,
          {
            'type': 'expense',
            'category': _selectedCategory,
            'amount': _amount,
            'description': _descriptionController.text,
            'startDate': _selectedDate,
            'endDate': _hasEndDate ? _endDate : null,
          },
        );
      } else {
        // Crear gasto eventual
        await datasource.addExpense(
          user.id,
          {
            'category': _selectedCategory,
            'amount': _amount,
            'title': _descriptionController.text,
            'date': _selectedDate,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gasto ${_isRecurring ? 'fijo' : 'eventual'} creado exitosamente'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        context.read<FinanceBloc>().add(LoadDashboard(user.id));
        Navigator.pop(context);
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
            ModalHeader(
              title: 'Nuevo Gasto',
              theme: theme,
              onClose: () => Navigator.pop(context),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle: Evento / Recurrente
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRecurring = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: !_isRecurring ? theme.colorScheme.error : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isRecurring ? theme.colorScheme.error : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Gasto Eventual',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !_isRecurring ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRecurring = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _isRecurring ? theme.colorScheme.error : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRecurring ? theme.colorScheme.error : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Gasto Fijo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecurring ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Amount Input
                  AmountInput(
                    controller: _amountController,
                    theme: theme,
                  ),
                  const SizedBox(height: 40),

                  // Description
                  FormSectionLabel(label: 'Descripción', theme: theme),
                  const SizedBox(height: 12),
                  DescriptionField(
                    controller: _descriptionController,
                    hintText: _isRecurring
                        ? 'ej: Renta, Luz, Agua'
                        : 'ej: Almuerzo, Transporte, Compras',
                  ),
                  const SizedBox(height: 24),

                  // Category Selection
                  FormSectionLabel(label: 'Categoría', theme: theme),
                  const SizedBox(height: 16),
                  CategoryGrid(
                    categories: _expenseCategories,
                    selectedCategory: _selectedCategory,
                    transactionType: 'expense',
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date Section
                  FormSectionLabel(label: 'Fecha', theme: theme),
                  const SizedBox(height: 12),
                  DateSelector(
                    selectedDate: _selectedDate,
                    onTap: _selectDate,
                    theme: theme,
                  ),

                  // Conditional: End Date for Recurring
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fecha fin',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Switch(
                          value: _hasEndDate,
                          onChanged: (value) {
                            setState(() => _hasEndDate = value);
                          },
                        ),
                      ],
                    ),
                    if (_hasEndDate) ...[
                      const SizedBox(height: 12),
                      DateSelector(
                        selectedDate: _endDate ?? _selectedDate,
                        onTap: _selectEndDate,
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Este gasto se repetirá cada mes desde la fecha seleccionada',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Save Button
                  StyledSaveButton(
                    label: _isRecurring ? 'Guardar Gasto Fijo' : 'Guardar Gasto',
                    onPressed: _submitForm,
                    transactionType: 'expense',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
