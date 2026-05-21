import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // READ: Put the fetchTasks function right here
  Future<List<dynamic>> fetchTasks() async {
    try {
      final response = await _supabase.from('tasks').select();
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching tasks: $e');
      return []; // Return empty list on failure to keep the UI stable
    }
  }

  // CREATE: This is the saveTask function your UI calls in _addNewTask()
  Future<bool> saveTask({required String title, required int importance}) async {
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
        'user_id': userId, // Satisfies your Supabase RLS security policy
      });

      return true; // Successfully saved
    } catch (e) {
      print('Error saving task: $e');
      return false; // Failed to save
    }
  }
}
