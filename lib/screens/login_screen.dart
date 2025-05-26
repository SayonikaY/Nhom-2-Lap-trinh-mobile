// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
// import '../models/nhan_vien.dart'; // Removed unused import
import '../services/nhan_vien_service.dart';
import 'quan_li_ban_screen.dart';
import '../models/ca_lam.dart';
import '../services/ca_lam_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final NhanVienService _nhanVienService = NhanVienService();
  final CaLamService _caLamService = CaLamService(); // Add CaLamService instance
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final nhanVien = await _nhanVienService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        // No need to set _isLoading = false here if navigating away

        if (nhanVien != null) {
          // Start a new shift using CaLamService
          final CaLam newCaLam = _caLamService.startNewShift(idNhanVien: nhanVien.maNhanVien);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuanLiBanScreen(
                nhanVien: nhanVien,
                caLam: newCaLam, // Pass the new CaLam object
              ),
            ),
          );
        } else {
          setState(() {
            _isLoading = false; // Set to false only if login fails
            _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đã xảy ra lỗi khi đăng nhập: ${e.toString()}\n\nVui lòng kiểm tra `baseUrl` trong `NhanVienService` và API.';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
