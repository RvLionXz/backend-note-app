import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'database.dart';
import 'dart:typed_data';

void main() async {
  final app = Router();

  // Ambil semua catatan
  app.get('/notes', (Request request) async {
    final conn = await DatabaseHelper.connect();
    var results = await conn.query('SELECT * FROM notes');

    List<Map<String, dynamic>> notes = [];

    for (var row in results) {
      try {
        Map<String, dynamic> safeRow = {
          'id': row['id'],
          'title': _ensureSerializable(row['title']),
          'content': _ensureSerializable(row['content']),
          'created_at': row['created_at'].toString(),
        };
        notes.add(safeRow);
      } catch (e) {
        print('Error processing row: $e');
      }
    }

    return Response.ok(
      jsonEncode(notes),
      headers: {'Content-Type': 'application/json'},
    );
  });

  //   // Tambah catatan baru
  // app.post('/notes', (Request request) async {
  //   // Membaca payload dari body dan mendecode menjadi Map
  //   var payload = await request.readAsString();
  //   var data = jsonDecode(payload); // Menggunakan jsonDecode untuk memparse JSON

  //   final conn = await DatabaseHelper.connect();
  //   await conn.query(
  //     'INSERT INTO notes (title, content) VALUES (?, ?)',
  //     [data['title'], data['content']]
  //   );

  //   return Response.ok(
  //     jsonEncode({'message': 'Catatan berhasil ditambahkan'}),
  //     headers: {'Content-Type': 'application/json'}
  //   );
  // });

  // Tambah catatan baru
  app.post('/notes', (Request request) async {
    // Membaca payload dari body dan mendecode menjadi Map
    var payload = await request.readAsString();
    var data = jsonDecode(
      payload,
    ); // Menggunakan jsonDecode untuk memparse JSON

    final conn = await DatabaseHelper.connect();
    await conn.query('INSERT INTO notes (title, content) VALUES (?, ?)', [
      data['title'],
      data['content'],
    ]);

    return Response.ok(
      jsonEncode({'message': 'Catatan berhasil ditambahkan'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Hapus catatan
  app.delete('/notes/<id>', (Request request) async {
    // Mengambil ID dari URL parameter
    final id = request.params['id'];

    final conn = await DatabaseHelper.connect();

    // Melakukan query untuk menghapus catatan berdasarkan ID
    final result = await conn.query('DELETE FROM notes WHERE id = ?', [id]);

    // Jika tidak ada baris yang terpengaruh (catatan tidak ditemukan)
    if (result.affectedRows == 0) {
      return Response.notFound(
        jsonEncode({'message': 'Catatan tidak ditemukan'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Mengembalikan respons berhasil
    return Response.ok(
      jsonEncode({'message': 'Catatan berhasil dihapus'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Jalankan server
  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);

  // Bind to all network interfaces (0.0.0.0) instead of just localhost
  await io.serve(handler, '0.0.0.0', 5000);
  print('Server berjalan di http://0.0.0.0:5000');
}

// Helper function to ensure a value is JSON serializable
dynamic _ensureSerializable(dynamic value) {
  if (value == null) return null;

  // Handle common types that are already serializable
  if (value is String || value is num || value is bool) {
    return value;
  }

  // Handle binary data
  if (value is Uint8List) {
    return utf8.decode(value);
  }

  if (value is List<int>) {
    return utf8.decode(value);
  }

  // For any other type, try to convert to string
  try {
    // Some database libraries have a toString() method that works well
    return value.toString();
  } catch (e) {
    // Last resort fallback
    return 'Unserializable data';
  }
}
