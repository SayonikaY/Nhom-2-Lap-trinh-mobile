class NhanVien {
  final int maNhanVien;
  final String tenNhanVien;
  final String chucVu;
  final String tenDangNhap;
  final String matKhau;

  NhanVien({
    required this.maNhanVien,
    required this.tenNhanVien,
    required this.chucVu,
    required this.tenDangNhap,
    required this.matKhau,
  });

  factory NhanVien.fromJson(Map<String, dynamic> json) {
    return NhanVien(
      maNhanVien: json['maNhanVien'],
      tenNhanVien: json['tenNhanVien'],
      chucVu: json['chucVu'],
      tenDangNhap: json['tenDangNhap'],
      matKhau: json['matKhau'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maNhanVien': maNhanVien,
      'tenNhanVien': tenNhanVien,
      'chucVu': chucVu,
      'tenDangNhap': tenDangNhap,
      'matKhau': matKhau,
    };
  }
}
