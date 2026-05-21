import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // READ: Fetch only UNCOMPLETED tasks belonging to the active session user
  Future<List<dynamic>> fetchTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', false) // Protects your screens from displaying completed items
          .order('id', ascending: false);
          
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // NEW FEATURE: Fetch dynamically by energy/importance level for your Focus Board
  Future<List<dynamic>> fetchTasksByImportance(int level) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('importance', level)
          .eq('is_completed', false); // Only actively load outstanding quests
          
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching filtered tasks: $e');
      return [];
    }
  }

  // CREATE: Save a fresh task cleanly trimmed
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
        'title': title.trim(), // Strips accidental leading/trailing spaces
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

  // UPDATE: Mark task complete with whitespace protections
  Future<bool> completeTask(dynamic idOrTitle) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase.from('tasks').update({'is_completed': true});

      if (idOrTitle is int) {
        query = query.eq('id', idOrTitle);
      } else if (idOrTitle is String) {
        // Trim the incoming title string to guarantee an exact match with the DB value
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