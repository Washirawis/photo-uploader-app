package com.example.photo_uploader_app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.photo_uploader_app/usb"
    private val ACTION_USB_PERMISSION = "com.example.photo_uploader_app.USB_PERMISSION"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getConnectedCamera") {
                val cameraInfo = checkAndRequestUsbPermission()
                result.success(cameraInfo)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkAndRequestUsbPermission(): String {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice> = usbManager.deviceList
        
        if (deviceList.isEmpty()) {
            return "ไม่พบอุปกรณ์ USB ที่เชื่อมต่อ กรุณาตรวจสอบสายและเปิดกล้อง"
        }

        var info = ""
        for (device in deviceList.values) {
            info += "ตรวจพบกล้อง:\n• Name: ${device.deviceName}\n• Vendor ID: ${device.vendorId}\n• Product ID: ${device.productId}\n"
            
            // ตรวจสอบและขอสิทธิ์ USB ด้วย PendingIntent แบบ FLAG_IMMUTABLE
            if (!usbManager.hasPermission(device)) {
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
                val intent = Intent(ACTION_USB_PERMISSION).apply {
                    setPackage(packageName)
                }
                val permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flags)
                usbManager.requestPermission(device, permissionIntent)
                info += "สถานะ: กำลังขอสิทธิ์เข้าถึง USB..."
            } else {
                info += "สถานะ: ได้รับสิทธิ์เข้าถึง USB เรียบร้อย!"
            }
        }
        return info
    }
}