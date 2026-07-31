import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/reusable_form_components.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditTransactionModal extends StatefulWidget {
  final TransactionEntity transaction;

  const EditTransactionModal({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends State<EditTransactionModal> {
  late DripFormController _formController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late double _amount;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedType;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    _formController = DripFormController();
    _amount = widget.transaction.amount;
    _selectedDate = widget.transaction.date;
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;

    _amountController = TextEditingController(text: _amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.title);
    _amountController.addListener(_updateAmount);
    
    _loadCategories();
  }

  /// Cargar categorías dinámicamente desde la BD
  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      
      final expenseResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'expense')
          .order('name');
      
      final incomeResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'income')
          .order('name');
      
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
          
          final validCategories = _selectedType == 'income' ? _incomeCategories : _expenseCategories;
          final validCategoryNames = validCategories.map((c) => c['name'] as String).toList();
          
          if (!validCategoryNames.contains(_selectedCategory) && validCategories.isNotEmpty) {
            _selectedCategory = validCategories[0]['name'] as String;
          }
        });
      }
    } catch (e) {
      print('ERROR cargando categorías: $e');
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
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _submitForm() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    final user = getIt<SupabaseClient>().auth.currentUser;
    if (user == null) return;

    final updatedData = {
      'title': _descriptionController.text,
      'category': _selectedCategory,
      'amount': _amount,
      'type': _selectedType,
      'date': _selectedDate.toIso8601String(),
      'description': _descriptionController.text,
    };

    context.read<FinanceBloc>().add(
      UpdateTransaction(
        profileId: user.id,
        transactionId: widget.transaction.id,
        transactionData: updatedData,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = _selectedType == 'income';
    final titleText = 'Editar ${isIncome ? 'Ingreso' : 'Gasto'}';
    final categories = isIncome ? _incomeCategories : _expenseCategories;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
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
              title: titleText,
              theme: theme,
              onClose: () => Navigator.pop(context),
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
                      TransactionTypeButton(
                        type: 'expense',
                        selectedType: _selectedType,
                        label: 'Gasto',
                        onTap: () {
                          setState(() {
                            _selectedType = 'expense';
                            if (_expenseCategories.isNotEmpty) {
                              _selectedCategory = _expenseCategories[0]['name'] as String;
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      TransactionTypeButton(
                        type: 'income',
                        selectedType: _selectedType,
                        label: 'Ingreso',
                        onTap: () {
                          setState(() {
                            _selectedType = 'income';
                            if (_incomeCategories.isNotEmpty) {
                              _selectedCategory = _incomeCategories[0]['name'] as String;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                    hintText: 'Describe la transacción',
                  ),
                  const SizedBox(height: 24),

                  // Category Selection
                  FormSectionLabel(label: 'Categoría', theme: theme),
                  const SizedBox(height: 16),
                  CategoryGrid(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    transactionType: _selectedType,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date Selection
                  FormSectionLabel(label: 'Fecha', theme: theme),
                  const SizedBox(height: 12),
                  DateSelector(
                    selectedDate: _selectedDate,
                    onTap: _selectDate,
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  StyledSaveButton(
                    label: 'Guardar Cambios',
                    onPressed: _submitForm,
                    transactionType: _selectedType,
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
