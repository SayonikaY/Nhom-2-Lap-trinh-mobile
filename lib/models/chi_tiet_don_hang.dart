class ChiTietDonHang {
  final int? maChiTiet;
  final int? maDonHang;
  final int maMonAn;
  final int soLuong;
  final double tongGia;

  ChiTietDonHang({
    this.maChiTiet,
    this.maDonHang,
    required this.maMonAn,
    required this.soLuong,
    required this.tongGia,
  });

  factory ChiTietDonHang.fromJson(Map<String, dynamic> json) => ChiTietDonHang(
        maChiTiet: json['MaChiTiet'],
        maDonHang: json['MaDonHang'],
        maMonAn: json['MaMonAn'],
        soLuong: json['SoLuong'],
        tongGia: json['TongGia'],
      );

  Map<String, dynamic> toJson() => {
        'MaChiTiet': maChiTiet,
        'MaDonHang': maDonHang,
        'MaMonAn': maMonAn,
        'SoLuong': soLuong,
        'TongGia': tongGia,
      };
}

