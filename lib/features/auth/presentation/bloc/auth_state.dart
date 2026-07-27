import 'package:drip_wallet/features/auth/domain/entities/user_entity.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final UserEntity user; // Entidad de dominio
  Authenticated(this.user);
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}