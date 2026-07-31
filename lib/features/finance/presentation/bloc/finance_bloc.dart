import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository repository;

  FinanceBloc(this.repository) : super(const FinanceInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<AddTransaction>(_onAddTransaction);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  /// Maneja el evento LoadDashboard
  /// 
  /// Carga los datos del dashboard del usuario incluyendo:
  /// - Total de ingresos
  /// - Total de gastos
  /// - Balance actual
  /// - Límite de presupuesto
  /// - Transacciones recientes
  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await repository.fetchDashboardData(event.profileId);

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }

  /// Maneja el evento AddTransaction
  /// 
  /// Agrega una nueva transacción y actualiza el dashboard.
  /// 
  /// [event.transactionData] debe contener:
  /// - title (String): Título de la transacción
  /// - category (String): Categoría
  /// - amount (double): Monto
  /// - type (String): 'income' o 'expense'
  /// - date (String o DateTime): Fecha de la transacción
  /// - description (String?): Descripción opcional
  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    // Obtener el estado actual del dashboard para mantener la información
    final currentState = state;

    emit(const FinanceLoading());

    final result = await repository.addTransaction(
      event.profileId,
      event.transactionData,
    );

    result.fold(
      (failure) {
        emit(FinanceError(failure.message));
        // Restaurar estado anterior en caso de error
        if (currentState is DashboardLoaded) {
          emit(currentState);
        }
      },
      (transaction) async {
        emit(TransactionAdded(transaction));
        // Refrescar el dashboard después de agregar la transacción
        add(RefreshDashboard(event.profileId));
      },
    );
  }

  /// Maneja el evento RefreshDashboard
  /// 
  /// Recarga el dashboard después de una acción que modifique los datos
  /// (como agregar una transacción)
  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.fetchDashboardData(event.profileId);

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }
}
