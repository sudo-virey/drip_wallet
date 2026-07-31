import 'package:drip_wallet/features/finance/data/models/dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FinanceRemoteDataSource {
  /// Obtiene los datos del dashboard desde Supabase
  Future<DashboardModel> fetchDashboardData(String profileId);

  /// Obtiene los datos del dashboard para un mes específico
  /// Si no hay presupuesto en ese mes, busca el mes anterior con presupuesto
  Future<DashboardModel> fetchDashboardDataForMonth(
    String profileId,
    DateTime month,
  );

  /// Agrega una nueva transacción en Supabase
  Future<TransactionModel> addExpense(
    String profileId,
    Map<String, dynamic> data,
  );

  /// Crea o actualiza el presupuesto mensual (solo límite de gasto)
  Future<Map<String, dynamic>> setMonthlyBudget(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  );

  /// Obtiene el presupuesto mensual
  Future<Map<String, dynamic>?> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  );

  /// Elimina (soft delete) una transacción
  Future<void> deleteTransaction(String transactionId);

  /// Actualiza una transacción existente
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  );

  /// Crea una transacción recurrente (gasto o ingreso fijo)
  Future<Map<String, dynamic>> addRecurringTransaction(
    String profileId,
    Map<String, dynamic> data, // Debe incluir: category, amount, description, type (income/expense), startDate, endDate
  );

  /// Obtiene las transacciones recurrentes activas para un perfil (income + expense)
  Future<List<Map<String, dynamic>>> getRecurringTransactions(String profileId);

  /// Obtiene las transacciones recurrentes aplicables a un mes específico
  Future<List<Map<String, dynamic>>> getRecurringTransactionsForMonth(
    String profileId,
    DateTime month,
  );

  /// Obtiene todas las categorías dinámicamente desde la BD
  /// Filtra por tipo si se especifica (expense, income, o null para todas)
  Future<List<Map<String, dynamic>>> getCategories({String? type});

  /// Elimina una transacción recurrente
  Future<void> deleteRecurringTransaction(String recurringTransactionId);

  /// Actualiza una transacción recurrente
  Future<void> updateRecurringTransaction(
    String recurringTransactionId,
    Map<String, dynamic> data, // Debe incluir: category, amount, description, startDate, endDate
  );

  /// [DEPRECATED] Crea un gasto recurrente - usa addRecurringTransaction en su lugar
  Future<Map<String, dynamic>> addRecurringExpense(
    String profileId,
    Map<String, dynamic> data,
  );

  /// [DEPRECATED] Obtiene los gastos recurrentes - usa getRecurringTransactions en su lugar
  Future<List<Map<String, dynamic>>> getRecurringExpenses(String profileId);

  /// [DEPRECATED] Elimina un gasto recurrente - usa deleteRecurringTransaction en su lugar
  Future<void> deleteRecurringExpense(String recurringExpenseId);

  /// [DEPRECATED] Obtiene los gastos recurrentes para un mes - usa getRecurringTransactionsForMonth en su lugar
  Future<List<Map<String, dynamic>>> getRecurringExpensesForMonth(
    String profileId,
    DateTime month,
  );
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  // Caché de categorías: Map<UUID, nombre>
  Map<String, String> _categoryIdToName = {};
  // Caché inverso: Map<nombre, UUID>
  Map<String, String> _categoryNameToId = {};
  // Caché de iconos: Map<UUID, nombre_icono>
  Map<String, String> _categoryIdToIcon = {};
  // Caché de tipo: Map<UUID, tipo>
  Map<String, String> _categoryIdToType = {};
  bool _categoriesLoaded = false;

  FinanceRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<DashboardModel> fetchDashboardData(String profileId) async {
    try {
      // Cargar categorías desde BD si no están cacheadas
      await _loadCategories();
      
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      // 1. Obtener presupuesto del mes actual
      final budgetResponse = await supabaseClient
          .from('monthly_budgets')
          .select('id, budget_limit')
          .eq('profile_id', profileId)
          .gte('month_year', currentMonth.toIso8601String())
          .lt('month_year', nextMonth.toIso8601String())
          .maybeSingle();

      final budgetLimit = (budgetResponse?['budget_limit'] as num?)?.toDouble() ?? 0.0;

      // 2. Obtener TODAS las transacciones del mes actual (por fecha, no por budget_id)
      // Esto asegura que el balance considera todos los movimientos del mes
      double totalIncome = 0;
      double totalExpense = 0;
      List<Map<String, dynamic>> allMonthTransactions = [];

      final allExpensesResponse = await supabaseClient
          .from('expenses')
          .select('id, amount, description, type, created_at, category_id, profile_id, is_deleted')
          .eq('profile_id', profileId)
          .neq('is_deleted', true)
          .gte('created_at', currentMonth.toIso8601String())
          .lt('created_at', nextMonth.toIso8601String())
          .order('created_at', ascending: false);

      allMonthTransactions = (allExpensesResponse as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Calcular totales de ingresos y gastos del mes completo
      for (var expense in allMonthTransactions) {
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
        if (expense['type'] == 'income') {
          totalIncome += amount;
        } else if (expense['type'] == 'expense') {
          totalExpense += amount;
        }
      }

      // Agregar gastos recurrentes (fijos) del mes actual
      final recurringExpensesForMonth = await getRecurringExpensesForMonth(profileId, DateTime.now());
      for (var recurring in recurringExpensesForMonth) {
        final amount = (recurring['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpense += amount;
        print('DEBUG: Agregando gasto recurrente "${recurring['description']}" al total: $amount');
      }

      final balance = budgetLimit - totalExpense;

      // 3. Obtener solo transacciones del último día con movimientos para mostrar en UI
      List<TransactionModel> recentTransactions = [];
      if (allMonthTransactions.isNotEmpty) {
        // Obtener la fecha más reciente
        final newestDate = DateTime.parse(allMonthTransactions.first['created_at'] as String);
        
        // Filtrar solo transacciones de ese día (comparar solo año, mes, día)
        final startOfDay = DateTime(newestDate.year, newestDate.month, newestDate.day);
        final endOfDay = DateTime(newestDate.year, newestDate.month, newestDate.day + 1);
        
        recentTransactions = allMonthTransactions
            .where((e) {
              final txDate = DateTime.parse(e['created_at'] as String);
              return txDate.isAfter(startOfDay) && txDate.isBefore(endOfDay);
            })
            .map((e) => TransactionModel(
              id: e['id'] as String? ?? '',
              title: e['description'] as String? ?? 'Transaction',
              category: _getCategoryName(e['category_id'] as String?),
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              date: e['created_at'] != null ? DateTime.parse(e['created_at'] as String) : DateTime.now(),
              type: e['type'] as String? ?? 'expense',
              description: e['description'] as String? ?? '',
              icon: _getCategoryIcon(e['category_id'] as String?),
            ))
            .toList();
      }

      return DashboardModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        budgetLimit: budgetLimit,
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      // Retornar dashboard vacío en caso de error
      return DashboardModel(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        budgetLimit: 0,
        recentTransactions: [],
      );
    }
  }

  @override
  Future<DashboardModel> fetchDashboardDataForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      // Cargar categorías desde BD si no están cacheadas
      await _loadCategories();
      
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 1);

      // 1. Buscar presupuesto para el mes seleccionado
      var budgetResponse = await supabaseClient
          .from('monthly_budgets')
          .select('id, budget_limit')
          .eq('profile_id', profileId)
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String())
          .maybeSingle();

      // 2. Si no existe presupuesto en este mes, buscar en meses anteriores
      if (budgetResponse == null) {
        var checkMonth = DateTime(month.year, month.month - 1, 1);
        while (checkMonth.year >= DateTime.now().year - 1) {
          // Buscar máximo 1 año hacia atrás
          final startCheck = DateTime(checkMonth.year, checkMonth.month, 1);
          final endCheck = DateTime(checkMonth.year, checkMonth.month + 1, 1);

          budgetResponse = await supabaseClient
              .from('monthly_budgets')
              .select('id, budget_limit')
              .eq('profile_id', profileId)
              .gte('month_year', startCheck.toIso8601String())
              .lt('month_year', endCheck.toIso8601String())
              .maybeSingle();

          if (budgetResponse != null) break;

          checkMonth = DateTime(checkMonth.year, checkMonth.month - 1, 1);
        }
      }

      final budgetLimit = (budgetResponse?['budget_limit'] as num?)?.toDouble() ?? 0.0;

      // 3. Obtener transacciones DEL MES SELECCIONADO (por fecha, no por budget_id)
      double totalIncome = 0;
      double totalExpense = 0;
      List<Map<String, dynamic>> expenses = [];

      final expensesResponse = await supabaseClient
          .from('expenses')
          .select('id, amount, description, type, created_at, category_id, profile_id, is_deleted')
          .eq('profile_id', profileId)
          .neq('is_deleted', true)
          .gte('created_at', startOfMonth.toIso8601String())
          .lt('created_at', endOfMonth.toIso8601String())
          .order('created_at', ascending: false);

      expenses = (expensesResponse as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Calcular totales
      for (var expense in expenses) {
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
        if (expense['type'] == 'income') {
          totalIncome += amount;
        } else if (expense['type'] == 'expense') {
          totalExpense += amount;
        }
      }

      // Agregar gastos recurrentes (fijos) del mes seleccionado
      final recurringExpensesForMonth = await getRecurringExpensesForMonth(profileId, month);
      for (var recurring in recurringExpensesForMonth) {
        final amount = (recurring['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpense += amount;
        print('DEBUG: Agregando gasto recurrente "${recurring['description']}" al total: $amount');
      }

      final balance = budgetLimit - totalExpense;

      // Obtener solo transacciones del último día con movimientos en este mes
      List<TransactionModel> recentTransactions = [];
      if (expenses.isNotEmpty) {
        // Obtener la fecha más reciente
        final newestDate = DateTime.parse(expenses.first['created_at'] as String);
        
        // Filtrar solo transacciones de ese día (comparar solo año, mes, día)
        final startOfDay = DateTime(newestDate.year, newestDate.month, newestDate.day);
        final endOfDay = DateTime(newestDate.year, newestDate.month, newestDate.day + 1);
        
        recentTransactions = expenses
            .where((e) {
              final txDate = DateTime.parse(e['created_at'] as String);
              return txDate.isAfter(startOfDay) && txDate.isBefore(endOfDay);
            })
            .map((e) => TransactionModel(
              id: e['id'] as String? ?? '',
              title: e['description'] as String? ?? 'Transaction',
              category: _getCategoryName(e['category_id'] as String?),
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              date: e['created_at'] != null ? DateTime.parse(e['created_at'] as String) : DateTime.now(),
              type: e['type'] as String? ?? 'expense',
              description: e['description'] as String? ?? '',
              icon: _getCategoryIcon(e['category_id'] as String?),
            ))
            .toList();
      }

      return DashboardModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        budgetLimit: budgetLimit,
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      // Retornar dashboard vacío en caso de error
      return DashboardModel(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        budgetLimit: 0,
        recentTransactions: [],
      );
    }
  }

  @override
  Future<TransactionModel> addExpense(String profileId, Map<String, dynamic> data) async {
    try {
      // Cargar categorías desde BD si no están cacheadas
      await _loadCategories();
      
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // 1. Obtener o crear presupuesto del mes actual
      var budgetResponse = await supabaseClient
          .from('monthly_budgets')
          .select('id')
          .eq('profile_id', profileId)
          .gte('month_year', currentMonth.toIso8601String())
          .lt('month_year', DateTime(now.year, now.month + 1, 1).toIso8601String())
          .maybeSingle();

      String budgetId = budgetResponse?['id'] as String? ?? '';

      // Si no existe presupuesto, crearlo
      if (budgetId.isEmpty) {
        final newBudget = await supabaseClient
            .from('monthly_budgets')
            .insert({
              'month_year': currentMonth.toIso8601String(),
              'budget_limit': data['budget_limit'] ?? 5000.0,
              'profile_id': profileId,
            })
            .select('id')
            .single();
        budgetId = newBudget['id'] as String;
      }

      // 2. Insertar en la tabla 'expenses'
      final response = await supabaseClient
          .from('expenses')
          .insert({
            'profile_id': profileId,
            'budget_id': budgetId,
            'amount': data['amount'],
            'description': data['title'] ?? 'Unnamed',
            'type': data['type'] ?? 'expense',
            'category_id': _getCategoryId(data['category'] ?? 'Otro'),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final transaction = TransactionModel(
        id: response['id'] as String? ?? '',
        title: response['description'] as String? ?? 'Expense',
        category: _getCategoryName(response['category_id'] as String?),
        amount: (response['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.parse(response['created_at'] as String),
        type: response['type'] as String? ?? 'expense',
        description: response['description'] as String? ?? '',
        icon: _getCategoryIcon(response['category_id'] as String?),
      );

      return transaction;
    } catch (e) {
      throw Exception('Error al guardar transacción: $e');
    }
  }

  /// Mapea categoría a su UUID correspondiente
  String _getCategoryId(String categoryName) {
    // Si no tenemos las categorías cacheadas, retornar valor por defecto
    if (!_categoriesLoaded) {
      return _categoryNameToId[categoryName] ?? '550e8400-e29b-41d4-a716-446655440007';
    }
    return _categoryNameToId[categoryName] ?? '550e8400-e29b-41d4-a716-446655440007';
  }

  /// Mapea UUID de categoría a nombre desde el caché
  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Otro';
    // Si no tenemos las categorías cacheadas, retornar valor por defecto
    if (!_categoriesLoaded) {
      return _categoryIdToName[categoryId] ?? 'Otro';
    }
    return _categoryIdToName[categoryId] ?? 'Otro';
  }

  /// Carga las categorías desde la BD y las cachea
  Future<void> _loadCategories() async {
    if (_categoriesLoaded) return;
    
    try {
      final response = await supabaseClient
          .from('categories')
          .select('id, name, icon, type');
      
      _categoryIdToName.clear();
      _categoryNameToId.clear();
      _categoryIdToIcon.clear();
      _categoryIdToType.clear();
      
      print('\n=== DEBUG: CARGANDO CATEGORÍAS DE LA BD ===');
      for (var category in response as List) {
        final id = category['id'] as String;
        final name = category['name'] as String;
        final icon = category['icon'] as String?;
        final type = category['type'] as String?;
        _categoryIdToName[id] = name;
        _categoryNameToId[name] = id;
        if (icon != null) {
          _categoryIdToIcon[id] = icon;
          print('✓ Categoría: "$name" | Icono en BD: "$icon" | Tipo: "$type"');
        } else {
          print('✗ Categoría: "$name" | ICONO NULL | Tipo: "$type"');
        }
        if (type != null) {
          _categoryIdToType[id] = type;
        }
      }
      print('Total categorías: ${_categoryIdToName.length}\n');
      
      _categoriesLoaded = true;
    } catch (e) {
      print('Error cargando categorías: $e');
      _categoriesLoaded = false;
    }
  }

  /// Obtiene el nombre del icono para una categoría
  String? _getCategoryIcon(String? categoryId) {
    if (categoryId == null) {
      print('DEBUG _getCategoryIcon: categoryId es NULL → devolviendo null');
      return null;
    }
    final icon = _categoryIdToIcon[categoryId];
    print('DEBUG _getCategoryIcon: categoryId="$categoryId" → icono="$icon"');
    return icon;
  }

  /// Obtiene todas las categorías dinámicamente desde la BD
  /// Filtra por tipo si se especifica (expense, income, o null para todas)
  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    await _loadCategories();
    
    try {
      var query = supabaseClient.from('categories').select('id, name, icon, type');
      
      if (type != null) {
        query = query.eq('type', type);
      }
      
      final response = await query.order('name');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> setMonthlyBudget(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  ) async {
    try {
      final startOfMonth = DateTime(monthYear.year, monthYear.month, 1);
      final endOfMonth = DateTime(monthYear.year, monthYear.month + 1, 1);

      // Obtener presupuesto existente
      var existing = await supabaseClient
          .from('monthly_budgets')
          .select('id')
          .eq('profile_id', profileId)
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String())
          .maybeSingle();

      if (existing != null) {
        // Actualizar usando UPSERT
        final budgetId = existing['id'] as String;

        final upsertResult = await supabaseClient
            .from('monthly_budgets')
            .upsert({
              'id': budgetId,
              'profile_id': profileId,
              'month_year': startOfMonth.toIso8601String(),
              'budget_limit': budgetLimit,
            })
            .select()
            .single();

        return upsertResult;
      } else {
        // Crear nuevo
        final created = await supabaseClient
            .from('monthly_budgets')
            .insert({
              'profile_id': profileId,
              'month_year': startOfMonth.toIso8601String(),
              'budget_limit': budgetLimit,
            })
            .select()
            .single();
        return created;
      }
    } catch (e) {
      throw Exception('Error al guardar presupuesto: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  ) async {
    try {
      final startOfMonth = DateTime(monthYear.year, monthYear.month, 1);
      final endOfMonth = DateTime(monthYear.year, monthYear.month + 1, 1);

      final budget = await supabaseClient
          .from('monthly_budgets')
          .select('id, monthly_income, budget_limit, month_year')
          .eq('profile_id', profileId)
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String())
          .maybeSingle();

      return budget;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await supabaseClient
          .from('expenses')
          .update({'is_deleted': true})
          .eq('id', transactionId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  @override
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Cargar categorías desde BD si no están cacheadas
      await _loadCategories();
      
      final updateData = {
        'description': data['title'] ?? data['description'],
        'amount': data['amount'],
        'type': data['type'],
        'category_id': _getCategoryId(data['category'] ?? 'Otro'),
        'created_at': data['date'] ?? DateTime.now().toIso8601String(),
      };

      await supabaseClient
          .from('expenses')
          .update(updateData)
          .eq('id', transactionId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Error al actualizar transacción: $e');
    }
  }

  /// Crear un gasto recurrente (DEPRECATED - usa addRecurringTransaction)
  @override
  Future<Map<String, dynamic>> addRecurringExpense(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    data['type'] = 'expense';
    return addRecurringTransaction(profileId, data);
  }

  /// Obtener gastos recurrentes activos (DEPRECATED - usa getRecurringTransactions)
  @override
  Future<List<Map<String, dynamic>>> getRecurringExpenses(String profileId) async {
    final allRecurring = await getRecurringTransactions(profileId);
    return allRecurring.where((r) => r['type'] == 'expense').toList();
  }

  /// Eliminar un gasto recurrente (DEPRECATED - usa deleteRecurringTransaction)
  @override
  Future<void> deleteRecurringExpense(String recurringExpenseId) async {
    return deleteRecurringTransaction(recurringExpenseId);
  }

  /// Obtener gastos recurrentes aplicables a un mes específico (DEPRECATED - usa getRecurringTransactionsForMonth)
  @override
  Future<List<Map<String, dynamic>>> getRecurringExpensesForMonth(
    String profileId,
    DateTime month,
  ) async {
    final allRecurring = await getRecurringTransactionsForMonth(profileId, month);
    return allRecurring.where((r) => r['type'] == 'expense').toList();
  }

  /// Crear transacción recurrente genérica (income o expense)
  @override
  Future<Map<String, dynamic>> addRecurringTransaction(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _loadCategories();

      final response = await supabaseClient
          .from('recurring_transactions')
          .insert({
            'profile_id': profileId,
            'type': data['type'] ?? 'expense',
            'category_id': _getCategoryId(data['category'] ?? 'Otro'),
            'description': data['title'] ?? data['description'] ?? 'Transacción Recurrente',
            'amount': data['amount'],
            'start_date': (data['startDate'] as DateTime?)?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
            'end_date': data['endDate'] != null ? (data['endDate'] as DateTime).toIso8601String().split('T')[0] : null,
          })
          .select()
          .single();

      print('DEBUG: Transacción recurrente creada: ${response['description']} (${response['type']})');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error creando transacción recurrente: $e');
      throw Exception('Error al crear transacción recurrente: $e');
    }
  }

  /// Obtener transacciones recurrentes activas (income + expense)
  @override
  Future<List<Map<String, dynamic>>> getRecurringTransactions(String profileId) async {
    try {
      await _loadCategories();

      final response = await supabaseClient
          .from('recurring_transactions')
          .select('id, description, amount, category_id, type, start_date, end_date')
          .eq('profile_id', profileId)
          .gte('start_date', DateTime.now().toIso8601String().split('T')[0])
          .order('description');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo transacciones recurrentes: $e');
      return [];
    }
  }

  /// Eliminar transacción recurrente
  @override
  Future<void> deleteRecurringTransaction(String recurringTransactionId) async {
    try {
      await supabaseClient
          .from('recurring_transactions')
          .delete()
          .eq('id', recurringTransactionId);
      print('DEBUG: Transacción recurrente eliminada: $recurringTransactionId');
    } catch (e) {
      throw Exception('Error al eliminar transacción recurrente: $e');
    }
  }

  @override
  Future<void> updateRecurringTransaction(
    String recurringTransactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _loadCategories();

      final updateData = {
        'description': data['description'],
        'amount': data['amount'],
        'category_id': _getCategoryId(data['category'] ?? 'Otro'),
        'start_date': (data['startDate'] as DateTime).toIso8601String().split('T')[0],
        'end_date': data['endDate'] != null
            ? (data['endDate'] as DateTime).toIso8601String().split('T')[0]
            : null,
      };

      await supabaseClient
          .from('recurring_transactions')
          .update(updateData)
          .eq('id', recurringTransactionId);

      print('DEBUG: Transacción recurrente actualizada: $recurringTransactionId');
    } catch (e) {
      throw Exception('Error al actualizar transacción recurrente: $e');
    }
  }

  /// Obtener transacciones recurrentes aplicables a un mes específico
  @override
  Future<List<Map<String, dynamic>>> getRecurringTransactionsForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      await _loadCategories();

      final startOfMonth = DateTime(month.year, month.month, 1).toIso8601String().split('T')[0];
      final endOfMonth = DateTime(month.year, month.month + 1, 1).toIso8601String().split('T')[0];

      final response = await supabaseClient
          .from('recurring_transactions')
          .select('id, description, amount, category_id, type, start_date, end_date')
          .eq('profile_id', profileId)
          .lte('start_date', endOfMonth)
          .or('end_date.is.null,end_date.gte.$startOfMonth')
          .order('description');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo transacciones recurrentes del mes: $e');
      return [];
    }
  }
}

