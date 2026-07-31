import 'package:drip_wallet/features/finance/domain/entities/dashboard_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required String id,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required String type,
    String? description,
    String? icon,
  }) : super(
    id: id,
    title: title,
    category: category,
    amount: amount,
    date: date,
    type: type,
    description: description,
    icon: icon,
  );

  /// Convierte un JSON de Supabase a TransactionModel
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }

  /// Convierte TransactionModel a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
    };
  }

  /// Convierte TransactionModel a TransactionEntity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      type: type,
      description: description,
      icon: icon,
    );
  }
}
