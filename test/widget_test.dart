import 'package:campus_market/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Cek apakah halaman login muncul', (WidgetTester tester) async {

    // 1. Panggil MyApp langsung dengan 'const'
    // (Karena di main.dart kamu sudah pasang const constructor & MultiProvider)
    await tester.pumpWidget(const MyApp());

    // 2. Tunggu sampai semua animasi/loading selesai
    await tester.pumpAndSettle();

    // 3. Cek apakah teks "Login Campus Market" muncul di layar
    expect(find.text('Login Campus Market'), findsOneWidget);

    // 4. Pastikan tombol Login ada
    expect(find.text('LOGIN'), findsOneWidget);
  });
}