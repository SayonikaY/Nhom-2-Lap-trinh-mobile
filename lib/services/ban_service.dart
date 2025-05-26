import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ban.dart';

class BanService {
  static const String baseUrl = '';

  Future<List<Ban>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/ban'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Ban.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Ban');
    }
  }

  Future<Ban> fetchById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/ban/$id'));
    if (response.statusCode == 200) {
      return Ban.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Ban');
    }
  }

  Future<void> create(Ban ban) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ban'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ban.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create Ban');
    }
  }

  Future<void> update(Ban ban) async {
    final response = await http.put(
      Uri.parse('$baseUrl/ban/${ban.maBan}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ban.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update Ban');
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/ban/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete Ban');
    }
  }
}

