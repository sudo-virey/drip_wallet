import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/home/presentation/widgets/reusable_form_components.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeTransactionModal extends StatefulWidget {
  const IncomeTransactionModal({super.key});

  @override
  State<IncomeTransactionModal> createState() => _IncomeTransactionModalState();
}

class _IncomeTransactionModalState extends State<IncomeTransactionModal> {
  late DripFormController _formController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  double _amount = 0.0;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate;
  
  bool _isRecurring = false;
  bool _hasEndDate = false;

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

  Future<void> _loadCategories() async {
    try {
      final supabaseClient = getIt<SupabaseClient>();
      
      final incomeResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'income')
          .order('name');
      
      if (mounted) {
        setState(() {
          _incomeCategories = (incomeResponse as List)
              .map((e) => {
                'name': e['name'] as String,
                'icon': e['icon'] as String,
              })
              .toList();
          
          if (_incomeCategories.isNotEmpty) {
            _selectedCategory = _incomeCategories[0]['name'] as String;
          }
        });
      }
    } catch (e) {
      print('ERROR cargando categorías de ingreso: $e');
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
        // Crear ingreso recurrente
        await datasource.addRecurringTransaction(
          user.id,
          {
            'type': 'income',
            'category': _selectedCategory,
            'amount': _amount,
            'description': _descriptionController.text,
            'startDate': _selectedDate,
            'endDate': _hasEndDate ? _endDate : null,
          },
        );
      } else {
        // Crear ingreso eventual
        await datasource.addExpense(
          user.id,
          {
            'category': _selectedCategory,
            'amount': _amount,
            'title': _descriptionController.text,
            'date': _selectedDate,
            'type': 'income',
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ingreso ${_isRecurring ? 'fijo' : 'eventual'} creado exitosamente'),
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
              title: 'Nuevo Ingreso',
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
                              color: !_isRecurring ? theme.colorScheme.secondary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isRecurring ? theme.colorScheme.secondary : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Ingreso Eventual',
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
                              color: _isRecurring ? theme.colorScheme.secondary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRecurring ? theme.colorScheme.secondary : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Ingreso Fijo',
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
                        ? 'ej: Sueldo, Freelance, Bono, Comisión'
                        : 'ej: Bono, Venta, Regalo',
                  ),
                  const SizedBox(height: 24),

                  // Category Selection
                  FormSectionLabel(label: 'Categoría', theme: theme),
                  const SizedBox(height: 16),
                  CategoryGrid(
                    categories: _incomeCategories,
                    selectedCategory: _selectedCategory,
                    transactionType: 'income',
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
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Este ingreso se repetirá cada mes desde la fecha seleccionada',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.secondary,
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
                    label: _isRecurring ? 'Guardar Ingreso Fijo' : 'Guardar Ingreso',
                    onPressed: _submitForm,
                    transactionType: 'income',
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
