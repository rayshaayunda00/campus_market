import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/order_service.dart';
import '../../services/chat_service.dart';
import '../../providers/user_provider.dart';
import '../../models/cart_model.dart';
import '../chat/chat_room_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> items = [];
  bool isLoading = true;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      OrderService().getCart(user.id).then((val) {
        if (mounted) {
          setState(() {
            items = val;
            isLoading = false;
            _calculateTotal();
          });
        }
      });
    }
  }

  void _calculateTotal() {
    double tempTotal = 0;
    for (var item in items) {
      if (item.isSelected) {
        tempTotal += item.harga;
      }
    }
    setState(() {
      totalPrice = tempTotal;
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _processCheckout() async {
    List<CartItem> selectedItems = items.where((i) => i.isSelected).toList();

    if (selectedItems.isEmpty) {
      _showSnack("Pilih minimal 1 barang untuk dibeli", Colors.red);
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    bool success = await OrderService().checkout(user.id);

    if (success) {
      CartItem targetItem = selectedItems.first;

      String orderMessage = "ORDER_INFO|${targetItem.namaProduk}|${targetItem.harga}|${targetItem.gambar}";

      await ChatService().sendChat(
        user.id.toString(),
        targetItem.sellerId.toString(),
        targetItem.productId,
        orderMessage,
      );

      if (!mounted) return;

      _showSnack("Pesanan berhasil dibuat!", Colors.green);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            currentUserId: user.id.toString(),
            otherUserId: targetItem.sellerId.toString(),
            productId: targetItem.productId,
            productName: targetItem.namaProduk,
            productPrice: targetItem.harga.toString(),
            productImage: targetItem.gambar,
          ),
        ),
      );
    } else {
      setState(() => isLoading = false);
      _showSnack("Gagal Checkout, coba lagi nanti.", Colors.red);
    }
  }

  void _deleteItem(int cartId, int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hapus Barang"),
        content: Text("Yakin ingin menghapus barang ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await OrderService().deleteCartItem(cartId);
      if (success) {
        setState(() {
          items.removeAt(index);
          _calculateTotal();
        });
        _showSnack("Barang dihapus", Colors.black87);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Keranjang Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : items.isEmpty
          ? Center(child: Text("Keranjang kosong"))
          : ListView.builder(
        itemCount: items.length,
        padding: EdgeInsets.only(bottom: 100, top: 10),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Checkbox(
                    activeColor: Color(0xFF0D47A1),
                    value: item.isSelected,
                    onChanged: (bool? val) {
                      setState(() {
                        item.isSelected = val ?? false;
                        _calculateTotal();
                      });
                    },
                  ),
                  // --- TAMPILAN GAMBAR ---
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.gambar.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.gambar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                        : Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
                  SizedBox(width: 10),
                  // --- TAMPILAN INFO PRODUK ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaProduk,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(item.harga),
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteItem(item.id, i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Harga", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  currencyFormatter.format(totalPrice),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _processCheckout,
              child: Text("Checkout (COD)", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC107),
                foregroundColor: Color(0xFF0D47A1),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            )
          ],
        ),
      ),
    );
  }
}