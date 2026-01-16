import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/order_service.dart';
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

  // Fetch data dari API
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

  // Hitung total harga barang yang dicentang
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

  // --- LOGIKA HAPUS ITEM ---
  void _deleteItem(int cartId, int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hapus Barang"),
        content: Text("Yakin ingin menghapus barang ini dari keranjang?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Batal")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Hapus", style: TextStyle(color: Colors.red))
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Barang dihapus"), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus barang"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // LOGIKA CHECKOUT
  void _processCheckout() async {
    List<CartItem> selectedItems = items.where((i) => i.isSelected).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pilih minimal 1 barang untuk dibeli")),
      );
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    bool success = await OrderService().checkout(user.id);

    if (success) {
      CartItem targetItem = selectedItems.first;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Pesanan Dibuat! Membuka chat dengan penjual..."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            currentUserId: user.id.toString(),
            otherUserId: targetItem.sellerId.toString(),
            productId: targetItem.productId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Checkout, coba lagi nanti."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Keranjang Saya", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Keranjang kosong"),
        ],
      ))
          : ListView.builder(
        itemCount: items.length,
        padding: EdgeInsets.only(bottom: 100),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // CHECKBOX
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

                  // GAMBAR / ICON
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
                  SizedBox(width: 10),

                  // DETAIL INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaProduk,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text("Penjual ID: ${item.sellerId}", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(item.harga),
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // TOMBOL HAPUS
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
                Text("Total Pembayaran:", style: TextStyle(color: Colors.grey[600])),
                Text(
                  currencyFormatter.format(totalPrice),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC107),
                foregroundColor: Color(0xFF0D47A1),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Checkout (COD)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}