import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'attendancehistoryList.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil data user yang sedang login dari AuthService kustom Anda
    final id = AuthService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Profil Mahasiswa",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Image.asset(
              'assets/logobiru.png',
              width: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ================= KARTU PROFIL =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF4A7DFF),
                    child: Icon(Icons.person, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  // Menampilkan Nama dari database
                  Text(
                    id?['nama'] ?? 'Nama Mahasiswa',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // Menampilkan NIM dari database
                  Text(
                    "NIM: ${id?['nim'] ?? '-'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  _infoRow(Icons.school_rounded, "Sistem Informasi"),
                  _infoRow(Icons.account_balance_rounded, "Fakultas Ilmu Komputer"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ================= TOMBOL RIWAYAT =================
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceHistoryList()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A7DFF), Color(0xFF6E95FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A7DFF).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.history_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Riwayat Absensi",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Lihat detail, jarak & bukti foto",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ================= TOMBOL LOGOUT =================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
  AuthService.logout();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
},

                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  "Keluar dari Aplikasi",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pendukung untuk baris informasi (Prodi/Fakultas)
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4A7DFF), size: 20),
          ),
          const SizedBox(width: 15),
          Text(
            text, 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}