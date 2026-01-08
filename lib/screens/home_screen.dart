import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'attendance_verification_screen.dart';
import 'attendance_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? displayName;

  const HomeScreen({super.key, this.displayName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAlreadyAbsent = false;
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _checkAttendanceStatus();
  }

  void _loadUserSession() {
    setState(() {
      final authUser = supabase.auth.currentUser;
      
      // Menggabungkan data dari AuthService dan Metadata Supabase
      userData = AuthService.currentUser ?? {
        'nama': widget.displayName ?? authUser?.userMetadata?['nama'] ?? "Mahasiswa",
        'nim': authUser?.userMetadata?['nim'] ?? "-",
      };
    });
  }

  Future<void> _checkAttendanceStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Pastikan format tanggal YYYY-MM-DD agar sinkron dengan PostgreSQL
    final String todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final scheduleMap = _getSchedule();
    final currentCourse = scheduleMap[now.weekday];

    if (currentCourse == null) return;

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id) // PERBAIKAN: Menggunakan user_id, bukan id
          .eq('date', todayDate)
          .eq('course_name', currentCourse.namaMatkul)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() => _isAlreadyAbsent = true);
      } else {
        setState(() => _isAlreadyAbsent = false);
      }
    } catch (e) {
      debugPrint("Error checking status: $e");
    }
  }

  Map<int, Course> _getSchedule() {
    return {
      DateTime.monday: Course(namaMatkul: "Technopreneurship", namaDosen: "Dosen A", hari: "Senin", jam: "13:01 - 15:30", ruang: "Lab Data"),
      DateTime.tuesday: Course(namaMatkul: "Manajemen Proyek SI", namaDosen: "Dosen B", hari: "Selasa", jam: "08:51 - 12:10", ruang: "R03 Alfa Prima"),
      DateTime.wednesday: Course(namaMatkul: "Enterprise Resource Planning", namaDosen: "Dosen C", hari: "Rabu", jam: "08:00 - 10:30", ruang: "Ruang 01"),
      DateTime.thursday: Course(namaMatkul: "Metodologi Penelitian", namaDosen: "Dosen D", hari: "Kamis", jam: "08:00 - 10:30", ruang: "Ruang 02"),
      DateTime.friday: Course(namaMatkul: "Pemrograman Mobile", namaDosen: "Bapak Buda Suyasa", hari: "Jumat", jam: "13:01 - 17:10", ruang: "Lab Mobile"),
      DateTime.saturday: Course(namaMatkul: "Data Mining", namaDosen: "Dosen E", hari: "Sabtu", jam: "08:00 - 10:00", ruang: "Ruang 05"),
    };
  }

  List<Widget> _getPages() {
    return [
      HomeContent(
        user: userData,
        isAbsent: _isAlreadyAbsent,
        scheduleMap: _getSchedule(),
        onSuccess: () => setState(() => _isAlreadyAbsent = true),
      ),
      const AttendanceListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    String name = userData?['nama'] ?? "U";
    String inisial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _getPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4A7DFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _checkAttendanceStatus();
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          const BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Kelas"),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: _currentIndex == 2 ? const Color(0xFF4A7DFF) : Colors.grey,
              child: Text(inisial, style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
            label: "Akun",
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool isAbsent;
  final Map<int, Course> scheduleMap;
  final VoidCallback onSuccess;

  const HomeContent({
    super.key,
    this.user,
    required this.isAbsent,
    required this.scheduleMap,
    required this.onSuccess,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedCourse = widget.scheduleMap[_selectedDay?.weekday];
    final bool isTodaySelected = isSameDay(_selectedDay, DateTime.now());

    final String displayNama = widget.user?['nama'] ?? "Nama Mahasiswa";
    final String displayNim = widget.user?['nim'] ?? "-";

    String formattedDate = "";
    if (_selectedDay != null) {
      formattedDate = "${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}";
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(color: Color(0xFF4A7DFF)),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayNama, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Mahasiswa - $displayNim", 
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
        ),
        
        Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF4A7DFF), shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Jadwal Kelas", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  selectedCourse != null ? "${selectedCourse.hari}, $formattedDate" : "Tidak ada jadwal",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                if (selectedCourse != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("REGULER", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(selectedCourse.ruang, style: const TextStyle(color: Colors.orange, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(selectedCourse.namaMatkul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(selectedCourse.jam, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        if (isTodaySelected) ...[
                          widget.isAbsent
                              ? _statusAbsentWidget("SUDAH ABSEN", Colors.green)
                              : SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => AttendanceVerificationScreen(course: selectedCourse)),
                                      );
                                      if (result == true) widget.onSuccess();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A7DFF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text("ABSEN SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                )
                        ] else ...[
                          _statusAbsentWidget("Absensi belum tersedia", Colors.grey)
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusAbsentWidget(String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
    );
  }
}

class Course {
  final String namaMatkul;
  final String namaDosen;
  final String hari;
  final String jam;
  final String ruang;
  Course({required this.namaMatkul, required this.namaDosen, required this.hari, required this.jam, required this.ruang});
}