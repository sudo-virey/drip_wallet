import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Obtener dashboard de un mes específico
class GetDashboardForMonthUseCase {
  final FinanceRepository repository;

  GetDashboardForMonthUseCase(this.repository);

  Future<Either<Failure, DashboardEntity>> call(
    String profileId,
    DateTime month,
  ) async {
    return repository.fetchDashboardDataForMonth(profileId, month);
  }
}
