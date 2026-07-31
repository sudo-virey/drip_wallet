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
  Future<Either<Failure, DashboardEntity>> fetchDashboardDataForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      final dashboard = await remoteDataSource.fetchDashboardDataForMonth(
        profileId,
        month,
      );
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

  @override
  Future<Either<Failure, void>> setMonthlyBudget(
    String profileId,
    DateTime monthYear,
    double budgetLimit,
  ) async {
    try {
      await remoteDataSource.setMonthlyBudget(
        profileId,
        monthYear,
        budgetLimit,
      );
      return Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getMonthlyBudget(
    String profileId,
    DateTime monthYear,
  ) async {
    try {
      final budget = await remoteDataSource.getMonthlyBudget(
        profileId,
        monthYear,
      );
      return Right(budget);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String transactionId) async {
    try {
      await remoteDataSource.deleteTransaction(transactionId);
      return Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      await remoteDataSource.updateTransaction(transactionId, data);
      return Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> fetchAllTransactionsForMonth(
    String profileId,
    DateTime month,
  ) async {
    try {
      final transactionModels = await remoteDataSource.fetchAllTransactionsForMonth(
        profileId,
        month,
      );
      final entities = transactionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(entities);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
