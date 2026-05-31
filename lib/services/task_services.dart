import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // READ: Mengambil SEMUA tugas milik user (Aktif maupun Selesai) untuk Tasks Hub
  Future<List<dynamic>> fetchTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          // REMOVED: .eq('is_completed', false)
          .order('id', ascending: false);

      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // READ SPECIFIC: Digunakan khusus oleh Focus Screen/Board berdasarkan Level Energi
  Future<List<dynamic>> fetchTasksByImportance(int level) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('importance', level)
          .eq(
            'is_completed',
            false,
          ); // Focus Screen tetap hanya mengambil tugas aktif

      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching filtered tasks: $e');
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
        'title': title.trim(),
        'importance': importance,
        'is_completed': false,
        'user_id': userId,
      });

      return true;
    } catch (e) {
      print('Error saving task: $e');
      return false;
    }
  }

  // UPDATE: Menandai tugas sebagai selesai
  Future<bool> completeTask(dynamic idOrTitle) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase.from('tasks').update({'is_completed': true});

      if (idOrTitle is int) {
        query = query.eq('id', idOrTitle);
      } else if (idOrTitle is String) {
        query = query.eq('title', idOrTitle.trim());
      } else {
        return false;
      }

      final response = await query.eq('user_id', userId).select();
      print('Hasil update Supabase: $response');

      return response.isNotEmpty;
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }
}
