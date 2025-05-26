import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nhan_vien.dart';

class NhanVienService {
  static const String baseUrl = '';

  Future<NhanVien?> login(String tenDangNhap, String matKhau) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nhan-vien/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'tenDangNhap': tenDangNhap,
        'matKhau': matKhau,
      }),
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return NhanVien.fromJson(json.decode(response.body));
      } else {
        return null; // Or handle empty response as login failure
      }
    } else if (response.statusCode == 401) {
      // Unauthorized - login failed
      return null;
    } else {
      // Other errors
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

}
