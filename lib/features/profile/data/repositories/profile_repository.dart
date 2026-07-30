import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({required SupabaseClient client}) : _client = client;

  Future<Map<String, dynamic>> getProfile(String userId) async {
    return await _client
        .from('profiles')
        .select('name, email')
        .eq('id', userId)
        .single();
  }
}
