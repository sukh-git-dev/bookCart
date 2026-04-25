import 'package:bookcart/core/config/supabase_app_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isSupabaseMissingTableError(Object error, {String? table}) {
  if (error is! PostgrestException) {
    return false;
  }

  if ((error.code ?? '').toUpperCase() != 'PGRST205') {
    return false;
  }

  final message = error.message.toLowerCase();
  if (table == null) {
    return message.contains('could not find the table');
  }

  return message.contains(table.toLowerCase());
}

String supabaseSchemaSetupMessage({String? table}) {
  final tableText = table == null
      ? 'the required Supabase tables'
      : 'the `$table` table';

  return 'Supabase schema is missing $tableText. Run '
      '`./scripts/setup_supabase_schema.sh` after linking project '
      '`${SupabaseAppOptions.defaultProjectRef}`, or set `SUPABASE_DB_URL` and '
      'run the same script.';
}
