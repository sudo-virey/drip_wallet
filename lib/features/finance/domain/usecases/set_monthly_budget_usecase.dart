import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Establecer presupuesto mensual
class SetMonthlyBudgetUseCase {
  final FinanceRepository repository;

  SetMonthlyBudgetUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  ) async {
    return repository.setMonthlyBudget(profileId, monthYear, budgetLimit);
  }
}
