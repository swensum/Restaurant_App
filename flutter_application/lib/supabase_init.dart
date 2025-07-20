import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://hydrecojpufsqnzpfqjp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5ZHJlY29qcHVmc3FuenBmcWpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMzcwMDUsImV4cCI6MjA2MzkxMzAwNX0.OHMDfpy-QzZn9k8Wn6om7eRoScieLg5OEQLuK1I_S3o',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit, 
      ),
      debug: true,
    );
  }
}
