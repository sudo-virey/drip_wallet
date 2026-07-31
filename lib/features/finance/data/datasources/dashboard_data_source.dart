import 'package:drip_wallet/features/finance/data/models/dashboard_model.dart';
import 'package:drip_wallet/features/finance/data/datasources/transaction_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DashboardDataSource {
  /// Obtiene los datos del dashboard del mes actual
  Future<DashboardModel> getDashboardData(String profileId);

  /// Obtiene los datos del dashboard para un mes específico
  Future<DashboardModel> getDashboardDataForMonth(
    String profileId,
    DateTime month,
  );
}

class DashboardDataSourceImpl implements DashboardDataSource {
  final SupabaseClient supabaseClient;
  final TransactionDataSource transactionDataSource;

  DashboardDataSourceImpl({
    required this.supabaseClient,
    required this.transactionDataSource,
  });

  Future<String?> _getBudgetFamilyIdForProfile(String profileId) async {
    final membership = await supabaseClient
        .from('budget_family_members')
        .select('family_id')
        .eq('profile_id', profileId)
        .maybeSingle();

    return membership?['family_id'] as String?;
  }

  Future<List<String>> _getBudgetScopeProfileIds(String profileId) async {
    final familyId = await _getBudgetFamilyIdForProfile(profileId);
    if (familyId == null) return [profileId];

    final members = await supabaseClient
        .from('budget_family_members')
        .select('profile_id')
        .eq('family_id', familyId);

    return (members as List).map((member) => member['profile_id'] as String).toList();
  }

  @override
  Future<DashboardModel> getDashboardData(String profileId) async {
    return getDashboardDataForMonth(profileId, DateTime.now());
  }

  @override
  Future<DashboardModel> getDashboardDataForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      final budgetFamilyId = await _getBudgetFamilyIdForProfile(profileId);
      final scopeProfileIds = await _getBudgetScopeProfileIds(profileId);

      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 1);

      // Obtener presupuesto del mes seleccionado
      var budgetQuery = supabaseClient
          .from('monthly_budgets')
          .select('id, budget_limit')
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String());

      budgetQuery = budgetFamilyId != null
          ? budgetQuery.eq('family_id', budgetFamilyId)
          : budgetQuery.eq('profile_id', profileId);

      var budgetResponse = await budgetQuery.maybeSingle();

      // Si no existe presupuesto en este mes, buscar en meses anteriores
      if (budgetResponse == null) {
        var checkMonth = DateTime(month.year, month.month - 1, 1);
        while (checkMonth.year >= DateTime.now().year - 1) {
          final startCheck = DateTime(checkMonth.year, checkMonth.month, 1);
          final endCheck = DateTime(checkMonth.year, checkMonth.month + 1, 1);

          var fallbackQuery = supabaseClient
              .from('monthly_budgets')
              .select('id, budget_limit')
              .gte('month_year', startCheck.toIso8601String())
              .lt('month_year', endCheck.toIso8601String());

          fallbackQuery = budgetFamilyId != null
              ? fallbackQuery.eq('family_id', budgetFamilyId)
              : fallbackQuery.eq('profile_id', profileId);

          budgetResponse = await fallbackQuery.maybeSingle();

          if (budgetResponse != null) break;

          checkMonth = DateTime(checkMonth.year, checkMonth.month - 1, 1);
        }
      }

      final budgetLimit = (budgetResponse?['budget_limit'] as num?)?.toDouble() ?? 0.0;

      // Obtener transacciones del mes
      double totalIncome = 0;
      double totalExpense = 0;

      final expensesResponse = await supabaseClient
          .from('expenses')
          .select('id, amount, type, created_at')
          .inFilter('profile_id', scopeProfileIds)
          .neq('is_deleted', true)
          .gte('created_at', startOfMonth.toIso8601String())
          .lt('created_at', endOfMonth.toIso8601String());

      final expenses = (expensesResponse as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (var expense in expenses) {
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
        if (expense['type'] == 'income') {
          totalIncome += amount;
        } else if (expense['type'] == 'expense') {
          totalExpense += amount;
        }
      }

      // Obtener transacciones recientes para mostrar en UI
      final allTransactions = await transactionDataSource.getTransactionsForMonth(profileId, month);
      final recentTransactions = allTransactions.take(5).toList();

      final balance = budgetLimit - totalExpense;

      return DashboardModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        budgetLimit: budgetLimit,
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      // Silenciar error en producción
      return DashboardModel(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        budgetLimit: 0,
        recentTransactions: [],
      );
    }
  }
}
