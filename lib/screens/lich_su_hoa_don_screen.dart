import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhan_vien.dart';
import '../models/don_hang.dart';
import '../models/chi_tiet_don_hang.dart';
import '../models/mon_an.dart';
import '../services/don_hang_service.dart';
import '../services/chi_tiet_don_hang_service.dart';
import '../services/mon_an_service.dart';
import '../widgets/appdrawer.dart';

class LichSuHoaDonScreen extends StatefulWidget {
  final NhanVien nhanVien;

  const LichSuHoaDonScreen({super.key, required this.nhanVien});

  @override
  State<LichSuHoaDonScreen> createState() => _LichSuHoaDonScreenState();
}

class _LichSuHoaDonScreenState extends State<LichSuHoaDonScreen> {
  final DonHangService _donHangService = DonHangService();
  final ChiTietDonHangService _chiTietDonHangService = ChiTietDonHangService();
  final MonAnService _monAnService = MonAnService();

  late Future<List<DonHang>> _donHangListFuture;

  @override
  void initState() {
    super.initState();
    _loadDonHang();
  }

  void _loadDonHang() {
    setState(() {
      _donHangListFuture = _donHangService.fetchAll().then((orders) =>
          orders.where((dh) => dh.trangThai.toLowerCase() == 'hoàn tất').toList()
      );
    });
  }

  Future<void> _showHoaDonDetailsDialog(DonHang donHang) async {
    if (donHang.maDonHang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã đơn hàng không hợp lệ.')),
      );
      return;
    }
    try {
      // Fetch ChiTietDonHang for the selected DonHang
      List<ChiTietDonHang> chiTietList = await _chiTietDonHangService.fetchAllByMaDonHang(donHang.maDonHang!);

      double totalAmount = 0;
      List<Widget> itemWidgets = [];

      if (chiTietList.isEmpty) {
        itemWidgets.add(const ListTile(title: Text('Không có chi tiết cho hóa đơn này.')));
      } else {
        for (var chiTiet in chiTietList) {
          MonAn monAn = await _monAnService.fetchById(chiTiet.maMonAn);
          double thanhTien = chiTiet.soLuong * monAn.gia;
          totalAmount += thanhTien;
          itemWidgets.add(
              ListTile(
                title: Text('${monAn.tenMon} (x${chiTiet.soLuong})'),
                trailing: Text('${NumberFormat("#,##0", "vi_VN").format(thanhTien)} VND'),
              )
          );
        }
      }


      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Chi Tiết Hóa Đơn #${donHang.maDonHang}'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Bàn: ${donHang.maBan}'),
                  Text('Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(donHang.thoiGianDat)}'),
                  const Divider(),
                  ...itemWidgets,
                  const Divider(),
                  ListTile(
                    title: const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${NumberFormat("#,##0", "vi_VN").format(totalAmount)} VND', style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Đóng'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải chi tiết hóa đơn: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Hóa Đơn'),
      ),
      drawer: AppDrawer(nhanVien: widget.nhanVien),
      body: RefreshIndicator(
        onRefresh: () async => _loadDonHang(),
        child: FutureBuilder<List<DonHang>>(
          future: _donHangListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Không có hóa đơn nào đã thanh toán.'));
            }

            final completedOrders = snapshot.data!;
            return ListView.builder(
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final donHang = completedOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                    title: Text('Hóa đơn #${donHang.maDonHang ?? "N/A"}'),
                    subtitle: Text(
                        'Bàn: ${donHang.maBan} - ${DateFormat('HH:mm dd/MM/yyyy').format(donHang.thoiGianDat)}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () {
                      if (donHang.maDonHang != null) {
                        _showHoaDonDetailsDialog(donHang);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể xem chi tiết, mã hóa đơn không tồn tại.')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
