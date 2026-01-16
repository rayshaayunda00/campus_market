import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../api/api_services.dart'; // Pastikan path benar
import 'chat_room_screen.dart';

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

  Future<void> _fetchChatList() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      // Panggil endpoint baru Python
      // Pastikan ApiServices.baseUrlChat mengarah ke port 8094
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
      } else {
        print("Error fetch chats: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pesan", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : chatList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];
          final otherUserId = chat['other_user_id'].toString();
          final productId = chat['product_id'].toString();
          final lastMessage = chat['message'] ?? '';
          // final time = chat['timestamp'] ?? ''; // Bisa diformat nanti

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[800]),
            ),
            title: Text(
              "User ID: $otherUserId", // Idealnya panggil API User untuk dapat nama
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text("Produk #$productId", style: TextStyle(fontSize: 12, color: Colors.blue)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastMessage,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            onTap: () {
              // Navigasi ke Chat Room saat diklik
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
              ).then((_) => _fetchChatList()); // Refresh saat kembali
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 10),
          Text("Belum ada pesan", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}