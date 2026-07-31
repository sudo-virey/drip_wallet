import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';

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
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transit', 'icon': Icons.directions_car},
    {'name': 'Bills', 'icon': Icons.receipt},
    {'name': 'Shop', 'icon': Icons.shopping_bag},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Fun', 'icon': Icons.sentiment_satisfied},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _formController = DripFormController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController.addListener(_updateAmount);
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
                    'New Expense',
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
                  // Amount Input
                  const SizedBox(height: 20),
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
                              width: 150,
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
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _amount += 1);
                                  },
                                  child: Icon(
                                    Icons.arrow_drop_up,
                                    size: 24,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_amount > 0) _amount -= 1;
                                    });
                                  },
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    size: 24,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
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
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
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
                      label: 'Save Expense',
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

  /// Guardar el gasto y disparar evento del FinanceBloc
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
      'type': 'expense',
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
