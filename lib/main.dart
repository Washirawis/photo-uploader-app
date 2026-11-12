import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PhotoUploaderApp());
}

class PhotoUploaderApp extends StatelessWidget {
  const PhotoUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Uploader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.photo_uploader_app/usb');
  String _deviceStatus = 'กำลังตรวจสอบการเชื่อมต่อกล้อง...';

  @override
  void initState() {
    super.initState();
    _checkUsbDevice();
  }

  Future<void> _checkUsbDevice() async {
    try {
      final String result = await platform.invokeMethod('getConnectedCamera');
      setState(() {
        _deviceStatus = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _deviceStatus = "เกิดข้อผิดพลาด: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Photo Uploader'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                _deviceStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _checkUsbDevice,
                icon: const Icon(Icons.refresh),
                label: const Text('ตรวจสอบสถานะกล้องอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}