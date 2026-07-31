import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final double totalIncome;      // Suma de todas las transacciones tipo 'income'
  final double totalExpense;     // Suma de todas las transacciones tipo 'expense'
  final double balance;          // totalIncome - totalExpense
  final double budgetLimit;      // Límite de gasto del mes actual
  final List<TransactionEntity> recentTransactions;

  const DashboardEntity({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.budgetLimit,
    required this.recentTransactions,
  });

  @override
  List<Object?> get props =>
      [totalIncome, totalExpense, balance, budgetLimit, recentTransactions];
}

class TransactionEntity extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // 'income' o 'expense'
  final String? description;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
  });

  @override
  List<Object?> get props =>
      [id, title, category, amount, date, type, description];
}
