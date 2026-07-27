abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested(this.email, this.password);
}

class AuthSignOutRequested extends AuthEvent {}