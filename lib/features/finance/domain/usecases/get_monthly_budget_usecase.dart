import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Obtener presupuesto mensual
class GetMonthlyBudgetUseCase {
  final FinanceRepository repository;

  GetMonthlyBudgetUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call(
    String profileId,
    DateTime monthYear,
  ) async {
    return repository.getMonthlyBudget(profileId, monthYear);
  }
}
