class ChatMessage {
  final String senderId;
  final String message;
  final String timestamp;

  // Opsional: tambahkan receiverId jika perlu
  final String? receiverId;

  ChatMessage({
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.receiverId
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      // Python backend menggunakan snake_case ('sender_id')
      senderId: (json['sender_id'] ?? '').toString(),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      receiverId: (json['receiver_id'] ?? '').toString(),
    );
  }
}