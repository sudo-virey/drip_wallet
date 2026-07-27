abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested({required this.email, required this.password});
}

class AuthSignOutRequested extends AuthEvent {}