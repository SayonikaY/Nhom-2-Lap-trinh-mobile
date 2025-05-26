class Ban {
  final int maBan;
  final String soBan;
  final String trangThai;
  final int soChoNgoi;

  Ban({
    required this.maBan,
    required this.soBan,
    required this.trangThai,
    required this.soChoNgoi,
  });

  factory Ban.fromJson(Map<String, dynamic> json) => Ban(
        maBan: json['MaBan'],
        soBan: json['SoBan'],
        trangThai: json['TrangThai'],
        soChoNgoi: json['SoChoNgoi'],
      );

  Map<String, dynamic> toJson() => {
        'MaBan': maBan,
        'SoBan': soBan,
        'TrangThai': trangThai,
        'SoChoNgoi': soChoNgoi,
      };
}

