import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
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
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late double _amount;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedType;

  // Categorías cargadas dinámicamente desde la BD
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
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
      print('DEBUG: Iniciando carga de categorías (edit modal)...');
      
      // Primero: Ver TODOS los registros sin filtro
      final allCategories = await supabaseClient
          .from('categories')
          .select('*');
      print('DEBUG: Total de categorías sin filtro: ${(allCategories as List).length}');
      print('DEBUG: Datos completos: $allCategories');
      
      // Cargar gastos
      final expenseResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'expense')
          .order('name');
      print('DEBUG: Gastos cargados: ${(expenseResponse as List).length} items');
      print('DEBUG: Datos de gastos: $expenseResponse');
      
      // Cargar ingresos
      final incomeResponse = await supabaseClient
          .from('categories')
          .select('id, name, icon, type')
          .eq('type', 'income')
          .order('name');
      print('DEBUG: Ingresos cargados: ${(incomeResponse as List).length} items');
      print('DEBUG: Datos de ingresos: $incomeResponse');
      
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
          
          // Validar que la categoría cargada exista en la lista, si no, usar la primera
          final validCategories = _selectedType == 'income' ? _incomeCategories : _expenseCategories;
          final validCategoryNames = validCategories.map((c) => c['name'] as String).toList();
          
          print('DEBUG: Validando categoría "${_selectedCategory}" en lista: $validCategoryNames');
          
          if (!validCategoryNames.contains(_selectedCategory) && validCategories.isNotEmpty) {
            print('DEBUG: Categoría no encontrada, usando primera: ${validCategories[0]['name']}');
            _selectedCategory = validCategories[0]['name'] as String;
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
                    onPressed: () {
                      setState(() {
                        _selectedType = 'expense';
                        if (_expenseCategories.isNotEmpty) {
                          _selectedCategory = _expenseCategories[0]['name'] as String;
                        }
                      });
                    },
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
                    onPressed: () {
                      setState(() {
                        _selectedType = 'income';
                        if (_incomeCategories.isNotEmpty) {
                          _selectedCategory = _incomeCategories[0]['name'] as String;
                        }
                      });
                    },
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

