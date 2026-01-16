import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';

const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpBackground = Color(0xFFF5F7FA);
const Color pnpChatBubbleMe = Color(0xFF1976D2);
const Color pnpChatBubbleOther = Colors.white;

class ChatRoomScreen extends StatefulWidget {
  final String currentUserId, otherUserId, productId;

  // Parameter opsional untuk inisialisasi UI
  final String? productName;
  final String? productPrice;
  final String? productImage;

  const ChatRoomScreen({
    required this.currentUserId,
    required this.otherUserId,
    required this.productId,
    this.productName,
    this.productPrice,
    this.productImage,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  Timer? _timer;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetch(firstLoad: true);
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _fetch());
  }

  void _fetch({bool firstLoad = false}) {
    if (_isSending) return;
    ChatService().getChats(widget.productId, widget.currentUserId, widget.otherUserId).then((val) {
      if (mounted) {
        setState(() {
          messages = val;
          _isLoading = false;
        });
        if (firstLoad && messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final text = _msgCtrl.text;
    setState(() => _isSending = true);
    _msgCtrl.clear();
    bool success = await ChatService().sendChat(
        widget.currentUserId, widget.otherUserId, widget.productId, text);
    if (mounted) setState(() => _isSending = false);
    if (success) {
      _fetch();
      Future.delayed(Duration(milliseconds: 300), () => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pnpBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("Chat", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                bool isMe = msg.senderId == widget.currentUserId;

                // --- DETEKSI PESAN DATA UNTUK MENAMPILKAN KARTU PESANAN ---
                if (msg.message.startsWith("ORDER_INFO|")) {
                  var parts = msg.message.split("|");
                  return OrderBubble(
                    productName: parts.length > 1 ? parts[1] : "Produk",
                    price: parts.length > 2 ? "Rp ${parts[2]}" : "Rp 0",
                    imageUrl: parts.length > 3 ? parts[3] : "",
                    isMe: isMe,
                  );
                }

                return _buildMessageBubble(msg.message, isMe);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? pnpChatBubbleMe : pnpChatBubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _msgCtrl,
                decoration: InputDecoration(hintText: "Tulis pesan...", border: InputBorder.none),
              ),
            ),
          ),
          SizedBox(width: 5),
          IconButton(
            icon: Icon(Icons.send, color: pnpPrimaryBlue),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class OrderBubble extends StatelessWidget {
  final String productName, price, imageUrl;
  final bool isMe;

  const OrderBubble({required this.productName, required this.price, required this.imageUrl, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 280,
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          border: Border.all(color: pnpPrimaryBlue.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pnpPrimaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, size: 16, color: pnpPrimaryBlue),
                  SizedBox(width: 8),
                  Text("Rincian Pesanan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
                  Spacer(),
                  Text("Menunggu COD", style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.shopping_bag, size: 30))
                        : Container(width: 50, height: 50, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4),
                        Text(price, style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}