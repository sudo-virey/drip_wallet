import 'package:drip_wallet/features/finance/data/models/transaction_model.dart';
import 'package:drip_wallet/features/finance/data/datasources/category_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TransactionDataSource {
  /// Agrega una nueva transacción
  Future<TransactionModel> addTransaction(
    String profileId,
    Map<String, dynamic> data,
  );

  /// Obtiene todas las transacciones de un mes
  Future<List<TransactionModel>> getTransactionsForMonth(
    String profileId,
    DateTime month,
  );

  /// Elimina (soft delete) una transacción
  Future<void> deleteTransaction(String transactionId);

  /// Actualiza una transacción existente
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  );
}

class TransactionDataSourceImpl implements TransactionDataSource {
  final SupabaseClient supabaseClient;
  final CategoryDataSource categoryDataSource;

  TransactionDataSourceImpl({
    required this.supabaseClient,
    required this.categoryDataSource,
  });

  Future<List<String>> _getBudgetScopeProfileIds(String profileId) async {
    final membership = await supabaseClient
        .from('budget_family_members')
        .select('family_id')
        .eq('profile_id', profileId)
        .maybeSingle();

    final familyId = membership?['family_id'] as String?;
    if (familyId == null) return [profileId];

    final members = await supabaseClient
        .from('budget_family_members')
        .select('profile_id')
        .eq('family_id', familyId);

    return (members as List).map((member) => member['profile_id'] as String).toList();
  }

  Future<String?> _getBudgetFamilyIdForProfile(String profileId) async {
    final membership = await supabaseClient
        .from('budget_family_members')
        .select('family_id')
        .eq('profile_id', profileId)
        .maybeSingle();

    return membership?['family_id'] as String?;
  }

  @override
  Future<TransactionModel> addTransaction(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    try {
      await categoryDataSource.loadCategories();

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final budgetFamilyId = await _getBudgetFamilyIdForProfile(profileId);

      // Obtener o crear presupuesto del mes actual
      var budgetQuery = supabaseClient
          .from('monthly_budgets')
          .select('id')
          .gte('month_year', currentMonth.toIso8601String())
          .lt('month_year', DateTime(now.year, now.month + 1, 1).toIso8601String());

      budgetQuery = budgetFamilyId != null
          ? budgetQuery.eq('family_id', budgetFamilyId)
          : budgetQuery.eq('profile_id', profileId);

      var budgetResponse = await budgetQuery.maybeSingle();

      String budgetId = budgetResponse?['id'] as String? ?? '';

      // Si no existe presupuesto, crearlo
      if (budgetId.isEmpty) {
        final newBudget = await supabaseClient
            .from('monthly_budgets')
            .insert({
              'month_year': currentMonth.toIso8601String(),
              'budget_limit': data['budget_limit'] ?? 5000.0,
              'profile_id': profileId,
              if (budgetFamilyId != null) 'family_id': budgetFamilyId,
            })
            .select('id')
            .single();
        budgetId = newBudget['id'] as String;
      }

      // Insertar transacción
      final response = await supabaseClient
          .from('expenses')
          .insert({
            'profile_id': profileId,
            'budget_id': budgetId,
            'amount': data['amount'],
            'description': data['title'] ?? 'Unnamed',
            'type': data['type'] ?? 'expense',
            'category_id': categoryDataSource.getCategoryId(data['category'] ?? 'Otro'),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return _mapToTransactionModel(response);
    } catch (e) {
      throw Exception('Error al guardar transacción: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      await categoryDataSource.loadCategories();

      final scopeProfileIds = await _getBudgetScopeProfileIds(profileId);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 1);

      final expensesResponse = await supabaseClient
          .from('expenses')
          .select('id, amount, description, type, created_at, category_id, profile_id, is_deleted')
          .inFilter('profile_id', scopeProfileIds)
          .neq('is_deleted', true)
          .gte('created_at', startOfMonth.toIso8601String())
          .lt('created_at', endOfMonth.toIso8601String())
          .order('created_at', ascending: false);

      final expenses = (expensesResponse as List?)?.cast<Map<String, dynamic>>() ?? [];
      return expenses.map(_mapToTransactionModel).toList();
    } catch (e) {
      print('ERROR fetching transactions for month: $e');
      return [];
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
      await categoryDataSource.loadCategories();

      final updateData = {
        'description': data['title'] ?? data['description'],
        'amount': data['amount'],
        'type': data['type'],
        'category_id': categoryDataSource.getCategoryId(data['category'] ?? 'Otro'),
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

  TransactionModel _mapToTransactionModel(Map<String, dynamic> response) {
    return TransactionModel(
      id: response['id'] as String? ?? '',
      title: response['description'] as String? ?? 'Transaction',
      category: categoryDataSource.getCategoryName(response['category_id'] as String?),
      amount: (response['amount'] as num?)?.toDouble() ?? 0.0,
      date: response['created_at'] != null ? DateTime.parse(response['created_at'] as String) : DateTime.now(),
      type: response['type'] as String? ?? 'expense',
      description: response['description'] as String? ?? '',
      icon: categoryDataSource.getCategoryIcon(response['category_id'] as String?),
    );
  }
}
