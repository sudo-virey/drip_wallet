import 'package:dartz/dartz.dart';
import 'package:drip_wallet/core/error/failure.dart';
import 'package:drip_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:drip_wallet/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, UserEntity>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return Right(
        UserEntity(id: response.user!.id, email: response.user!.email!),
      );
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure("Unexpected error"));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Pasamos el nombre en el 'user_metadata'
      );

      if (response.user == null) {
        return Left(ServerFailure('Registration failed'));
      }

      // Auto-login después del signup para persistir la sesión
      await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return Right(
        UserEntity(id: response.user!.id, email: response.user!.email!),
      );
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final googleSignIn = serverClientId == null || serverClientId.isEmpty
          ? GoogleSignIn(scopes: ['email'])
          : GoogleSignIn(
              scopes: ['email'],
              serverClientId: serverClientId,
            );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return Left(ServerFailure('Google sign-in cancelled'));
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return Left(
          ServerFailure(
            'No se pudo obtener el token de Google. Configura GOOGLE_WEB_CLIENT_ID.',
          ),
        );
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authentication.accessToken,
      );

      final user = response.user;
      if (user == null) {
        return Left(ServerFailure('Google sign-in failed'));
      }

      return Right(
        UserEntity(id: user.id, email: user.email ?? account.email),
      );
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error'));
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
    try {
      final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final googleSignIn = serverClientId == null || serverClientId.isEmpty
          ? GoogleSignIn(scopes: ['email'])
          : GoogleSignIn(
              scopes: ['email'],
              serverClientId: serverClientId,
            );
      await googleSignIn.signOut();
    } catch (_) {}

    await supabaseClient.auth.signOut();
  }
}
