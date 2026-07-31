import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/reusable_form_components.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditExpenseTransactionModal extends StatefulWidget {
  final TransactionEntity transaction;

  const EditExpenseTransactionModal({
    super.key,
    required this.transaction,
  });

  @override
  State<EditExpenseTransactionModal> createState() =>
      _EditExpenseTransactionModalState();
}

class _EditExpenseTransactionModalState
    extends State<EditExpenseTransactionModal> {
  late DripFormController _formController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late double _amount;
  late String _selectedCategory;
  late DateTime _selectedDate;

  List<Map<String, dynamic>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _formController = DripFormController();
    _amount = widget.transaction.amount;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;

    _amountController =
        TextEditingController(text: _amount.toStringAsFixed(2));
    _descriptionController =
        TextEditingController(text: widget.transaction.title);
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

          // Validar que la categoría seleccionada existe en la lista
          final validCategoryNames =
              _expenseCategories.map((c) => c['name'] as String).toList();

          if (!validCategoryNames.contains(_selectedCategory) &&
              _expenseCategories.isNotEmpty) {
            _selectedCategory = _expenseCategories[0]['name'] as String;
          }
        });
      }
    } catch (e) {
      print('ERROR cargando categorías de gasto: $e');
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
      'type': 'expense',
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
              title: 'Editar Gasto',
              theme: theme,
              onClose: () => Navigator.pop(context),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    hintText: 'ej: Almuerzo, Transporte, Compras',
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
                  const SizedBox(height: 24),

                  // Save Button
                  StyledSaveButton(
                    label: 'Guardar Cambios',
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
