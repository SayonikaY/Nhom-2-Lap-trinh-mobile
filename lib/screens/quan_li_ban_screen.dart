// lib/screens/quan_li_ban_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ban.dart';
import '../models/nhan_vien.dart';
import '../models/don_hang.dart';
import '../models/chi_tiet_don_hang.dart';
import '../models/mon_an.dart';
import '../services/ban_service.dart';
import '../services/don_hang_service.dart';
import '../services/chi_tiet_don_hang_service.dart';
import '../services/mon_an_service.dart';
import '../widgets/appdrawer.dart';
import '../widgets/section_header.dart';
import 'oder_screen.dart';
import '../models/ca_lam.dart'; // Import the CaLam model

class QuanLiBanScreen extends StatefulWidget {
  final NhanVien nhanVien;
  final CaLam caLam; // Add CaLam to store shift data

  const QuanLiBanScreen({
    super.key,
    required this.nhanVien,
    required this.caLam, // Make CaLam a required parameter
  });

  @override
  State<QuanLiBanScreen> createState() => _QuanLiBanScreenState();
}

class _QuanLiBanScreenState extends State<QuanLiBanScreen> {
  final BanService _banService = BanService();
  final DonHangService _donHangService = DonHangService();
  final ChiTietDonHangService _chiTietDonHangService = ChiTietDonHangService();
  final MonAnService _monAnService = MonAnService();
  // static double tongDoanhThuCa = 0; // Remove this static variable

