import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Eliminar una transacción
class DeleteTransactionUseCase {
  final FinanceRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(String transactionId) async {
    return repository.deleteTransaction(transactionId);
  }
}
