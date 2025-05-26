// lib/services/don_hang_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/don_hang.dart';

class DonHangService {
  // IMPORTANT: Replace with your actual API base URL
  static const String baseUrl = 'YOUR_API_BASE_URL'; // << SET THIS

  Future<List<DonHang>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/don-hang'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DonHang.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load DonHang list');
    }
  }

  Future<DonHang> fetchById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/don-hang/$id'));
    if (response.statusCode == 200) {
      return DonHang.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load DonHang by ID');
    }
  }

  // Fetches orders for a specific table, could be active or pre-orders
  Future<List<DonHang>> fetchOrdersByMaBan(int maBan) async {
    // Adjust endpoint as per your API, e.g., /don-hang/ban/{maBan}
    final response = await http.get(Uri.parse('$baseUrl/don-hang/ban/$maBan'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((jsonItem) => DonHang.fromJson(jsonItem)).toList();
    } else if (response.statusCode == 404) {
      return []; // No orders found for this table
    } else {
      throw Exception('Failed to load orders for table $maBan. Status: ${response.statusCode}');
    }
  }


  Future<DonHang?> fetchActiveOrderByMaBan(int maBan) async {
    // This endpoint should specifically return an order with trangThai "Đang phục vụ" or similar.
    final response = await http.get(Uri.parse('$baseUrl/don-hang/ban/$maBan/active'));
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.body != "null") {
        return DonHang.fromJson(json.decode(response.body));
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load active order for table $maBan. Status: ${response.statusCode}');
    }
  }

  // Modified to return the created DonHang object
  Future<DonHang> create(DonHang donHang) async {
    final response = await http.post(
      Uri.parse('$baseUrl/don-hang'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(donHang.toJson()),
    );
    if (response.statusCode == 201) { // 201 Created
      // Assuming the API returns the created DonHang object in the response body
      return DonHang.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create DonHang. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> update(DonHang donHang) async {
    final response = await http.put(
      Uri.parse('$baseUrl/don-hang/${donHang.maDonHang}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(donHang.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update DonHang. Status: ${response.statusCode}');
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/don-hang/$id'));
    if (response.statusCode != 200) { // Or 204 No Content
      throw Exception('Failed to delete DonHang');
    }
  }
}
