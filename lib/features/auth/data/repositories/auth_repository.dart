
import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<UserEntity?> getCurrentUser();
  Future<void> signOut();
}