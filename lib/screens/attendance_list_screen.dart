import 'package:flutter/material.dart';
import 'home_screen.dart';

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data MATA KULIAH 
    final List<Course> allCourses = [
      Course(
        namaMatkul: "Technopreneurship", 
        namaDosen: "Dosen A", 
        hari: "Senin", 
        jam: "13:01 - 15:30", 
        ruang: "Lab Data",
      ),
      Course(
        namaMatkul: "Manajemen Proyek Sistem Informasi", 
        namaDosen: "Dosen B", 
        hari: "Selasa", 
        jam: "08:51 - 12:10", 
        ruang: "R03 Alfa Prima Denpasar",
      ),
      Course(
        namaMatkul: "Enterprise Resource Planning", 
        namaDosen: "Dosen C", 
        hari: "Rabu", 
        jam: "08:00 - 10:30", 
        ruang: "Ruang 01",
      ),
      Course(
        namaMatkul: "Metodologi Penelitian Dan Penulisan Ilmiah", 
        namaDosen: "Dosen D", 
        hari: "Kamis", 
        jam: "08:00 - 10:30", 
        ruang: "Ruang 02",
      ),
      Course(
        namaMatkul: "Pemrograman Mobile", 
        namaDosen: "Bapak Buda Suyasa", 
        hari: "Jumat", 
        jam: "13:01 - 17:10", 
        ruang: "Lab Mobile",
      ),
      Course(
        namaMatkul: "Data Mining", 
        namaDosen: "Dosen E", 
        hari: "Sabtu", 
        jam: "08:00 - 10:00", 
        ruang: "Ruang 05",
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daftar Kuliah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF4A7DFF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.separated(
        itemCount: allCourses.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final item = allCourses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Nama Mata Kuliah 
                Text(
                  item.namaMatkul,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: Color(0xFF4A7DFF) 
                  ),
                ),
                const SizedBox(height: 10),
                
                // 2. Baris Prodi / Kelas
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "PAGI2 • Sistem Informasi",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // 3. Baris Hari & Jam
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "${item.hari}, ${item.jam}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 4. Baris Ruang
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      item.ruang,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}