class DonHang {
  final int? maDonHang;
  final int maBan;
  final DateTime thoiGianDat;
  final String trangThai;
  final bool datTruoc;
  final DateTime? thoiGianHen;

  DonHang({
    this.maDonHang,
    required this.maBan,
    required this.thoiGianDat,
    required this.trangThai,
    required this.datTruoc,
    this.thoiGianHen,
  });

  factory DonHang.fromJson(Map<String, dynamic> json) => DonHang(
        maDonHang: json['MaDonHang'],
        maBan: json['MaBan'],
        thoiGianDat: DateTime.parse(json['ThoiGianDat']),
        trangThai: json['TrangThai'],
        datTruoc: json['DatTruoc'] == 1 || json['DatTruoc'] == true,
        thoiGianHen: json['ThoiGianHen'] != null ? DateTime.tryParse(json['ThoiGianHen']) : null,
      );

  Map<String, dynamic> toJson() => {
        'MaDonHang': maDonHang,
        'MaBan': maBan,
        'ThoiGianDat': thoiGianDat.toIso8601String(),
        'TrangThai': trangThai,
        'DatTruoc': datTruoc ? 1 : 0,
        'ThoiGianHen': thoiGianHen?.toIso8601String(),
      };
}

