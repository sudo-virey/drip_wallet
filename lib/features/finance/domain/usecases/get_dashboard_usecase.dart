import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

/// Use Case: Obtener datos del dashboard del mes actual
class GetDashboardUseCase {
  final FinanceRepository repository;

  GetDashboardUseCase(this.repository);

  Future<Either<Failure, DashboardEntity>> call(String profileId) async {
    return repository.fetchDashboardData(profileId);
  }
}
