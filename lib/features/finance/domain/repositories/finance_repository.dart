import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';

abstract class FinanceRepository {
  /// Obtiene el dashboard con datos financieros del usuario
  /// 
  /// Retorna [Either<Failure, DashboardEntity>] con los datos del dashboard
  /// o un error en caso de fallar
  Future<Either<Failure, DashboardEntity>> fetchDashboardData(String profileId);

  /// Obtiene el dashboard para un mes específico
  /// 
  /// Si no hay presupuesto en ese mes, busca el mes anterior con presupuesto.
  /// Retorna [Either<Failure, DashboardEntity>] con los datos del dashboard
  /// o un error en caso de fallar
  Future<Either<Failure, DashboardEntity>> fetchDashboardDataForMonth(
    String profileId,
    DateTime month,
  );

  /// Agrega una nueva transacción
  /// 
  /// [data] debe contener:
  /// - title (String): Título de la transacción
  /// - category (String): Categoría de la transacción
  /// - amount (double): Monto de la transacción
  /// - type (String): Tipo de transacción ('income' o 'expense')
  /// - description (String?): Descripción opcional
  /// - date (DateTime): Fecha de la transacción
  /// 
  /// Retorna [Either<Failure, TransactionEntity>] con la transacción creada
  /// o un error en caso de fallar
  Future<Either<Failure, TransactionEntity>> addTransaction(
    String profileId,
    Map<String, dynamic> data,
  );

  /// Establece el límite de presupuesto mensual
  /// 
  /// [monthYear]: Mes para el que se establece el presupuesto
  /// [budgetLimit]: Límite de gasto del mes (los ingresos se registran como transacciones)
  /// 
  /// Retorna [Either<Failure, void>] o un error en caso de fallar
  Future<Either<Failure, void>> setMonthlyBudget(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  );

  /// Obtiene el presupuesto de un mes específico
  /// 
  /// Retorna [Either<Failure, Map>] con monthly_income y budget_limit
  Future<Either<Failure, Map<String, dynamic>?>> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  );

  /// Elimina (soft delete) una transacción
  /// 
  /// Marca la transacción como eliminada sin borrar el registro
  /// 
  /// Retorna [Either<Failure, void>] o un error en caso de fallar
  Future<Either<Failure, void>> deleteTransaction(String transactionId);

  /// Actualiza una transacción existente
  /// 
  /// [data] puede contener:
  /// - title (String): Título de la transacción
  /// - category (String): Categoría
  /// - amount (double): Monto
  /// - type (String): 'income' o 'expense'
  /// - description (String?): Descripción
  /// - date (String): Fecha ISO
  /// 
  /// Retorna [Either<Failure, void>] o un error en caso de fallar
  Future<Either<Failure, void>> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  );

  /// Obtiene TODAS las transacciones de un mes específico para la pantalla de historial
  /// 
  /// Devuelve una lista de [TransactionEntity] ordenada por fecha (más reciente primero)
  /// sin filtrar por día como lo hace fetchDashboardDataForMonth
  Future<Either<Failure, List<TransactionEntity>>> fetchAllTransactionsForMonth(
    String profileId,
    DateTime month,
  );
}
