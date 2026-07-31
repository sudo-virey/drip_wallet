import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository repository;

  FinanceBloc(this.repository) : super(const FinanceInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadDashboardForMonth>(_onLoadDashboardForMonth);
    on<LoadHistoryForMonth>(_onLoadHistoryForMonth);
    on<AddTransaction>(_onAddTransaction);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<SetMonthlyBudget>(_onSetMonthlyBudget);
    on<FetchMonthlyBudget>(_onFetchMonthlyBudget);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
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

  /// Maneja el evento LoadDashboardForMonth
  /// 
  /// Carga los datos del dashboard para un mes específico.
  /// Si no hay presupuesto en ese mes, busca el mes anterior con presupuesto.
  Future<void> _onLoadDashboardForMonth(
    LoadDashboardForMonth event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await repository.fetchDashboardDataForMonth(
      event.profileId,
      event.month,
    );

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

  /// Maneja el evento SetMonthlyBudget
  /// 
  /// Establece el límite de presupuesto mensual y recarga el dashboard.
  /// Los ingresos se registran como transacciones, no aquí.
  Future<void> _onSetMonthlyBudget(
    SetMonthlyBudget event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await repository.setMonthlyBudget(
      event.profileId,
      event.monthYear,
      event.budgetLimit,
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) async {
        emit(const BudgetSet());
        // Refrescar el dashboard después de establecer el presupuesto
        add(LoadDashboard(event.profileId));
      },
    );
  }

  /// Maneja el evento FetchMonthlyBudget
  /// 
  /// Obtiene el presupuesto mensual de un mes específico
  Future<void> _onFetchMonthlyBudget(
    FetchMonthlyBudget event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await repository.getMonthlyBudget(
      event.profileId,
      event.monthYear,
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (budget) => emit(BudgetFetched(budget)),
    );
  }

  /// Maneja el evento DeleteTransaction
  /// 
  /// Elimina (soft delete) una transacción y recarga el dashboard
  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.deleteTransaction(
      event.transactionId,
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) async {
        // Refrescar el dashboard después de eliminar la transacción
        add(RefreshDashboard(event.profileId));
      },
    );
  }

  /// Maneja el evento UpdateTransaction
  /// 
  /// Actualiza una transacción existente y recarga el dashboard
  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final result = await repository.updateTransaction(
      event.transactionId,
      event.transactionData,
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (_) async {
        // Refrescar el dashboard después de actualizar
        add(RefreshDashboard(event.profileId));
      },
    );
  }

  /// Maneja el evento LoadHistoryForMonth
  /// 
  /// Carga TODAS las transacciones de un mes específico para la pantalla de historial
  Future<void> _onLoadHistoryForMonth(
    LoadHistoryForMonth event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading());

    final result = await repository.fetchAllTransactionsForMonth(
      event.profileId,
      event.month,
    );

    result.fold(
      (failure) => emit(FinanceError(failure.message)),
      (transactions) => emit(HistoryLoaded(transactions)),
    );
  }
}
