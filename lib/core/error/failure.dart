import 'package:equatable/equatable.dart';

// Base class for all failures
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Specific failure class for Server errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}