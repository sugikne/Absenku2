import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';

class AttendanceHistoryList extends StatefulWidget {
  const AttendanceHistoryList({super.key});

  @override
  State<AttendanceHistoryList> createState() => _AttendanceHistoryListState();
}

class _AttendanceHistoryListState extends State<AttendanceHistoryList> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> attendanceList = [];
  bool isLoading = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final String? currentUserId = AuthService.userId;
    if (currentUserId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    if (mounted) setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('attendance_history')
          .select()
          .eq('user_id', currentUserId)
          .order('date', ascending: false)
          .order('time', ascending: false);

      if (mounted) {
        setState(() {
          attendanceList = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar("Gagal mengambil data: $e", Colors.red);
      }
    }
  }

  // --- FITUR DOWNLOAD GAMBAR ---
  Future<void> _downloadImage(String url) async {
    setState(() => isDownloading = true);
    try {
      // 1. Dapatkan lokasi folder temporary
      final tempDir = await getTemporaryDirectory();
      final String fileName = "Absen_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String savePath = "${tempDir.path}/$fileName";

      // 2. Download file dari URL ke folder temp
      await Dio().download(url, savePath);

      // 3. Simpan file dari temp ke Galeri HP
      await Gal.putImage(savePath);

      _showSnackBar("✅ Foto berhasil disimpan ke galeri!", Colors.green);
    } catch (e) {
      _showSnackBar("❌ Gagal mendownload: $e", Colors.red);
    } finally {
      setState(() => isDownloading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // --- FITUR DETAIL ---
  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // Agar loading download terlihat di bottomsheet
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text("Detail Kehadiran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Box Gambar & Tombol Download
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: item['photo_url'] != null && item['photo_url'] != ""
                              ? Image.network(item['photo_url'], height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _imagePlaceholderLarge())
                              : _imagePlaceholderLarge(),
                        ),
                        if (item['photo_url'] != null && item['photo_url'] != "")
                          Positioned(
                            top: 10, right: 10,
                            child: FloatingActionButton.small(
                              backgroundColor: Colors.white,
                              onPressed: isDownloading ? null : () async {
                                await _downloadImage(item['photo_url']);
                              },
                              child: isDownloading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.download, color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    _buildDetailTile(Icons.book, "Mata Kuliah", item['course_name'] ?? "-"),
                    _buildDetailTile(Icons.calendar_today, "Tanggal", item['date'] ?? "-"),
                    _buildDetailTile(Icons.access_time, "Waktu Absen", item['time'] ?? "-"),
                    _buildDetailTile(Icons.location_on, "Jarak", "${item['distance']?.toStringAsFixed(1) ?? '0'} meter"),
                    _buildDetailTile(Icons.info_outline, "Status", item['status'] ?? "Hadir"),
                    _buildDetailTile(Icons.map_outlined, "Koordinat", "${item['latitude']}, ${item['longitude']}"),
                    
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Riwayat Absensi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(onPressed: _fetchAttendance, icon: const Icon(Icons.refresh))],
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
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _showDetail(item),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _buildThumbnail(item['photo_url'] ?? ""),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['course_name'] ?? "Matakuliah", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(item['date'] ?? "-", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(item['time'] ?? "-", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(item['status'] ?? "Hadir"),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // --- WIDGET PENDUKUNG ---
  Widget _buildThumbnail(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isNotEmpty
          ? Image.network(url, width: 55, height: 55, fit: BoxFit.cover, 
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
              loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: 55, height: 55, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))))
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() => Container(width: 55, height: 55, color: Colors.grey[100], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20));

  Widget _imagePlaceholderLarge() => Container(height: 200, width: double.infinity, color: Colors.grey[100], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 50));

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color color = s == "hadir" ? Colors.green : (s.contains("luar") ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Belum ada riwayat absensi", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
}