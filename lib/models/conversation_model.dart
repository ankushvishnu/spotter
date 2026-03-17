import '../utils/time_utils.dart';

class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final DateTime createdAt;

  // Participant 1 info
  final String? participant1Name;
  final String? participant1Avatar;

  // Participant 2 info
  final String? participant2Name;
  final String? participant2Avatar;

  ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.lastMessageAt,
    this.lastMessagePreview,
    required this.createdAt,
    this.participant1Name,
    this.participant1Avatar,
    this.participant2Name,
    this.participant2Avatar,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participant1Id: json['participant_1_id'] as String,
      participant2Id: json['participant_2_id'] as String,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessagePreview: json['last_message_preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      participant1Name: json['participant_1']?['full_name'] as String?,
      participant1Avatar: json['participant_1']?['avatar_url'] as String?,
      participant2Name: json['participant_2']?['full_name'] as String?,
      participant2Avatar: json['participant_2']?['avatar_url'] as String?,
    );
  }

  // Get the other participant's info (not the current user)
  Map<String, String?> getOtherParticipant(String currentUserId) {
    if (currentUserId == participant1Id) {
      return {
        'id': participant2Id,
        'name': participant2Name,
        'avatar': participant2Avatar,
      };
    } else {
      return {
        'id': participant1Id,
        'name': participant1Name,
        'avatar': participant1Avatar,
      };
    }
  }

  String get timeAgo => TimeUtils.timeAgo(lastMessageAt);
}