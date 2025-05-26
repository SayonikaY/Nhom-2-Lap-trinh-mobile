class MonAn {
  final int maMonAn;
  final String tenMon;
  final String moTa;
  final double gia;
  final String loaiMon;

  MonAn({
    required this.maMonAn,
    required this.tenMon,
    required this.moTa,
    required this.gia,
    required this.loaiMon,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) => MonAn(
        maMonAn: json['MaMonAn'],
        tenMon: json['TenMon'],
        moTa: json['MoTa'],
        gia: (json['Gia'] as num).toDouble(),
        loaiMon: json['LoaiMon'],
      );

  Map<String, dynamic> toJson() => {
        'MaMonAn': maMonAn,
        'TenMon': tenMon,
        'MoTa': moTa,
        'Gia': gia,
        'LoaiMon': loaiMon,
      };
}

