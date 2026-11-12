// ไฟล์เต็ม: ก๊อบไปทับ lib/main.dart ได้ทั้งไฟล์
// (หน้าจอทดสอบตรวจสอบกล้องเท่านั้น แนะนำให้สำรอง main.dart เดิมไว้ก่อน)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'usb_camera_service.dart';

void main() => runApp(const PhotoUploaderApp());

class PhotoUploaderApp extends StatelessWidget {
  const PhotoUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Uploader',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const CameraCheckPage(),
    );
  }
}

class CameraCheckPage extends StatefulWidget {
  const CameraCheckPage({super.key});

  @override
  State<CameraCheckPage> createState() => _CameraCheckPageState();
}

class _CameraCheckPageState extends State<CameraCheckPage> {
  String _log = 'เสียบกล้องแล้วกดปุ่ม "ตรวจสอบกล้อง"';
  bool _busy = false;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _log = 'กำลังตรวจสอบ...';
    });

    final buf = StringBuffer();
    try {
      final devices = await UsbCameraService.listDevices();
      buf.writeln('พบอุปกรณ์ USB ทั้งหมด: ${devices.length} ตัว');
      buf.writeln();

      for (final d in devices) {
        buf.writeln('• ${d['manufacturerName']} ${d['productName']}');
        buf.writeln('  deviceName: ${d['deviceName']}');
        buf.writeln('  vendorId: ${d['vendorId']}  productId: ${d['productId']}');
        buf.writeln('  interfaceClasses: ${d['interfaceClasses']}');
        buf.writeln('  isCamera: ${d['isCamera']}  hasPermission: ${d['hasPermission']}');
        buf.writeln();
      }

      final camera = await UsbCameraService.findCamera();
      if (camera == null) {
        buf.writeln('❌ ไม่พบกล้อง');
        buf.writeln('ถ้าจำนวนอุปกรณ์เป็น 0 แปลว่าโทรศัพท์ไม่เห็นกล้องเลย');
        buf.writeln('ให้เช็กสาย / หัว OTG / เปิดกล้อง / ปิด Wi-Fi ของกล้อง');
      } else {
        buf.writeln('✅ พบกล้อง: ${camera['productName']}');
        if (camera['hasPermission'] == true) {
          buf.writeln('✅ แอพมีสิทธิ์ใช้กล้องแล้ว');
        } else {
          final granted = await UsbCameraService.requestPermission(
            camera['deviceName'] as String,
          );
          buf.writeln(
            granted
                ? '✅ ได้รับสิทธิ์ใช้กล้องแล้ว'
                : '❌ ไม่ได้รับสิทธิ์ (กดไม่อนุญาต หรือ popup ไม่ขึ้น)',
          );
        }
      }
    } on PlatformException catch (e) {
      buf.writeln('❌ PlatformException: ${e.code}');
      buf.writeln('${e.message}');
    } catch (e) {
      buf.writeln('❌ เกิดข้อผิดพลาด: $e');
    }

    if (!mounted) return;
    setState(() {
      _log = buf.toString();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบกล้อง')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _check,
                icon: const Icon(Icons.usb),
                label: Text(_busy ? 'กำลังตรวจสอบ...' : 'ตรวจสอบกล้อง'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  // กดค้างเพื่อคัดลอกข้อความไปส่งให้ดูได้
                  child: SelectableText(
                    _log,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
