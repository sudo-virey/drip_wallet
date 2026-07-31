import 'package:equatable/equatable.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el dashboard del usuario
class LoadDashboard extends FinanceEvent {
  final String profileId;

  const LoadDashboard(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

/// Evento para cargar el dashboard de un mes específico
class LoadDashboardForMonth extends FinanceEvent {
  final String profileId;
  final DateTime month;

  const LoadDashboardForMonth({
    required this.profileId,
    required this.month,
  });

  @override
  List<Object?> get props => [profileId, month];
}

/// Evento para agregar una nueva transacción
class AddTransaction extends FinanceEvent {
  final String profileId;
  final Map<String, dynamic> transactionData;

  const AddTransaction({
    required this.profileId,
    required this.transactionData,
  });

  @override
  List<Object?> get props => [profileId, transactionData];
}

/// Evento para refrescar el dashboard después de agregar una transacción
class RefreshDashboard extends FinanceEvent {
  final String profileId;

  const RefreshDashboard(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

/// Evento para establecer el límite de presupuesto mensual
class SetMonthlyBudget extends FinanceEvent {
  final String profileId;
  final DateTime monthYear;
  final double budgetLimit;

  const SetMonthlyBudget({
    required this.profileId,
    required this.monthYear,
    required this.budgetLimit,
  });

  @override
  List<Object?> get props => [profileId, monthYear, budgetLimit];
}

/// Evento para obtener el presupuesto de un mes
class FetchMonthlyBudget extends FinanceEvent {
  final String profileId;
  final DateTime monthYear;

  const FetchMonthlyBudget({
    required this.profileId,
    required this.monthYear,
  });

  @override
  List<Object?> get props => [profileId, monthYear];
}

/// Evento para eliminar (soft delete) una transacción
class DeleteTransaction extends FinanceEvent {
  final String profileId;
  final String transactionId;

  const DeleteTransaction({
    required this.profileId,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [profileId, transactionId];
}

/// Evento para actualizar una transacción existente
class UpdateTransaction extends FinanceEvent {
  final String profileId;
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const UpdateTransaction({
    required this.profileId,
    required this.transactionId,
    required this.transactionData,
  });

  @override
  List<Object?> get props => [profileId, transactionId, transactionData];
}

/// Evento para cargar TODAS las transacciones de un mes (para History/Historial)
class LoadHistoryForMonth extends FinanceEvent {
  final String profileId;
  final DateTime month;

  const LoadHistoryForMonth({
    required this.profileId,
    required this.month,
  });

  @override
  List<Object?> get props => [profileId, month];
}
