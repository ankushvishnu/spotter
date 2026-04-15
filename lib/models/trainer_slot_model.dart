class TrainerSlotModel {
  final String id;
  final String trainerId;
  final DateTime slotDate;
  final String startTime;
  final String endTime;
  final bool isPreferred;

  TrainerSlotModel({
    required this.id,
    required this.trainerId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    this.isPreferred = true,
  });

  factory TrainerSlotModel.fromJson(Map<String, dynamic> json) {
    return TrainerSlotModel(
      id: json['id'],
      trainerId: json['trainer_id'],
      slotDate: DateTime.parse(json['slot_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      isPreferred: json['is_preferred'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'slot_date': slotDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'is_preferred': isPreferred,
    };
  }

  String get formattedDate => '${slotDate.day}/${slotDate.month}/${slotDate.year}';
  String get timeRange => '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
}
