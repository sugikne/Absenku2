import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart'; // ✅ Import AuthService kustom Anda

class AttendanceHistoryList extends StatefulWidget {
  const AttendanceHistoryList({super.key});

  @override
  State<AttendanceHistoryList> createState() => _AttendanceHistoryListState();
}

class _AttendanceHistoryListState extends State<AttendanceHistoryList> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> attendanceList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    // ✅ PERBAIKAN: Ambil ID dari AuthService, bukan supabase.auth
    final String? currentUserId = AuthService.userId;

    debugPrint("AuthService User ID: $currentUserId");

    if (currentUserId == null) {
      debugPrint("❌ User belum login (Sesi AuthService Kosong)");
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    if (mounted) setState(() => isLoading = true);

    try {
      // Mengambil data dari tabel history berdasarkan user_id kustom
      final data = await supabase
          .from('attendance_history') 
          .select()
          .eq('user_id', currentUserId) // ✅ Filter sesuai ID yang login
          .order('date', ascending: false)
          .order('time', ascending: false);

      debugPrint("📦 RAW DATA HISTORY: $data");

      if (mounted) {
        setState(() {
          attendanceList = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🔥 ERROR FETCH HISTORY: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil data: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Riwayat Absensi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchAttendance,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAttendance,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: attendanceList.length,
                    itemBuilder: (context, index) {
                      final item = attendanceList[index];

                      final String courseName = item['course_name'] ?? "Matakuliah";
                      final String status = item['status'] ?? "Hadir";
                      final String date = item['date']?.toString() ?? "-";
                      final String time = item['time']?.toString() ?? "-";
                      final String photoUrl = item['photo_url'] ?? "";

                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildThumbnail(photoUrl),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildThumbnail(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
              // ✅ Menambahkan loading builder agar lebih halus
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey[100],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildStatusBadge(String status) {
    // Normalisasi status untuk pewarnaan
    final s = status.toLowerCase();
    Color color = Colors.orange;
    if (s == "hadir") color = Colors.green;
    if (s.contains("luar")) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Belum ada riwayat absensi",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}