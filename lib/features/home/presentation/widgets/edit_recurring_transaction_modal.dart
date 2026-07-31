import 'package:flutter/material.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:drip_wallet/features/home/presentation/widgets/reusable_form_components.dart';

class EditRecurringTransactionModal extends StatefulWidget {
  final String recurringId;
  final Map<String, dynamic> recurringData;
  final VoidCallback onSuccess;

  const EditRecurringTransactionModal({
    super.key,
    required this.recurringId,
    required this.recurringData,
    required this.onSuccess,
  });

  @override
  State<EditRecurringTransactionModal> createState() =>
      _EditRecurringTransactionModalState();
}

class _EditRecurringTransactionModalState
    extends State<EditRecurringTransactionModal> {
  late String _transactionType;
  late String _selectedCategory;
  late DateTime _startDate;
  late DateTime? _endDate;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.recurringData['type'] ?? 'expense';
    _selectedCategory = widget.recurringData['category'] ?? 'Otro';
    _startDate = DateTime.parse(widget.recurringData['start_date'] as String);
    _endDate = widget.recurringData['end_date'] != null
        ? DateTime.parse(widget.recurringData['end_date'] as String)
        : null;
    _descriptionController =
        TextEditingController(text: widget.recurringData['description'] ?? '');
    final amount = (widget.recurringData['amount'] as num).toDouble();
    _amountController =
        TextEditingController(text: amount.toStringAsFixed(2));
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final datasource = getIt<FinanceRemoteDataSource>();
      final categories =
          await datasource.getCategories(type: _transactionType);
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final datasource = getIt<FinanceRemoteDataSource>();
      await datasource.updateRecurringTransaction(
        widget.recurringId,
        {
          'category': _selectedCategory,
          'amount': amount,
          'description': _descriptionController.text,
          'startDate': _startDate,
          'endDate': _endDate,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción actualizada')),
        );
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isEndDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? _startDate) : _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2099),
    );

    if (picked != null) {
      setState(() {
        if (isEndDate) {
          _endDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalHeader(
              title:
                  'Editar ${_transactionType == 'income' ? 'Ingreso' : 'Gasto'} Regular',
              theme: theme,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),

            // Descripción
            FormSectionLabel(
              label: 'Descripción',
              theme: theme,
            ),
            const SizedBox(height: 8),
            DescriptionField(
              controller: _descriptionController,
              hintText: _transactionType == 'income'
                  ? 'Ej: Salario mensual'
                  : 'Ej: Renta de apartamento',
            ),
            const SizedBox(height: 16),

            // Monto
            FormSectionLabel(
              label: 'Monto',
              theme: theme,
            ),
            const SizedBox(height: 8),
            AmountInput(
              controller: _amountController,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Categoría
            FormSectionLabel(
              label: 'Categoría',
              theme: theme,
            ),
            const SizedBox(height: 8),
            CategoryGrid(
              categories: _categories,
              selectedCategory: _selectedCategory,
              transactionType: _transactionType,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: 16),

            // Fecha inicio
            FormSectionLabel(
              label: 'Desde',
              theme: theme,
            ),
            const SizedBox(height: 8),
            DateSelector(
              selectedDate: _startDate,
              theme: theme,
              onTap: () => _selectDate(false),
            ),
            const SizedBox(height: 16),

            // Fecha fin (opcional)
            FormSectionLabel(
              label: 'Hasta (opcional)',
              theme: theme,
            ),
            const SizedBox(height: 8),
            DateSelector(
              selectedDate: _endDate ?? _startDate,
              theme: theme,
              onTap: () => _selectDate(true),
            ),
            if (_endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Eliminar fecha fin'),
                  onPressed: () => setState(() => _endDate = null),
                ),
              ),
            const SizedBox(height: 24),

            // Botón guardar
            StyledSaveButton(
              label: 'Guardar cambios',
              onPressed: _isLoading ? () {} : _saveChanges,
              transactionType: _transactionType,
              theme: theme,
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _transactionType == 'income'
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
