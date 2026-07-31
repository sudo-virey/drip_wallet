import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';

abstract class FinanceRepository {
  /// Obtiene el dashboard con datos financieros del usuario
  /// 
  /// Retorna [Either<Failure, DashboardEntity>] con los datos del dashboard
  /// o un error en caso de fallar
  Future<Either<Failure, DashboardEntity>> fetchDashboardData(String profileId);

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
}
