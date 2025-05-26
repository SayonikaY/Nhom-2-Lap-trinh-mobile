// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/ban.dart';
import '../models/nhan_vien.dart';
import '../models/mon_an.dart';
import '../models/don_hang.dart';
import '../models/chi_tiet_don_hang.dart';
import '../services/mon_an_service.dart';
import '../services/don_hang_service.dart';
import '../services/chi_tiet_don_hang_service.dart';
import '../services/ban_service.dart';

class OrderScreen extends StatefulWidget {
  final Ban ban;
  final NhanVien nhanVien;

  const OrderScreen({super.key, required this.ban, required this.nhanVien});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final MonAnService _monAnService = MonAnService();
  final DonHangService _donHangService = DonHangService();
  final ChiTietDonHangService _chiTietDonHangService = ChiTietDonHangService();
  final BanService _banService = BanService();

  late Future<List<MonAn>> _monAnListFuture;
  final Map<MonAn, int> _selectedItems = {};
  bool _isPlacingOrder = false;
  bool _isPreOrder = false;
  DateTime? _selectedPreOrderTime;

  @override
  void initState() {
    super.initState();
    _monAnListFuture = _monAnService.fetchAll();
    // If the table is already "Đã đặt trước", default to pre-order mode
    if (widget.ban.trangThai.toLowerCase() == 'đã đặt trước') {
      _isPreOrder = true;
      // Potentially load existing pre-order time if modifying, but current scope is new order
    }
  }

  void _addItem(MonAn monAn) {
    setState(() {
      _selectedItems.update(monAn, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _removeItem(MonAn monAn) {
    setState(() {
      if (_selectedItems.containsKey(monAn)) {
        if (_selectedItems[monAn]! > 1) {
          _selectedItems[monAn] = _selectedItems[monAn]! - 1;
        } else {
          _selectedItems.remove(monAn);
        }
      }
    });
  }

  double get _totalOrderAmount {
    double total = 0;
    _selectedItems.forEach((monAn, quantity) {
      total += monAn.gia * quantity;
    });
    return total;
  }

  Future<void> _selectPreOrderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedPreOrderTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedPreOrderTime ?? DateTime.now().add(const Duration(hours: 1))),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedPreOrderTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một món.')),
      );
      return;
    }

    if (_isPreOrder && _selectedPreOrderTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian đặt trước.')),
      );
      return;
    }

    if (_isPreOrder && _selectedPreOrderTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian đặt trước phải là một thời điểm trong tương lai.')),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      DonHang newDonHang = DonHang(
        maBan: widget.ban.maBan,
        thoiGianDat: DateTime.now(),
        trangThai: _isPreOrder ? 'Đã đặt trước' : 'Đang phục vụ',
        datTruoc: _isPreOrder,
        thoiGianHen: _isPreOrder ? _selectedPreOrderTime : null,
      );

      // Assumes DonHangService.create returns the created DonHang with its ID
      DonHang createdOrder = await _donHangService.create(newDonHang);

      if (createdOrder.maDonHang == null) {
        throw Exception('Không thể tạo đơn hàng hoặc không nhận được mã đơn hàng.');
      }

      for (var entry in _selectedItems.entries) {
        MonAn monAn = entry.key;
        int quantity = entry.value;
        ChiTietDonHang chiTiet = ChiTietDonHang(
          maDonHang: createdOrder.maDonHang,
          maMonAn: monAn.maMonAn, // Assuming maMonAn is not nullable in MonAn
          soLuong: quantity,
          tongGia: monAn.gia * quantity, // This is total for this item line
        );
        await _chiTietDonHangService.create(chiTiet);
      }

      Ban updatedBan = Ban(
        maBan: widget.ban.maBan,
        soBan: widget.ban.soBan,
        trangThai: _isPreOrder ? 'Đã đặt trước' : 'Đang phục vụ',
        soChoNgoi: widget.ban.soChoNgoi,
      );
      await _banService.update(updatedBan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isPreOrder
              ? 'Đặt trước thành công cho bàn ${widget.ban.soBan}'
              : 'Đặt món thành công cho bàn ${widget.ban.soBan}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đặt món/đặt trước: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt món cho Bàn ${widget.ban.soBan}'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SwitchListTile(
                  title: const Text('Đặt trước (Pre-order)'),
                  value: _isPreOrder,
                  onChanged: (bool value) {
                    setState(() {
                      _isPreOrder = value;
                      if (!_isPreOrder) {
                        _selectedPreOrderTime = null;
                      }
                    });
                  },
                ),
              ),
              if (_isPreOrder)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedPreOrderTime == null
                              ? 'Chưa chọn thời gian hẹn'
                              : 'Thời gian hẹn: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedPreOrderTime!)}',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectPreOrderDateTime,
                        child: const Text('Chọn giờ'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<MonAn>>(
                  future: _monAnListFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi tải danh sách món: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Không có món ăn nào.'));
                    }
                    final monAnList = snapshot.data!;
                    return ListView.builder(
                      itemCount: monAnList.length,
                      itemBuilder: (context, index) {
                        final monAn = monAnList[index];
                        final quantity = _selectedItems[monAn] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(monAn.tenMon),
                            subtitle: Text('${monAn.gia.toStringAsFixed(0)}đ - ${monAn.loaiMon}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: quantity > 0 ? () => _removeItem(monAn) : null,
                                  color: Colors.red,
                                ),
                                Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _addItem(monAn),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selectedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Tổng cộng: ${_totalOrderAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(_isPreOrder ? 'Xác nhận Đặt trước' : 'Xác nhận Đặt món'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isPlacingOrder)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Đang xử lý...", style: TextStyle(color: Colors.white, fontSize: 16))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
