import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mon_an.dart';

class MonAnService {
  // IMPORTANT: Replace with your actual API base URL
  static const String baseUrl = 'http://your_api_url_here'; // << SET THIS

  Future<List<MonAn>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/mon-an'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => MonAn.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load MonAn');
    }
  }

  Future<MonAn> fetchById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/mon-an/$id'));
    if (response.statusCode == 200) {
      return MonAn.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load MonAn');
    }
  }

  Future<void> create(MonAn monAn) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mon-an'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(monAn.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create MonAn');
    }
  }

  Future<void> update(MonAn monAn) async {
    final response = await http.put(
      Uri.parse('$baseUrl/mon-an/${monAn.maMonAn}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(monAn.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update MonAn');
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/mon-an/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete MonAn');
    }
  }
}


