// วางไว้ที่ lib/usb_camera_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsbCameraService {
  static const _channel = MethodChannel('photo_uploader/usb_camera');

  /// รายการอุปกรณ์ USB ทั้งหมดที่โทรศัพท์เห็น (ใช้ดู log ตอนดีบัก)
  static Future<List<Map<String, dynamic>>> listDevices() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listDevices');
    final devices =
        (raw ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    debugPrint('USB devices (${devices.length}): $devices');
    return devices;
  }

  /// หากล้อง: interface class 6 (PTP) หรือ vendorId ของ Canon (1193 = 0x04A9)
  static Future<Map<String, dynamic>?> findCamera() async {
    final devices = await listDevices();
    for (final d in devices) {
      if (d['isCamera'] == true || d['vendorId'] == 1193) return d;
    }
    return null;
  }

  /// ขอสิทธิ์ใช้งานอุปกรณ์ USB (จะมี popup ให้กดอนุญาต)
  static Future<bool> requestPermission(String deviceName) async {
    final ok = await _channel.invokeMethod<bool>(
      'requestPermission',
      {'deviceName': deviceName},
    );
    return ok ?? false;
  }
}

// ตัวอย่างใช้ในปุ่ม "ตรวจสอบกล้อง":
//
// final camera = await UsbCameraService.findCamera();
// if (camera == null) {
//   // ถ้าตรงนี้ได้ null และ log ขึ้น "USB devices (0)" = โทรศัพท์ไม่เห็นกล้อง
//   // (ปัญหาที่สาย/หัว OTG/ตั้งค่ากล้อง ไม่ใช่โค้ด)
// } else {
//   final granted = await UsbCameraService.requestPermission(camera['deviceName']);
// }
