import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'database.dart';

void main() async {
  final app = Router();

  // Get Notes
  app.get('/notes', (Request request) async {
    final conn = await DatabaseHelper.connect();
    var results = await conn.query('SELECT * FROM notes');
    
    List<Map<String, dynamic>> notes = results.map((row) {
      return {
        'id': row['id'],
        'title': row['title'],
        'content': row['content'],
        'created_at': row['created_at'].toString()
      };
    }).toList();
    
    return Response.ok(notes.toString());
  });

  // Add notes
  app.post('/notes', (Request request) async {
    var payload = await request.readAsString();
    var data = Uri.splitQueryString(payload);

    final conn = await DatabaseHelper.connect();
    await conn.query(
      'INSERT INTO notes (title, content) VALUES (?, ?)',
      [data['title'], data['content']]
    );

    return Response.ok('Catatan berhasil ditambahkan');
  });

  // Run Server
  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);
  await io.serve(handler, 'localhost', 80);
  print('Server berjalan di http://localhost:5000');
}
