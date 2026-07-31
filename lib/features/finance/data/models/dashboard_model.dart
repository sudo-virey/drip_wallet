import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/data/models/transaction_model.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required double budgetLimit,
    required List<TransactionModel> recentTransactions,
  }) : super(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: balance,
    budgetLimit: budgetLimit,
    recentTransactions: recentTransactions,
  );

  /// Convierte un JSON de Supabase a DashboardModel
  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalIncome: (json['total_income'] ?? 0.0).toDouble(),
      totalExpense: (json['total_expense'] ?? 0.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      budgetLimit: (json['budget_limit'] ?? 0.0).toDouble(),
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
          ?.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  /// Convierte DashboardModel a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': balance,
      'budget_limit': budgetLimit,
      'recent_transactions': (recentTransactions as List<TransactionModel>)
          .map((t) => t.toJson())
          .toList(),
    };
  }
}
