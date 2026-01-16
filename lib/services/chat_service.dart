import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_services.dart';
import '../models/chat_model.dart';

class ChatService {

  // 1. AMBIL CHAT (GET) - FIXED URL FORMAT
  Future<List<ChatMessage>> getChats(String productId, String userId, String otherId) async {
    try {
      // VALIDASI: Jangan kirim request jika ID kosong (Mencegah 404)
      if (productId.isEmpty || userId.isEmpty || otherId.isEmpty || otherId == "0") {
        print("ChatService: Parameter tidak lengkap ($productId, $userId, $otherId)");
        return [];
      }

      // Backend Python Anda menggunakan PATH PARAMETER: /chat/{id}/{user1}/{user2}
      final url = Uri.parse('${ApiServices.baseUrlChat}/chat/$productId/$userId/$otherId');

      print("DEBUG GET CHAT: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Python mengembalikan: {"chats": [...]}
        List data = decoded['chats'];
        return data.map((e) => ChatMessage.fromJson(e)).toList();
      } else {
        print("Gagal ambil chat: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error Get Chat: $e");
      return [];
    }
  }

  // 2. KIRIM CHAT (POST)
  Future<bool> sendChat(String senderId, String receiverId, String productId, String message) async {
    try {
      final url = Uri.parse('${ApiServices.baseUrlChat}/chat');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId,
          "receiver_id": receiverId,
          "product_id": productId,
          "message": message,
          "timestamp": DateTime.now().toIso8601String()
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Send Chat: $e");
      return false;
    }
  }
}