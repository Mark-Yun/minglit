import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Reinforcing PGMQ Delete Wrapper ---');
    
    // Define a robust singular delete function
    await connection.execute(r'''
      create or replace function public.pgmq_delete(queue_name text, msg_id bigint)
      returns boolean as $$
      begin
        -- Cast msg_id to int8 explicitly
        return pgmq.delete(queue_name, msg_id::int8);
      end;
      $$ language plpgsql security definer;
    ''');

    print('Function public.pgmq_delete updated!');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
