import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _namaC = TextEditingController();
  final _nimC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _namaC.dispose();
    _nimC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  // ================= SIGN UP LOGIC =================
  Future<void> _handleSignUp() async {
    // Validasi input
    if (_namaC.text.trim().isEmpty ||
        _nimC.text.trim().isEmpty ||
        _emailC.text.trim().isEmpty ||
        _passwordC.text.trim().length < 6) {
      _showSnack("Lengkapi data dan password minimal 6 karakter", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Melakukan pendaftaran via AuthService
      await AuthService().signUp(
        nama: _namaC.text.trim(),
        nim: _nimC.text.trim(),
        email: _emailC.text.trim(),
        password: _passwordC.text.trim(),
      );

      if (!mounted) return;

      // 2. Berhasil: Pindah ke Home dan kirim nama untuk ditampilkan di branda
      // Gunakan pushAndRemoveUntil agar user tidak bisa back ke halaman daftar
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(displayName: _namaC.text.trim()),
        ),
        (route) => false,
      );
      
    } catch (e) {
      debugPrint("SignUp Error: $e");
      if (mounted) {
        _showSnack("Pendaftaran gagal: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7DFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  _input("Nama Lengkap", Icons.person_outline, controller: _namaC),
                  const SizedBox(height: 20),
                  _input(
                    "NIM ",
                    Icons.badge_outlined,
                    controller: _nimC,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _input(
                    "Email",
                    Icons.email_outlined,
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _input(
                    "Password",
                    Icons.lock_outline,
                    controller: _passwordC,
                    hide: true,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A7DFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "DAFTAR SEKARANG",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Sudah punya akun? Masuk",
                      style: TextStyle(color: Colors.grey),
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

  // ================= HEADER =================
  Widget _header() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF4A7DFF),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100)),
      ),
      child: const Padding(
        padding: EdgeInsets.only(left: 30, bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Buat Akun",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Lengkapi data diri Anda",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _input(
    String hint,
    IconData icon, {
    bool hide = false,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: hide,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF4A7DFF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ================= SNACKBAR =================
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}