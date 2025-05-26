import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chi_tiet_don_hang.dart';

class ChiTietDonHangService {
  static const String baseUrl = '';

  Future<List<ChiTietDonHang>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/chi-tiet-don-hang'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChiTietDonHang.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ChiTietDonHang');
    }
  }

  Future<List<ChiTietDonHang>> fetchAllByMaDonHang(int maDonHang) async {
    // Adjust endpoint as needed, e.g., /chi-tiet-don-hang/don-hang/{maDonHang}
    final response = await http.get(Uri.parse('$baseUrl/chi-tiet-don-hang/don-hang/$maDonHang'));
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChiTietDonHang.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load ChiTietDonHang for order $maDonHang. Status: ${response.statusCode}');
    }
  }

  Future<ChiTietDonHang> fetchById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/chi-tiet-don-hang/$id'));
    if (response.statusCode == 200) {
      return ChiTietDonHang.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ChiTietDonHang');
    }
  }

  Future<void> create(ChiTietDonHang chiTiet) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chi-tiet-don-hang'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(chiTiet.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create ChiTietDonHang');
    }
  }

  Future<void> update(ChiTietDonHang chiTiet) async {
    final response = await http.put(
      Uri.parse('$baseUrl/chi-tiet-don-hang/${chiTiet.maChiTiet}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(chiTiet.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update ChiTietDonHang');
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/chi-tiet-don-hang/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete ChiTietDonHang');
    }
  }
}