  late Future<List<Ban>> _banListFuture;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadBanData();
    // Note: widget.caLam is now available here and in the build method
    // You can access the total sales for the shift using widget.caLam.tongTien
  }

  void _loadBanData() {
    setState(() {
      _banListFuture = _banService.fetchAll();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'trống':
        return Colors.green;
      case 'có khách':
      case 'đang phục vụ':
        return Colors.red;
      case 'đã đặt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }


  Future<void> _handleTableTap(Ban ban) async {
    // The maBan field in your Ban model is non-nullable String maBan;
    // So, ban.maBan == null will always be false.
    // If maBan could legitimately be null or empty, the model should be String? maBan;
    // For now, assuming maBan is always valid if the object exists.
    // if (ban.maBan == null) { // This check is redundant due to non-nullable maBan
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Mã bàn không hợp lệ!')),
    //   );
    //   return;
    // }

    String trangThaiLower = ban.trangThai.toLowerCase();

    if (trangThaiLower == 'đang phục vụ') {
      await _showPaymentDialog(ban);
    } else if (trangThaiLower == 'trống') {
      // Navigate to OrderScreen for an empty table
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(ban: ban, nhanVien: widget.nhanVien),
        ),
      );
      if (result == true) _loadBanData();
    } else if (trangThaiLower == 'đặt trước') {
      try {
        // Fetch orders for this table to find the pre-order
        // ban.maBan is non-nullable, so ban.maBan! is redundant.
        List<DonHang> orders = await _donHangService.fetchOrdersByMaBan(ban.maBan);
        DonHang? preOrder;
        for (var order in orders) {
          if (order.datTruoc && order.trangThai.toLowerCase() == 'đã đặt trước') {
            preOrder = order;
            break;
          }
        }

        if (preOrder != null && preOrder.thoiGianHen != null) {
          DateTime now = DateTime.now();
          Duration timeUntilBooking = preOrder.thoiGianHen!.difference(now);

          if (!timeUntilBooking.isNegative && timeUntilBooking.inHours < 1) {
            // Less than 1 hour until booking time
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Bàn ${ban.soBan} đã đặt trước lúc ${DateFormat('HH:mm dd/MM').format(preOrder.thoiGianHen!)}. Không thể tạo đơn mới gần giờ hẹn.'),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return; // Block creating new order
          }
        }
        // If no conflicting pre-order or time is not close, allow proceeding.
        // OrderScreen will default to pre-order mode for this table.
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderScreen(ban: ban, nhanVien: widget.nhanVien),
          ),
        );
        if (result == true) _loadBanData();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi kiểm tra đặt trước: ${e.toString()}')),
          );
        }
      } finally {

      }
    } else {
      // For other statuses like "Ngưng phục vụ"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bàn ${ban.soBan} hiện đang ${ban.trangThai}. Không thể đặt món mới.')),
      );
    }
  }

  Future<void> _showPaymentDialog(Ban ban) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // 1. Fetch active order for the table
      // ban.maBan is non-nullable, so ban.maBan! is redundant.
      final DonHang? activeOrder = await _donHangService.fetchActiveOrderByMaBan(ban.maBan);
      if (activeOrder == null || activeOrder.maDonHang == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tìm thấy đơn hàng đang hoạt động cho bàn ${ban.soBan}.')),
          );
        }
        setState(() { _isProcessingPayment = false; });
        return;
      }

      // 2. Fetch order details (ChiTietDonHang)
      final List<ChiTietDonHang> orderItems = await _chiTietDonHangService.fetchAllByMaDonHang(activeOrder.maDonHang!);

      if (orderItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đơn hàng cho bàn ${ban.soBan} không có món nào.')),
          );
        }
        setState(() { _isProcessingPayment = false; });
        return;
      }

      // 3. Fetch MonAn details for prices and calculate total
      double totalAmount = 0;
      List<Map<String, dynamic>> itemDetailsForDisplay = [];

      for (var item in orderItems) {
        final MonAn monAn = await _monAnService.fetchById(item.maMonAn);
        totalAmount += item.soLuong * monAn.gia;
        itemDetailsForDisplay.add({
          'tenMonAn': monAn.tenMon,
          'soLuong': item.soLuong,
          'donGia': monAn.gia,
          'thanhTien': item.soLuong * monAn.gia,
        });
      }

      if (!mounted) return;
      setState(() { _isProcessingPayment = false; });

      // 4. Show dialog with order details and payment button
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Thanh toán cho Bàn ${ban.soBan}'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  ...itemDetailsForDisplay.map((detail) => Text(
                      '${detail['tenMonAn']} (x${detail['soLuong']}) - ${detail['thanhTien'].toStringAsFixed(0)}đ')),
                  const Divider(),
                  Text('Tổng cộng: ${totalAmount.toStringAsFixed(0)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Xác nhận Thanh toán'),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog first
                  await _processPayment(ban, activeOrder, totalAmount);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy thông tin thanh toán: ${e.toString()}')),
        );
      }
      setState(() { _isProcessingPayment = false; });
    }
  }

  Future<void> _processPayment(Ban banToUpdate, DonHang orderToUpdate, double amountPaid) async {
    setState(() { _isProcessingPayment = true; });
    try {
      // 1. Update DonHang status
      DonHang updatedOrder = DonHang(
        maDonHang: orderToUpdate.maDonHang,
        maBan: orderToUpdate.maBan,
        thoiGianDat: orderToUpdate.thoiGianDat,
        trangThai: 'Đã thanh toán', // New status
        datTruoc: orderToUpdate.datTruoc,
        thoiGianHen: orderToUpdate.thoiGianHen,
      );
      await _donHangService.update(updatedOrder);

      // 2. Update Ban status
      Ban updatedBan = Ban(
        maBan: banToUpdate.maBan,
        soBan: banToUpdate.soBan,
        trangThai: 'Trống', // New status
        soChoNgoi: banToUpdate.soChoNgoi,
      );
      await _banService.update(updatedBan);

      // 3. Update employee's sales
      setState(() {
        widget.caLam.themVaoTongTien(amountPaid);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công ${amountPaid.toStringAsFixed(0)}đ cho bàn ${banToUpdate.soBan}.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _loadBanData(); // Refresh table list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xử lý thanh toán: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessingPayment = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lí Bàn'),
            Text(
              'Nhân viên: ${widget.nhanVien.tenNhanVien} - Doanh thu ca: ${widget.caLam.tongTien.toStringAsFixed(0)}đ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
      drawer: AppDrawer(nhanVien: widget.nhanVien, currentCaLam: widget.caLam), // Pass caLam to AppDrawer
      body: RefreshIndicator(
        onRefresh: () async {
          _loadBanData();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.table_restaurant_outlined,
                    title: 'Danh sách bàn',
                    iconColor: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: FutureBuilder<List<Ban>>(
                      future: _banListFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !_isProcessingPayment) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Lỗi khi tải danh sách bàn.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Không tìm thấy bàn nào.'));
                        }

                        final banList = snapshot.data!;
                        return ListView.builder(
                          itemCount: banList.length,
                          itemBuilder: (context, index) {
                            final ban = banList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ListTile(
                                leading: Icon(
                                  Icons.table_bar_rounded,
                                  color: _getStatusColor(ban.trangThai),
                                  size: 30,
                                ),
                                title: Text(ban.soBan, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Trạng thái: ${ban.trangThai}\nChỗ ngồi: ${ban.soChoNgoi}'),
                                isThreeLine: true,
                                trailing: (ban.trangThai.toLowerCase() == 'có khách' || ban.trangThai.toLowerCase() == 'đang phục vụ')
                                    ? const Icon(Icons.payment)
                                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                onTap: () => _handleTableTap(ban),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessingPayment)
              Container(
                color: Colors.black.withOpacity(0.3), // Kept withOpacity for now, consider .withValue if issues arise
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng thêm bàn mới (chưa triển khai)')),
          );
        },
        tooltip: 'Thêm bàn mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
