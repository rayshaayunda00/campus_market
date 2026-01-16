import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Untuk Timer Notifikasi
import 'dart:convert'; // Untuk Decode JSON
import 'package:http/http.dart' as http;

import '../../api/api_services.dart'; // Pastikan path ini benar
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import 'product_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../seller/manage_product_screen.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import '../order/order_screen.dart';

// --- WARNA TEMA MODERN ---
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpLightBlue = Color(0xFFE3F2FD);
const Color pnpAccentYellow = Color(0xFFFFC107);
const Color pnpBackground = Color(0xFFFAFAFA);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // --- VARIABEL NOTIFIKASI ---
  Timer? _notificationTimer;
  int _previousChatCount = 0;
  bool _hasNewMessage = false;

  @override
  void initState() {
    super.initState();
    // 1. Fetch Produk
    Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).fetchProducts());

    // 2. Mulai Cek Pesan (Polling)
    _startMessagePolling();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationTimer?.cancel(); // Hentikan timer saat keluar
    super.dispose();
  }

  // --- LOGIKA CEK PESAN OTOMATIS ---
  void _startMessagePolling() {
    _checkNewMessages(); // Cek langsung saat start

    // Cek ulang setiap 5 detik
    _notificationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkNewMessages();
    });
  }

  Future<void> _checkNewMessages() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      // Endpoint mengambil daftar chat user
      final url = '${ApiServices.baseUrlChat}/my-chats/${user.id}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List chats = data['chats'];
        int currentCount = chats.length;

        if (mounted) {
          // Jika jumlah chat bertambah, berarti ada pesan baru (dari orang baru/lama)
          if (currentCount > _previousChatCount && _previousChatCount != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.mark_chat_unread, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Pesan baru diterima!"),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(20),
                  action: SnackBarAction(
                    label: "LIHAT",
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatListScreen()));
                    },
                  ),
                )
            );
          }

          setState(() {
            // Tampilkan titik merah jika ada chat > 0 (Logika sederhana)
            // Idealnya backend kirim flag "is_read", tapi ini cukup untuk simulasi
            _hasNewMessage = currentCount > 0;
            _previousChatCount = currentCount;
          });
        }
      }
    } catch (e) {
      print("Polling error: $e");
    }
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    if (_searchQuery.isEmpty) return allProducts;
    return allProducts.where((product) {
      return product.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final productProvider = Provider.of<ProductProvider>(context);
    final filteredProducts = _getFilteredProducts(productProvider.products);

    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = _buildHomeView(user, productProvider, filteredProducts);
        break;
      case 1:
        content = _buildSearchView(filteredProducts);
        break;
      case 2:
        content = OrderScreen();
        break;
      case 3:
        content = _buildProfileView(context, user);
        break;
      default:
        content = _buildHomeView(user, productProvider, filteredProducts);
    }

    return Scaffold(
      backgroundColor: pnpBackground,
      body: content,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index != 1) {
                _searchQuery = "";
                _searchController.clear();
              }
            });
          },
          selectedItemColor: pnpPrimaryBlue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Cari'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Pesanan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // =========================================
  // VIEW: BERANDA
  // =========================================
  Widget _buildHomeView(User? user, ProductProvider productProvider, List<Product> displayProducts) {
    return Column(
      children: [
        // Header
        _buildHeader(user?.nama ?? 'Mahasiswa'),

        Expanded(
          child: productProvider.isLoading
              ? Center(child: CircularProgressIndicator(color: pnpPrimaryBlue))
              : RefreshIndicator(
            onRefresh: () => productProvider.fetchProducts(),
            color: pnpPrimaryBlue,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchQuery.isEmpty) _buildHeaderBanner(),

                  _buildSectionTitle(_searchQuery.isNotEmpty
                      ? "Hasil pencarian '$_searchQuery'"
                      : "Rekomendasi Terbaru"),

                  _buildProductGrid(displayProducts),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================
  // WIDGET HEADER (DENGAN NOTIFIKASI)
  // =========================================
  Widget _buildHeader(String namaUser) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: pnpPrimaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [BoxShadow(color: pnpPrimaryBlue.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Selamat Datang, 👋", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      namaUser,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- ICON CHAT DENGAN NOTIFIKASI ---
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatListScreen()));
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                    ),
                    // TITIK MERAH (BADGE)
                    if (_hasNewMessage)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: pnpPrimaryBlue, width: 2)
                          ),
                        ),
                      )
                  ],
                ),
              ),
              // -----------------------------------

              SizedBox(width: 10),
              _buildHeaderIcon(Icons.shopping_cart_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
              }),
            ],
          ),
          SizedBox(height: 20),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari buku, elektronik...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: pnpPrimaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  }),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [pnpPrimaryBlue, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: pnpPrimaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8)
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            bottom: -25,
            child: Icon(
                Icons.shopping_bag_outlined,
                size: 140,
                color: Colors.white.withOpacity(0.1)
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "Selamat Datang di Campus Market",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: pnpAccentYellow, letterSpacing: 0.5)
                ),
                SizedBox(height: 8),
                Text(
                    "Cari Kebutuhan\nKuliahmu Di Sini!",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, height: 1.2)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
              SizedBox(height: 10),
              Text("Produk tidak ditemukan.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        return _ProductGridCard(
          product: products[i],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: products[i]))),
        );
      },
    );
  }

  // =========================================
  // VIEW: SEARCH
  // =========================================
  Widget _buildSearchView(List<Product> displayProducts) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Cari produk...",
              prefixIcon: Icon(Icons.search, color: pnpPrimaryBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => setState(() {
                  _searchController.clear();
                  _searchQuery = "";
                }),
              )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _buildProductGrid(displayProducts),
        ),
      ],
    );
  }

  // =========================================
  // VIEW: PROFIL (DENGAN BADGE STATUS)
  // =========================================
  Widget _buildProfileView(BuildContext context, User? user) {
    if (user == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
          child: Text("Silakan Login"),
        ),
      );
    }

    bool isSeller = user.role.toLowerCase() == 'penjual';

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                  height: 160,
                  decoration: BoxDecoration(
                      color: pnpPrimaryBlue,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))
                  )
              ),
              Positioned(
                bottom: -40,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 55, color: Colors.grey[400])
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 50),

          Text(user.nama, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user.email, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 10),

          // BADGE STATUS ROLE
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSeller ? Colors.green.withOpacity(0.1) : Colors.blueGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSeller ? Colors.green : Colors.blueGrey,
                  width: 1
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSeller ? Icons.verified_user : Icons.person_outline,
                  size: 16,
                  color: isSeller ? Colors.green : Colors.blueGrey,
                ),
                SizedBox(width: 6),
                Text(
                  isSeller ? "Status: Penjual Terverifikasi" : "Status: Pembeli Mahasiswa",
                  style: TextStyle(
                      color: isSeller ? Colors.green[700] : Colors.blueGrey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          if (isSeller)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: pnpPrimaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.store, color: pnpPrimaryBlue)
                ),
                title: Text("Kelola Toko Saya", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Tambah & edit produk jualan"),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageProductScreen())),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildProfileMenu(
                icon: Icons.logout,
                text: "Keluar",
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _showLogoutDialog(context)
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileMenu({required IconData icon, required String text, required VoidCallback onTap, Color textColor = Colors.black87, Color iconColor = Colors.blue}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor)),
        title: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Logout"),
        content: Text("Yakin ingin keluar aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false);
            },
            child: Text("Keluar"),
          )
        ],
      ),
    );
  }
}

// =========================================
// WIDGET CARD PRODUK
// =========================================
// =========================================
// WIDGET CARD PRODUK (RATING DIHAPUS)
// =========================================
class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      color: Colors.grey[100],
                      image: product.gambar.isNotEmpty
                          ? DecorationImage(image: NetworkImage(product.gambar[0]), fit: BoxFit.cover)
                          : null,
                    ),
                    child: product.gambar.isEmpty
                        ? Icon(Icons.image, color: Colors.grey[400], size: 40)
                        : null,
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        "Bekas",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.namaProduk,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rp ${product.harga}",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: pnpPrimaryBlue),
                      ),
                      Icon(Icons.more_horiz, size: 16, color: Colors.grey[400])
                    ],
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