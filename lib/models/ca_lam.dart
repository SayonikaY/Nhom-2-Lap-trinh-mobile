// lib/models/ca_lam.dart
import './nhan_vien.dart';

class CaLam {
  String idCaLam;
  int idNhanVien;
  DateTime thoiGianBatDau;
  DateTime? thoiGianKetThuc; // Nullable, as the shift might be ongoing
  double tongTien;

  CaLam({
    required this.idCaLam,
    required this.idNhanVien,
    required this.thoiGianBatDau,
    this.thoiGianKetThuc,
    this.tongTien = 0.0,
  });

  factory CaLam.startNewShift({
    required int idNhanVien,
  }) {
    return CaLam(
      idCaLam: 'CL_${DateTime.now()}', // Unique ID based on timestamp
      idNhanVien: idNhanVien,
      thoiGianBatDau: DateTime.now(),
      tongTien: 0.0,
    );
  }

  void themVaoTongTien(double soTien) {
    tongTien += soTien;
  }

  void ketThucCaLam() {
    thoiGianKetThuc = DateTime.now();
  }
}

