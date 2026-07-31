import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BudgetDataSource {
  /// Obtiene el presupuesto mensual
  Future<Map<String, dynamic>?> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  );

  /// Crea o actualiza el presupuesto mensual
  Future<Map<String, dynamic>> setMonthlyBudget(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  );

  /// Obtiene el ID de la familia de presupuesto del perfil
  Future<String?> getBudgetFamilyIdForProfile(String profileId);
}

class BudgetDataSourceImpl implements BudgetDataSource {
  final SupabaseClient supabaseClient;

  BudgetDataSourceImpl(this.supabaseClient);

  @override
  Future<String?> getBudgetFamilyIdForProfile(String profileId) async {
    final membership = await supabaseClient
        .from('budget_family_members')
        .select('family_id')
        .eq('profile_id', profileId)
        .maybeSingle();

    return membership?['family_id'] as String?;
  }

  @override
  Future<Map<String, dynamic>?> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  ) async {
    try {
      final startOfMonth = DateTime(monthYear.year, monthYear.month, 1);
      final endOfMonth = DateTime(monthYear.year, monthYear.month + 1, 1);
      final budgetFamilyId = await getBudgetFamilyIdForProfile(profileId);

      var budgetQuery = supabaseClient
          .from('monthly_budgets')
          .select('id, monthly_income, budget_limit, month_year')
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String());

      budgetQuery = budgetFamilyId != null
          ? budgetQuery.eq('family_id', budgetFamilyId)
          : budgetQuery.eq('profile_id', profileId);

      final budget = await budgetQuery.maybeSingle();
      return budget;
    } catch (e) {
      return null;
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
      final budgetFamilyId = await getBudgetFamilyIdForProfile(profileId);

      // Obtener presupuesto existente
      var existingQuery = supabaseClient
          .from('monthly_budgets')
          .select('id')
          .gte('month_year', startOfMonth.toIso8601String())
          .lt('month_year', endOfMonth.toIso8601String());

      existingQuery = budgetFamilyId != null
          ? existingQuery.eq('family_id', budgetFamilyId)
          : existingQuery.eq('profile_id', profileId);

      var existing = await existingQuery.maybeSingle();

      if (existing != null) {
        // Actualizar usando UPSERT
        final budgetId = existing['id'] as String;

        final upsertResult = await supabaseClient
            .from('monthly_budgets')
            .upsert({
              'id': budgetId,
              'profile_id': profileId,
              if (budgetFamilyId != null) 'family_id': budgetFamilyId,
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
              if (budgetFamilyId != null) 'family_id': budgetFamilyId,
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
}
