import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Actualizar una transacción
class UpdateTransactionUseCase {
  final FinanceRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    return repository.updateTransaction(transactionId, transactionData);
  }
}
