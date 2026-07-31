import 'package:equatable/equatable.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

/// Estado de carga
class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

/// Estado cuando el dashboard se ha cargado exitosamente
class DashboardLoaded extends FinanceState {
  final DashboardEntity dashboard;

  const DashboardLoaded(this.dashboard);

  @override
  List<Object?> get props => [dashboard];
}

/// Estado cuando se ha agregado una transacción exitosamente
class TransactionAdded extends FinanceState {
  final TransactionEntity transaction;

  const TransactionAdded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Estado de error
class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado cuando el presupuesto ha sido establecido exitosamente
class BudgetSet extends FinanceState {
  final String message;

  const BudgetSet({this.message = 'Presupuesto establecido correctamente'});

  @override
  List<Object?> get props => [message];
}

/// Estado cuando se ha obtenido el presupuesto mensual
class BudgetFetched extends FinanceState {
  final Map<String, dynamic>? budget;

  const BudgetFetched(this.budget);

  @override
  List<Object?> get props => [budget];
}
