import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../services/chat_service.dart';
import '../../providers/user_provider.dart';
import '../chat/chat_room_screen.dart';
import '../cart/cart_screen.dart';

const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpAccentYellow = Color(0xFFFFC107);
const Color pnpBackground = Color(0xFFF5F7FA);

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String sellerName = "Memuat...";
  bool isBuying = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerName();
  }

  Future<void> _fetchSellerName() async {
    String sId = widget.product.sellerId;
    if (sId.isEmpty || sId == "0") {
      if (mounted) setState(() => sellerName = "Penjual (ID Error)");
      return;
    }

    try {
      final String url = 'http://10.0.2.2:8091/users/$sId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => sellerName = data['nama'] ?? "Nama Tidak Diketahui");
      }
    } catch (e) {
      if (mounted) setState(() => sellerName = "Penjual Mahasiswa");
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: Duration(seconds: 2)),
    );
  }

  // ==========================================
  // 1. LOGIKA TAMBAH KE KERANJANG (DIPERBAIKI)
  // ==========================================
  Future<void> _handleAddToCart(UserProvider userProvider) async {
    if (isBuying) return;
    final user = userProvider.currentUser;
    int buyerId = user?.id ?? 1;
    String sId = widget.product.sellerId;
    int sellerIdInt = int.tryParse(sId) ?? 0;

    setState(() => isBuying = true);
    try {
      // PERBAIKAN: Sertakan parameter gambar agar data di keranjang lengkap
      var response = await OrderService().addToCart(
          buyerId,
          widget.product.id,
          sellerIdInt,
          widget.product.namaProduk,
          widget.product.harga,
          widget.product.gambar.isNotEmpty ? widget.product.gambar[0] : ""
      );

      if (response != null) {
        _showSnack("Berhasil masuk keranjang!", Colors.green);
      } else {
        _showSnack("Gagal menambahkan. Cek koneksi.", Colors.red);
      }
    } catch (e) {
      _showSnack("Terjadi kesalahan aplikasi.", Colors.red);
    } finally {
      if (mounted) setState(() => isBuying = false);
    }
  }

  // ==========================================
  // 2. LOGIKA BELI SEKARANG (SYNC CHAT & ORDER)
  // ==========================================
  Future<void> _handleBuyNow(UserProvider userProvider) async {
    if (isBuying) return;
    final user = userProvider.currentUser;
    if (user == null) {
      _showSnack("Silakan login terlebih dahulu.", Colors.red);
      return;
    }
    setState(() => isBuying = true);

    try {
      String pId = widget.product.id;
      String sId = widget.product.sellerId;
      int sellerIdInt = int.tryParse(sId) ?? 0;

      // 1. Add to Cart (Gunakan ID & Data Valid dari Server)
      var cartResponse = await OrderService().addToCart(
          user.id,
          pId,
          sellerIdInt,
          widget.product.namaProduk,
          widget.product.harga,
          widget.product.gambar.isNotEmpty ? widget.product.gambar[0] : ""
      );

      if (cartResponse == null) throw Exception("Gagal add to cart");

      // Ambil ID dari respon Cart Service untuk sinkronisasi chat
      String validProductId = cartResponse['cart']['product_id'].toString();
      String validSellerId = cartResponse['cart']['seller_id'].toString();

      // 2. Proses Checkout
      await Future.delayed(Duration(milliseconds: 300));
      bool checkoutSuccess = await OrderService().checkout(user.id);

      if (checkoutSuccess) {
        if (!mounted) return;

        // 3. KIRIM PESAN OTOMATIS KE DATABASE (Format ORDER_INFO)
        String orderMessage = "ORDER_INFO|${widget.product.namaProduk}|${widget.product.harga}|${widget.product.gambar.isNotEmpty ? widget.product.gambar[0] : ""}";

        await ChatService().sendChat(
          user.id.toString(),
          validSellerId,
          validProductId,
          orderMessage,
        );

        // 4. Pindah ke Chat Room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatRoomScreen(
            currentUserId: user.id.toString(),
            otherUserId: validSellerId,
            productId: validProductId,
          )),
        );

        _showSnack("Pesanan dibuat!", Colors.green);
      } else {
        _showSnack("Gagal checkout.", Colors.red);
      }
    } catch (e) {
      _showSnack("Gagal memproses transaksi.", Colors.red);
    } finally {
      if (mounted) setState(() => isBuying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: pnpBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
          child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: Colors.black87),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen())),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 350, width: double.infinity, color: Colors.grey[200],
              child: widget.product.gambar.isNotEmpty
                  ? Image.network(widget.product.gambar[0], fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.broken_image))
                  : Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
            ),
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, margin: EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rp ${widget.product.harga}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: pnpPrimaryBlue)),
                      Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)), child: Text("Tersedia", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(widget.product.namaProduk, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundColor: pnpPrimaryBlue.withOpacity(0.1), child: Icon(Icons.store, color: pnpPrimaryBlue, size: 20)),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sellerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text("ID Penjual: ${widget.product.sellerId}", style: TextStyle(fontSize: 12, color: Colors.grey[600]))])),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(widget.product.deskripsi.isEmpty ? "Tidak ada deskripsi." : widget.product.deskripsi, style: TextStyle(color: Colors.grey[700], height: 1.6)),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 15, 20, 25),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: Icon(Icons.chat_bubble_outline_rounded, color: pnpPrimaryBlue),
                onPressed: () {
                  if(widget.product.id.isEmpty || widget.product.sellerId.isEmpty) {
                    _showSnack("Data produk tidak lengkap.", Colors.red);
                    return;
                  }
                  final user = userProvider.currentUser;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
                      currentUserId: user?.id.toString() ?? "0",
                      otherUserId: widget.product.sellerId,
                      productId: widget.product.id
                  )));
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: pnpPrimaryBlue, side: BorderSide(color: pnpPrimaryBlue), padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isBuying ? null : () => _handleAddToCart(userProvider),
                child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_shopping_cart, size: 18), Text("+ Keranjang", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: pnpAccentYellow, foregroundColor: pnpPrimaryBlue, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isBuying ? null : () => _handleBuyNow(userProvider),
                child: isBuying
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: pnpPrimaryBlue))
                    : Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_bag_outlined, size: 18), Text("Beli Sekarang", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}