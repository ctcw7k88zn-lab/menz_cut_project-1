import 'appointment_model.dart';

class PaymentModel {
  final String id;
  final String appointmentId;
  final double amount;
  final String currency;
  final String method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime? paymentDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.amount,
    this.currency = 'PKR',
    required this.method,
    this.status = PaymentStatus.pending,
    this.transactionId,
    this.paymentDate,
    required this.createdAt,
  });

  PaymentModel copyWith({
    String? id,
    String? appointmentId,
    double? amount,
    String? currency,
    String? method,
    PaymentStatus? status,
    String? transactionId,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status.name,
      'transaction_id': transactionId,
      'payment_date': paymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      appointmentId: map['appointment_id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'PKR',
      method: map['method'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: map['transaction_id'],
      paymentDate: map['payment_date'] != null 
          ? DateTime.parse(map['payment_date']) 
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, appointmentId: $appointmentId, amount: $amount, currency: $currency, method: $method, status: $status, transactionId: $transactionId, paymentDate: $paymentDate, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PaymentModel &&
      other.id == id &&
      other.appointmentId == appointmentId &&
      other.amount == amount &&
      other.currency == currency &&
      other.method == method &&
      other.status == status &&
      other.transactionId == transactionId &&
      other.paymentDate == paymentDate &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      appointmentId.hashCode ^
      amount.hashCode ^
      currency.hashCode ^
      method.hashCode ^
      status.hashCode ^
      transactionId.hashCode ^
      paymentDate.hashCode ^
      createdAt.hashCode;
  }
}
