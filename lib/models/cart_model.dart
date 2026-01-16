class CartItem {
  final int id;
  final int buyerId;
  final String productId;
  final int sellerId;
  final String namaProduk;
  final int harga;
  final String? gambar;
  bool isSelected;

  CartItem({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.sellerId,
    required this.namaProduk,
    required this.harga,
    this.gambar,
    this.isSelected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['ID'] ?? 0,
      buyerId: json['buyerId'] ?? 0,
      productId: json['productId'] ?? "",
      sellerId: json['sellerId'] ?? 0,
      namaProduk: json['namaProduk'] ?? "",
      harga: json['harga'] ?? 0,
      gambar: json['gambar'],
    );
  }
}