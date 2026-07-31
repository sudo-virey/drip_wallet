import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Obtener historial de transacciones de un mes
class GetHistoryForMonthUseCase {
  final FinanceRepository repository;

  GetHistoryForMonthUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(
    String profileId,
    DateTime month,
  ) async {
    return repository.fetchAllTransactionsForMonth(profileId, month);
  }
}
