import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nhan_vien.dart';
import '../models/mon_an.dart';
import '../services/mon_an_service.dart';
import '../widgets/appdrawer.dart';

class QuanLiMonAnScreen extends StatefulWidget {
  final NhanVien nhanVien;

  const QuanLiMonAnScreen({super.key, required this.nhanVien});

  @override
  State<QuanLiMonAnScreen> createState() => _QuanLiMonAnScreenState();
}

class _QuanLiMonAnScreenState extends State<QuanLiMonAnScreen> {
  final MonAnService _monAnService = MonAnService();
  late Future<List<MonAn>> _monAnListFuture;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tenMonController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();
  final TextEditingController _giaController = TextEditingController();
  final TextEditingController _loaiMonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMonAn();
  }

  void _loadMonAn() {
    setState(() {
      _monAnListFuture = _monAnService.fetchAll();
    });
  }

  @override
  void dispose() {
    _tenMonController.dispose();
    _moTaController.dispose();
    _giaController.dispose();
    _loaiMonController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _tenMonController.clear();
    _moTaController.clear();
    _giaController.clear();
    _loaiMonController.clear();
  }

  Future<void> _showAddEditMonAnDialog({MonAn? monAn}) async {
    if (monAn != null) {
      _tenMonController.text = monAn.tenMon;
      _moTaController.text = monAn.moTa;
      _giaController.text = monAn.gia.toStringAsFixed(0);
      _loaiMonController.text = monAn.loaiMon;
    } else {
      _clearForm();
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(monAn == null ? 'Thêm Món Ăn Mới' : 'Cập Nhật Món Ăn'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: _tenMonController,
                    decoration: const InputDecoration(labelText: 'Tên Món'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên món';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _moTaController,
                    decoration: const InputDecoration(labelText: 'Mô Tả'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _giaController,
                    decoration: const InputDecoration(labelText: 'Giá'),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _loaiMonController,
                    decoration: const InputDecoration(labelText: 'Loại Món'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập loại món';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
            ),
            TextButton(
              child: Text(monAn == null ? 'Thêm' : 'Cập Nhật'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final newMonAn = MonAn(
                      maMonAn: monAn?.maMonAn ?? 0, // API should handle ID generation for new items
                      tenMon: _tenMonController.text,
                      moTa: _moTaController.text,
                      gia: double.parse(_giaController.text),
                      loaiMon: _loaiMonController.text,
                    );

                    if (monAn == null) {
                      await _monAnService.create(newMonAn);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm món ăn mới!')),
                      );
                    } else {
                      await _monAnService.update(newMonAn);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật món ăn!')),
                      );
                    }
                    Navigator.of(context).pop();
                    _clearForm();
                    _loadMonAn(); // Refresh the list
                  } catch (e) {
                    Navigator.of(context).pop(); // Close dialog first
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteMonAn(MonAn monAn) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác Nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa món "${monAn.tenMon}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () async {
                try {
                  await _monAnService.delete(monAn.maMonAn);
                  Navigator.of(context).pop(); // Close confirmation dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xóa món "${monAn.tenMon}"')),
                  );
                  _loadMonAn(); // Refresh list
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lí Thực Đơn (Món Ăn)'),
      ),
      drawer: AppDrawer(nhanVien: widget.nhanVien),
      body: RefreshIndicator(
        onRefresh: () async => _loadMonAn(),
        child: FutureBuilder<List<MonAn>>(
          future: _monAnListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có món ăn nào. Hãy thêm một món mới!'));
            }

            final monAnList = snapshot.data!;
            return ListView.builder(
              itemCount: monAnList.length,
              itemBuilder: (context, index) {
                final monAn = monAnList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(monAn.tenMon),
                    subtitle: Text('${monAn.loaiMon} - ${monAn.gia.toStringAsFixed(0)} VND'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditMonAnDialog(monAn: monAn),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteMonAn(monAn),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showAddEditMonAnDialog(monAn: monAn);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditMonAnDialog(),
        tooltip: 'Thêm Món Ăn',
        child: const Icon(Icons.add),
      ),
    );
  }
}
