// lib/services/ca_lam_service.dart
import '../models/ca_lam.dart';
import 'package:http/http.dart' as http; // For API calls later

class CaLamService {
  final String _baseUrl = '';

  // Creates a new CaLam object locally when a shift starts
  CaLam startNewShift({required int idNhanVien}) {
    print('CaLamService: Starting new shift for NhanVien ID: $idNhanVien');
    return CaLam.startNewShift(idNhanVien: idNhanVien);
  }

  Future<void> endShiftAndSave(CaLam caLam) async {
    caLam.ketThucCaLam(); // Set the end time

    print('CaLamService: Ending shift ID: ${caLam.idCaLam}');
    print('   NhanVien ID: ${caLam.idNhanVien}');
    print('   Start Time: ${caLam.thoiGianBatDau}');
    print('   End Time: ${caLam.thoiGianKetThuc}');
    print('   Total Sales: ${caLam.tongTien}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/calam/end'), // Example endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('CaLamService: Shift data saved successfully.');
      } else {
        print('CaLamService: Failed to save shift data. Status: ${response.statusCode}, Body: ${response.body}');
        // Handle error appropriately
      }
    } catch (e) {
      print('CaLamService: Error saving shift data: $e');
      // Handle error appropriately
    }

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    //temp saving test
    print('CaLamService: Shift ${caLam.idCaLam} processed for saving.');
  }
}

