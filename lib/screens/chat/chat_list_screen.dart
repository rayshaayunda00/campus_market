import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../api/api_services.dart';
import 'chat_room_screen.dart';

// Gunakan konstanta warna agar konsisten dengan HomeScreen
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpLightBlue = Color(0xFFE3F2FD);
const Color pnpBackground = Color(0xFFFAFAFA);

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  // Fungsi helper untuk merapikan tampilan pesan ORDER_INFO
  String _formatLastMessage(String message) {
    if (message.startsWith("ORDER_INFO|")) {
      List<String> parts = message.split("|");
      return "📦 Pesanan: ${parts.length > 1 ? parts[1] : 'Produk'}";
    }
    return message;
  }

  Future<void> _fetchChatList() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final url = '${ApiServices.baseUrlChat}/my-chats/${user.id}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            chatList = data['chats'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pnpBackground,
      appBar: AppBar(
        title: Text("Pesan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: pnpPrimaryBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: pnpPrimaryBlue))
          : chatList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchChatList,
        child: ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: chatList.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final chat = chatList[index];
            final otherUserId = chat['other_user_id'].toString();
            final productId = chat['product_id'].toString();
            final rawMessage = chat['message'] ?? '';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: pnpLightBlue,
                  child: Icon(Icons.person, color: pnpPrimaryBlue, size: 30),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    "Pengguna #$otherUserId",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Produk ID: $productId",
                        style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _formatLastMessage(rawMessage),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        currentUserId: currentUser!.id.toString(),
                        otherUserId: otherUserId,
                        productId: productId,
                      ),
                    ),
                  ).then((_) => _fetchChatList());
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[400]),
          ),
          SizedBox(height: 16),
          Text("Belum ada percakapan", style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
          Text("Mulailah bertanya pada penjual!", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}