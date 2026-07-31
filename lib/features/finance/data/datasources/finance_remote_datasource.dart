import 'package:drip_wallet/features/finance/data/models/dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FinanceRemoteDataSource {
  /// Obtiene los datos del dashboard desde Supabase
  Future<DashboardModel> fetchDashboardData(String profileId);

  /// Agrega una nueva transacción en Supabase
  Future<TransactionModel> addExpense(
    String profileId,
    Map<String, dynamic> data,
  );
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  FinanceRemoteDataSourceImpl(this.supabaseClient);

@override
Future<DashboardModel> fetchDashboardData(String profileId) async {
  try {
    // 1. Obtener presupuesto actual (ajusta la lógica de fecha según tu requerimiento)
    final budgetData = await supabaseClient
        .from('monthly_budgets')
        .select('*')
        .eq('profile_id', profileId)
        .order('month_year', ascending: false)
        .limit(1)
        .single();

    // 2. Obtener gastos relacionados con ese presupuesto
    final expensesResponse = await supabaseClient
        .from('expenses')
        .select('*, categories(*)') // Trae la categoría relacionada
        .eq('profile_id', profileId)
        .eq('budget_id', budgetData['id'])
        .order('created_at', ascending: false);

    // 3. Mapear esto a tu modelo (ajusta los campos según tu DashboardModel)
    // Aquí realizarías la suma de gastos en memoria:
    double totalExpense = 0;
    for (var exp in (expensesResponse as List)) {
      totalExpense += (exp['amount'] as num).toDouble();
    }

    return DashboardModel(
      totalIncome: 0, // Tu esquema actual no tiene income explícito, ¿lo manejas aparte?
      totalExpense: totalExpense,
      balance: (budgetData['total_limit'] as num).toDouble() - totalExpense,
      budgetLimit: (budgetData['total_limit'] as num).toDouble(),
      recentTransactions: expensesResponse.map((e) => TransactionModel.fromJson(e)).toList(),
    );
  } catch (e) {
    throw Exception('Error al obtener datos: $e');
  }
}
@override
Future<TransactionModel> addExpense(String profileId, Map<String, dynamic> data) async {
  try {
    // 1. Insertar en la tabla real 'expenses'
    final response = await supabaseClient
        .from('expenses')
        .insert({
          'profile_id': profileId,
          'budget_id': data['budget_id'], // Asegúrate de pasar el budget_id activo
          'category_id': data['category_id'],
          'amount': data['amount'],
          'description': data['description'],
          'type': data['type'],
        })
        .select()
        .single();

    return TransactionModel.fromJson(response);
  } catch (e) {
    throw Exception('Error al guardar gasto: $e');
  }
}

  /// Actualiza los totales del dashboard después de agregar una transacción
  Future<void> _updateDashboardTotals(String profileId) async {
    try {
      // Obtener todas las transacciones del usuario
      final transactions = await supabaseClient
          .from('transactions')
          .select('type, amount')
          .eq('user_id', profileId);

      double totalIncome = 0;
      double totalExpense = 0;

      for (final tx in transactions as List<dynamic>) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      final balance = totalIncome - totalExpense;

      // Actualizar dashboard
      await supabaseClient
          .from('dashboards')
          .update({
            'total_income': totalIncome,
            'total_expense': totalExpense,
            'balance': balance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', profileId);
    } catch (e) {
      // Log error pero no fallar la operación principal
      print('Error updating dashboard totals: $e');
    }
  }
}
