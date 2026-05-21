import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // READ: Mengambil semua tugas milik user yang sedang login
  Future<List<dynamic>> fetchTasks() async {
    try {
      // Menambahkan modifier .order() agar data terurut berdasarkan yang terbaru
      final response = await _supabase
          .from('tasks')
          .select()
          .order(
            'id',
            ascending: false,
          ); // atau ganti 'id' dengan 'created_at' jika ada
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // CREATE: Menyimpan tugas baru ke Supabase
  Future<bool> saveTask({
    required String title,
    required int importance,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        print('Error: No active user session found.');
        return false;
      }

      await _supabase.from('tasks').insert({
        'title': title,
        'importance': importance,
        'is_completed': false,
        'user_id': userId, // Memenuhi policy RLS Supabase
      });

      return true;
    } catch (e) {
      print('Error saving task: $e');
      return false;
    }
  }

  // UPDATE: Fungsi baru untuk menandai tugas sebagai selesai
  // Menerima 'idOrTitle' berupa int (ID database) atau String (Judul tugas)
  Future<bool> completeTask(dynamic idOrTitle) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase.from('tasks').update({'is_completed': true});

      if (idOrTitle is int) {
        query = query.eq('id', idOrTitle);
      } else if (idOrTitle is String) {
        query = query.eq('title', idOrTitle);
      } else {
        return false;
      }

      // Jalankan kueri dan minta data kembalian untuk melihat apakah ada baris yang ter-update
      final response = await query.eq('user_id', userId).select();
      print('Hasil update Supabase: $response'); // <--- TAMBAHKAN INI

      return response
          .isNotEmpty; // Mengembalikan true jika ada data yang berhasil diubah
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }
}
