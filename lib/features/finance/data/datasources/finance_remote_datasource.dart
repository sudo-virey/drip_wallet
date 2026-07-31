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
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  FinanceRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<DashboardModel> fetchDashboardData(String profileId) async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // 1. Obtener presupuesto del mes actual
      final budgetResponse = await supabaseClient
          .from('monthly_budgets')
          .select('id, budget_limit')
          .eq('profile_id', profileId)
          .gte('month_year', currentMonth.toIso8601String())
          .lt('month_year', DateTime(now.year, now.month + 1, 1).toIso8601String())
          .maybeSingle();

      final budgetLimit = (budgetResponse?['budget_limit'] as num?)?.toDouble() ?? 0.0;
      final budgetId = budgetResponse?['id'] as String?;

      // 2. Si existe presupuesto, obtener transacciones; si no, retornar dashboard vacío
      double totalIncome = 0;
      double totalExpense = 0;
      List<Map<String, dynamic>> expenses = [];

      if (budgetId != null) {
        final expensesResponse = await supabaseClient
            .from('expenses')
            .select('id, amount, description, type, created_at, category_id, profile_id, is_deleted')
            .eq('budget_id', budgetId)
            .neq('is_deleted', true)
            .order('created_at', ascending: false);

        expenses = (expensesResponse as List?)?.cast<Map<String, dynamic>>() ?? [];

        // Calcular totales de ingresos y gastos (solo transacciones no eliminadas)
        for (var expense in expenses) {
          final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
          if (expense['type'] == 'income') {
            totalIncome += amount;
          } else if (expense['type'] == 'expense') {
            totalExpense += amount;
          }
        }
      }

      final balance = budgetLimit - totalExpense;

      return DashboardModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        budgetLimit: budgetLimit,
        recentTransactions: expenses
            .map((e) => TransactionModel(
              id: e['id'] as String? ?? '',
              title: e['description'] as String? ?? 'Transaction',
              category: _getCategoryName(e['category_id'] as String?),
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              date: e['created_at'] != null ? DateTime.parse(e['created_at'] as String) : DateTime.now(),
              type: e['type'] as String? ?? 'expense',
              description: e['description'] as String? ?? '',
            ))
            .toList(),
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

      final balance = budgetLimit - totalExpense;

      return DashboardModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        budgetLimit: budgetLimit,
        recentTransactions: expenses
            .map((e) => TransactionModel(
              id: e['id'] as String? ?? '',
              title: e['description'] as String? ?? 'Transaction',
              category: _getCategoryName(e['category_id'] as String?),
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              date: e['created_at'] != null ? DateTime.parse(e['created_at'] as String) : DateTime.now(),
              type: e['type'] as String? ?? 'expense',
              description: e['description'] as String? ?? '',
            ))
            .toList(),
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
            'category_id': _getCategoryId(data['category'] ?? 'Other'),
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
      );

      return transaction;
    } catch (e) {
      throw Exception('Error al guardar transacción: $e');
    }
  }

  /// Mapea categoría a su UUID correspondiente
  String _getCategoryId(String categoryName) {
    final categoryMap = {
      'Food': '550e8400-e29b-41d4-a716-446655440001',
      'Transit': '550e8400-e29b-41d4-a716-446655440002',
      'Bills': '550e8400-e29b-41d4-a716-446655440003',
      'Shop': '550e8400-e29b-41d4-a716-446655440004',
      'Home': '550e8400-e29b-41d4-a716-446655440005',
      'Fun': '550e8400-e29b-41d4-a716-446655440006',
      'Other': '550e8400-e29b-41d4-a716-446655440007',
    };
    return categoryMap[categoryName] ?? categoryMap['Other']!;
  }

  /// Mapea UUID de categoría a nombre en español
  String _getCategoryName(String? categoryId) {
    final categoryMap = {
      '550e8400-e29b-41d4-a716-446655440001': 'Comida',
      '550e8400-e29b-41d4-a716-446655440002': 'Transporte',
      '550e8400-e29b-41d4-a716-446655440003': 'Facturas',
      '550e8400-e29b-41d4-a716-446655440004': 'Compras',
      '550e8400-e29b-41d4-a716-446655440005': 'Hogar',
      '550e8400-e29b-41d4-a716-446655440006': 'Diversión',
      '550e8400-e29b-41d4-a716-446655440007': 'Otro',
    };
    return categoryMap[categoryId] ?? 'Otro';
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
      final updateData = {
        'description': data['title'] ?? data['description'],
        'amount': data['amount'],
        'type': data['type'],
        'category_id': _getCategoryId(data['category'] ?? 'Other'),
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
}
