import 'package:equatable/equatable.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el dashboard del usuario
class LoadDashboard extends FinanceEvent {
  final String profileId;

  const LoadDashboard(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

/// Evento para agregar una nueva transacción
class AddTransaction extends FinanceEvent {
  final String profileId;
  final Map<String, dynamic> transactionData;

  const AddTransaction({
    required this.profileId,
    required this.transactionData,
  });

  @override
  List<Object?> get props => [profileId, transactionData];
}

/// Evento para refrescar el dashboard después de agregar una transacción
class RefreshDashboard extends FinanceEvent {
  final String profileId;

  const RefreshDashboard(this.profileId);

  @override
  List<Object?> get props => [profileId];
}
