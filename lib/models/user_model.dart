class User {
  final int id;
  final String nama;
  final String nim; // Field Baru
  final String email;
  final String role;

  User({
    required this.id,
    required this.nama,
    required this.nim, // Wajib diisi
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '-', // Ambil NIM dari backend, default '-' jika null
      email: json['email'] ?? '',
      role: json['role'] ?? 'PEMBELI',
    );
  }
}