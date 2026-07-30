import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:drip_wallet/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email, 
        password: password,
      );
      
      return Right(UserEntity(
        id: response.user!.id, 
        email: response.user!.email!
      ));
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure("Unexpected error"));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(String name, String email, String password) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      return Right(UserEntity(
        id: response.user!.id,
        email: response.user!.email!,
      ));
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure("Unexpected error during registration"));
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return UserEntity(id: user.id, email: user.email!);
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }
}