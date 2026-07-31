import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Agregar una nueva transacción
class AddTransactionUseCase {
  final FinanceRepository repository;

  AddTransactionUseCase(this.repository);

  Future<Either<Failure, TransactionEntity>> call(
    String profileId,
    Map<String, dynamic> transactionData,
  ) async {
    return repository.addTransaction(profileId, transactionData);
  }
}
