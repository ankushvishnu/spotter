class BookingModel {
  final String id;
  final String clientId;
  final String trainerId;
  final DateTime sessionDate;
  final String sessionTime;
  final int durationMinutes;
  final String locationType;
  final String? locationAddress;
  final int basePrice;
  final int platformFee;
  final int totalPrice;
  final String status;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;

  // Trainer info
  final String? trainerName;
  final String? trainerAvatar;
  final List<String>? trainerSpecialties;

  // Client info
  final String? clientName;
  final String? clientAvatar;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.sessionDate,
    required this.sessionTime,
    required this.durationMinutes,
    required this.locationType,
    this.locationAddress,
    required this.basePrice,
    required this.platformFee,
    required this.totalPrice,
    required this.status,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.trainerName,
    this.trainerAvatar,
    this.trainerSpecialties,
    this.clientName,
    this.clientAvatar,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      sessionTime: json['session_time'] as String,
      durationMinutes: json['duration_minutes'] as int,
      locationType: json['location_type'] as String,
      locationAddress: json['location_address'] as String?,
      basePrice: json['base_price'] as int,
      platformFee: json['platform_fee'] as int,
      totalPrice: json['total_price'] as int,
      status: json['status'] as String,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      trainerName: json['trainer']?['users']?['full_name'] as String?,
      trainerAvatar: json['trainer']?['users']?['avatar_url'] as String?,
      trainerSpecialties: json['trainer']?['specialties'] != null
          ? List<String>.from(json['trainer']['specialties'] as List)
          : null,
      clientName: json['client']?['full_name'] as String?,
      clientAvatar: json['client']?['avatar_url'] as String?,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String get locationDisplay {
    switch (locationType) {
      case 'trainer_space':
        return 'Trainer\'s Studio';
      case 'client_location':
        return 'Your Location';
      case 'park':
        return 'Outdoor/Park';
      case 'gym':
        return 'Gym';
      default:
        return locationType;
    }
  }

  String get formattedDate {
    return '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }

  String get formattedTime {
    return sessionTime.substring(0, 5); // HH:MM
  }

  String get dateTimeDisplay {
    return '$formattedDate at $formattedTime';
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => isPending || isConfirmed;
}