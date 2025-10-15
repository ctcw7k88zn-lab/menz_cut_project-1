import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

@HiveType(typeId: 6)
enum AppointmentStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  confirmed,
  @HiveField(2)
  inProgress,
  @HiveField(3)
  completed,
  @HiveField(4)
  cancelled,
  @HiveField(5)
  noShow,
}

@HiveType(typeId: 7)
enum PaymentStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
  @HiveField(2)
  refunded,
  @HiveField(3)
  failed,
}

@HiveType(typeId: 1)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String customerId;
  
  @HiveField(2)
  final String salonId;
  
  @HiveField(3)
  final String serviceId;
  
  @HiveField(4)
  final String? staffId;
  
  @HiveField(5)
  final String? stylistId;
  
  @HiveField(6)
  final DateTime startAt;
  
  @HiveField(7)
  final DateTime endAt;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime updatedAt;
  
  @HiveField(10)
  final AppointmentStatus status;
  
  @HiveField(11)
  final PaymentStatus paymentStatus;
  
  @HiveField(12)
  final double totalAmount;
  
  @HiveField(13)
  final String? notes;
  
  @HiveField(14)
  final String? cancellationReason;
  
  @HiveField(15)
  final int? duration;
  
  @HiveField(16)
  final double? price;
  
  @HiveField(17)
  final Map<String, dynamic>? serviceDetails;
  
  @HiveField(18)
  final Map<String, dynamic>? customerDetails;
  
  @HiveField(19)
  final Map<String, dynamic>? salonDetails;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.salonId,
    required this.serviceId,
    this.staffId,
    this.stylistId,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    this.notes,
    this.cancellationReason,
    this.duration,
    this.price,
    this.serviceDetails,
    this.customerDetails,
    this.salonDetails,
  });

  DateTime get date => startAt;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final startAt = DateTime.parse(json['startAt'] as String? ?? json['scheduledAt'] as String);
    final duration = json['duration'] as int? ?? 60;
    final endAt = startAt.add(Duration(minutes: duration));
    
    return AppointmentModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      salonId: json['salonId'] as String,
      serviceId: json['serviceId'] as String,
      staffId: json['staffId'] as String?,
      stylistId: json['stylistId'] as String?,
      startAt: startAt,
      endAt: endAt,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: AppointmentStatus.values.firstWhere((e) => e.name == json['status']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == json['paymentStatus']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      duration: duration,
      price: (json['price'] as num?)?.toDouble(),
      serviceDetails: json['serviceDetails'] as Map<String, dynamic>?,
      customerDetails: json['customerDetails'] as Map<String, dynamic>?,
      salonDetails: json['salonDetails'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'salonId': salonId,
      'serviceId': serviceId,
      'staffId': staffId,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'totalAmount': totalAmount,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'duration': duration,
      'price': price,
      'serviceDetails': serviceDetails,
      'customerDetails': customerDetails,
      'salonDetails': salonDetails,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? salonId,
    String? serviceId,
    String? staffId,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    AppointmentStatus? status,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    String? notes,
    String? cancellationReason,
    int? duration,
    double? price,
    Map<String, dynamic>? serviceDetails,
    Map<String, dynamic>? customerDetails,
    Map<String, dynamic>? salonDetails,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salonId: salonId ?? this.salonId,
      serviceId: serviceId ?? this.serviceId,
      staffId: staffId ?? this.staffId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      customerDetails: customerDetails ?? this.customerDetails,
      salonDetails: salonDetails ?? this.salonDetails,
    );
  }

  String get formattedAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedScheduledDate => _formatDate(startAt);
  String get formattedScheduledTime => _formatTime(startAt);
  bool get isUpcoming => startAt.isAfter(DateTime.now()) && 
                        (status == AppointmentStatus.pending || status == AppointmentStatus.confirmed);
  bool get isPast => startAt.isBefore(DateTime.now()) || 
                    status == AppointmentStatus.completed;
  bool get canBeCancelled => isUpcoming && status != AppointmentStatus.cancelled;
  bool get canBeRescheduled => isUpcoming && status != AppointmentStatus.cancelled;
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);
    
    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
