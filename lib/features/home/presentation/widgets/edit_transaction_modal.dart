import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late double _amount;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedType;

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
    _amount = widget.transaction.amount;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
    _selectedType = widget.transaction.type;

    _amountController = TextEditingController(text: _amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.title);
    _amountController.addListener(_updateAmount);
  }

  @override
  void dispose() {
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

    final user = supabase.Supabase.instance.client.auth.currentUser;
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Editar Transacción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Monto
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Descripción
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tipo de transacción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'expense' 
                        ? Colors.red 
                        : Colors.grey.shade300,
                    ),
                    onPressed: () => setState(() => _selectedType = 'expense'),
                    child: Text(
                      'Gasto',
                      style: TextStyle(
                        color: _selectedType == 'expense' 
                          ? Colors.white 
                          : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'income' 
                        ? Colors.green 
                        : Colors.grey.shade300,
                    ),
                    onPressed: () => setState(() => _selectedType = 'income'),
                    child: Text(
                      'Ingreso',
                      style: TextStyle(
                        color: _selectedType == 'income' 
                          ? Colors.white 
                          : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Categorías
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category['name']),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category['icon'],
                              color: isSelected ? Colors.white : Colors.black,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Fecha
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(_selectedDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),
            // Botón Guardar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _submitForm,
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

