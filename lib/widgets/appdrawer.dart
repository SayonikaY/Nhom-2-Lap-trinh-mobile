// lib/widgets/appdrawer.dart
import 'package:flutter/material.dart';
import '../models/ca_lam.dart';
import '../models/nhan_vien.dart';
import '../services/ca_lam_service.dart'; // Import NhanVien
import '../screens/quan_li_mon_an_screen.dart'; // Import QuanLiMonAnScreen
import '../screens/lich_su_hoa_don_screen.dart'; // Import LichSuHoaDonScreen
// Import other screens if needed for navigation
// import '../screens/quan_li_thuc_don_screen.dart';

class AppDrawer extends StatelessWidget {
  final NhanVien nhanVien;
  final CaLam? currentCaLam; // Make CaLam nullable, as it might not exist for all roles or before login

  const AppDrawer({super.key, required this.nhanVien, this.currentCaLam}); // Update constructor

  @override
  Widget build(BuildContext context) {
    List<Widget> drawerItems = [];

    // Add UserAccountsDrawerHeader
    drawerItems.add(
      UserAccountsDrawerHeader(
        accountName: Text(nhanVien.tenNhanVien, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        accountEmail: Text(nhanVien.chucVu, style: const TextStyle(color: Colors.white70)),
        currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            nhanVien.tenNhanVien.isNotEmpty ? nhanVien.tenNhanVien[0].toUpperCase() : 'NV',
            style: const TextStyle(fontSize: 40.0, color: Colors.indigo),
          ),
        ),
        decoration: const BoxDecoration(
          color: Colors.indigo,
        ),
      ),
    );

    // Add items based on role
    if (nhanVien.chucVu == 'Nhan Vien') {
      drawerItems.add(
        ListTile(
          leading: const Icon(Icons.table_restaurant_outlined),
          title: const Text('Quản lí Bàn'),
          onTap: () {
            // If already on QuanLiBanScreen, pop. Otherwise, navigate.
            // This assumes QuanLiBanScreen is the primary screen.
            Navigator.pop(context);
          },
        ),
      );
    } else if (nhanVien.chucVu == 'Quan Ly') {
      drawerItems.add(
        ListTile(
          leading: const Icon(Icons.people_alt_outlined),
          title: const Text('Quản lí Nhân Viên'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng Quản lí Nhân Viên (chưa triển khai)')),
            );
          },
        ),
      );
      drawerItems.add(
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Quản lí Thực đơn'),
          onTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QuanLiMonAnScreen(nhanVien: nhanVien)),
            );
          },
        ),
      );
      drawerItems.add(
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Quản lí Kho'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng Quản lí Kho (chưa triển khai)')),
            );
          },
        ),
      );
      drawerItems.add(
        ListTile(
          leading: const Icon(Icons.history_outlined),
          title: const Text('Lịch sử bán hàng'),
          onTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LichSuHoaDonScreen(nhanVien: nhanVien)),
            );
          },
        ),
      );
    }

    // Add Logout
    drawerItems.add(
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Đăng xuất'),
        onTap: () async { // Make onTap async
          Navigator.pop(context); // Close drawer

          if (currentCaLam != null) {
            // If there's an active shift, end it and save
            final CaLamService caLamService = CaLamService();
            try {
              await caLamService.endShiftAndSave(currentCaLam!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã kết thúc ca làm việc. Doanh thu: ${currentCaLam!.tongTien.toStringAsFixed(0)}đ')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi lưu ca làm việc: ${e.toString()}')),
              );
            }
          }

          // Navigate back to LoginScreen and remove all previous routes
          Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
        },
      ),
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: drawerItems,
      ),
    );
  }
}
