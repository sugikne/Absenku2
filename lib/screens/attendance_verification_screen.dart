import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_screen.dart';

class AttendanceVerificationScreen extends StatefulWidget {
  final Course course;
  const AttendanceVerificationScreen({super.key, required this.course});

  @override
  State<AttendanceVerificationScreen> createState() => _AttendanceVerificationScreenState();
}

class _AttendanceVerificationScreenState extends State<AttendanceVerificationScreen> {
  CameraController? _controller;
  XFile? _capturedImage; 
  bool _isReady = false;
  bool _isLoading = false;
  bool _isInRange = false; 
  bool _isSuccess = false; 
  double _distanceInMeters = 0;
  String _currentTime = ""; 
  String _statusMessage = "";
  String _lateInfo = "00:00:00";
  Color _statusColor = Colors.grey;
  LatLng? lokasiUserReal;

  Position? _currentPosition;
  final LatLng lokasiKampus = const LatLng(-8.6621907, 115.2476819); 
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInit();
  }

  Future<void> _checkPermissionAndInit() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS tidak aktif, mohon aktifkan GPS anda.")));
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        Navigator.pop(context);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever && mounted) {
      Navigator.pop(context);
      return;
    }

    _initKamera();
  }

  void _initKamera() async {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.length > 1 ? cameras[1] : cameras[0], 
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        if (mounted) setState(() => _isReady = true);
      } catch (e) {
        debugPrint("Kamera Error: $e");
      }
    }
  }

  void _validateTime() {
    DateTime now = DateTime.now();
    _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    try {
      String startStr = widget.course.jam.split(" ")[0];
      List<String> parts = startStr.split(":");
      DateTime schedule = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      Duration diff = now.difference(schedule);

      setState(() {
        if (diff.isNegative) {
          _statusMessage = "Wah kamu rajin sekali!";
          _lateInfo = "00:00:00";
          _statusColor = Colors.blue;
        } else {
          _statusMessage = diff.inMinutes > 15 ? "Yah kamu terlambat!" : "Mantap! Tepat waktu.";
          _statusColor = diff.inMinutes > 15 ? Colors.orange : Colors.green;
          _lateInfo = "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
        }
      });
    } catch (e) {
      _statusMessage = "Waktu Terdeteksi";
    }
  }

  Future<void> _prosesAmbilFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isLoading = true);

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      final XFile img = await _controller!.takePicture();
      double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lokasiKampus.latitude, lokasiKampus.longitude);

      _validateTime();

      setState(() {
        _capturedImage = img;
        _currentPosition = pos;
        lokasiUserReal = LatLng(pos.latitude, pos.longitude);
        _distanceInMeters = dist;
        _isInRange = dist <= 100; 
        _isLoading = false;
      });

      _mapController.move(lokasiUserReal!, 16);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data: $e"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _finalVerifikasi() async {
    // Menggunakan currentUser secara langsung tanpa refreshSession yang memicu error
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesi tidak valid. Mohon Re-Login."))
        );
      }
      return;
    }

    if (_capturedImage == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data tidak lengkap")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final String namaUser = user.userMetadata?['nama'] ?? "Mahasiswa";
      final String nimUser = user.userMetadata?['nim'] ?? "-";

      // 1. Upload foto ke Storage
      String fileName = "${user.id}/${now.millisecondsSinceEpoch}.jpg";
      final bytes = await File(_capturedImage!.path).readAsBytes();
      
      await supabase.storage
          .from('attendance_photos')
          .uploadBinary(
            fileName, 
            bytes, 
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true)
          );

      final String photoUrl = supabase.storage.from('attendance_photos').getPublicUrl(fileName);

      // 2. Insert Database
      await supabase.from('attendance').insert({
        'user_id': user.id,
        'course_name': widget.course.namaMatkul,
        'lecturer_name': widget.course.namaDosen,
        'date': formattedDate,
        'time': formattedTime,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'distance': _distanceInMeters,
        'photo_url': photoUrl,
        'status': _isInRange ? "Hadir" : "Di luar radius",
        'user_name': namaUser,
        'nim': nimUser,
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Verifikasi Kehadiran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _capturedImage != null 
                ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                : (_isReady 
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize!.height,
                          height: _controller!.value.previewSize!.width,
                          child: CameraPreview(_controller!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: Colors.white))),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 15),
                    Text("Memproses Data...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          if (_isSuccess)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 120),
                    SizedBox(height: 20),
                    Text("VERIFIKASI BERHASIL!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          if (!_isSuccess)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(initialCenter: lokasiKampus, initialZoom: 15),
                            children: [
                              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                              MarkerLayer(markers: [
                                Marker(point: lokasiKampus, child: const Icon(Icons.location_on, color: Colors.red)),
                                if (lokasiUserReal != null) Marker(point: lokasiUserReal!, child: const Icon(Icons.my_location, color: Colors.blue)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.course.namaMatkul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (_capturedImage != null)
                              Text(_isInRange ? "✅ Lokasi Sesuai" : "❌ Di Luar Radius", 
                                  style: TextStyle(color: _isInRange ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13))
                            else
                              const Text("Siap melakukan absensi...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_capturedImage != null) ...[
                    const Divider(height: 25),
                    _buildInfoRow("Status Kehadiran", _isInRange ? _statusMessage : "Di luar radius kampus!", _isInRange ? _statusColor : Colors.red),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoRow("Jam", _currentTime, Colors.black87),
                        _buildInfoRow("Telat", _lateInfo, Colors.red),
                        _buildInfoRow("Jarak", "${_distanceInMeters.toStringAsFixed(0)}m", Colors.black87),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_capturedImage != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _capturedImage = null),
                            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text("ULANG"),
                          ),
                        ),
                      if (_capturedImage != null) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading 
                              ? null 
                              : (_capturedImage == null ? () => _prosesAmbilFoto() : (_isInRange ? _finalVerifikasi : null)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7DFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_capturedImage == null ? "AMBIL FOTO" : "VERIFIKASI SEKARANG"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}