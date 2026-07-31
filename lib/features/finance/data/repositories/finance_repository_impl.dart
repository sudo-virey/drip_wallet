import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';
import 'package:drip_wallet/features/finance/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;

  FinanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, DashboardEntity>> fetchDashboardData(
    String profileId,
  ) async {
    try {
      final dashboard = await remoteDataSource.fetchDashboardData(profileId);
      return Right(dashboard);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> addTransaction(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    try {
      final transaction = await remoteDataSource.addExpense(
        profileId,
        data,
      );
      return Right(transaction);
    } on ArgumentError catch (e) {
      return Left(ServerFailure('Invalid data: ${e.message}'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
