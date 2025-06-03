// lib/models/ca_lam.dart
import './nhan_vien.dart';

class CaLam {
  String maCaLam;
  int maNhanVien;
  DateTime thoiGianBatDau;
  DateTime? thoiGianKetThuc; // Nullable, as the shift might be ongoing
  double tongTien;

  CaLam({
    required this.maCaLam,
    required this.maNhanVien,
    required this.thoiGianBatDau,
    this.thoiGianKetThuc,
    this.tongTien = 0.0,
  });

  factory CaLam.startNewShift({
    required int idNhanVien,
  }) {
    return CaLam(
      maCaLam: 'CL_${DateTime.now()}', // Unique ID based on timestamp
      maNhanVien: idNhanVien,
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

