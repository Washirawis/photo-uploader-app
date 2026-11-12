// ไฟล์เต็ม: ก๊อบไปทับ android/app/src/main/kotlin/.../MainActivity.kt ได้ทั้งไฟล์
// ⚠️ แก้ได้จุดเดียวคือบรรทัด package ด้านล่าง ให้ตรงกับบรรทัดแรกของ MainActivity.kt เดิมของคุณ
package com.example.photo_uploader_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "photo_uploader/usb_camera"
    private val permissionAction by lazy { "$packageName.USB_PERMISSION" }
    private var pendingResult: MethodChannel.Result? = null

    private val usbManager: UsbManager
        get() = getSystemService(Context.USB_SERVICE) as UsbManager

    // รับผลหลังผู้ใช้กดอนุญาต/ไม่อนุญาตสิทธิ์ USB
    private val permissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != permissionAction) return
            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            pendingResult?.success(granted)
            pendingResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val filter = IntentFilter(permissionAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(permissionReceiver, filter)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listDevices" -> result.success(listDevices())

                    "requestPermission" -> {
                        val name = call.argument<String>("deviceName")
                        val device = if (name != null) usbManager.deviceList[name] else null
                        if (device == null) {
                            result.error("NOT_FOUND", "ไม่พบอุปกรณ์ $name", null)
                        } else if (usbManager.hasPermission(device)) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            // Android 14 ต้องระบุ package และใช้ FLAG_MUTABLE
                            val intent = Intent(permissionAction).setPackage(packageName)
                            var flags = PendingIntent.FLAG_UPDATE_CURRENT
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                flags = flags or PendingIntent.FLAG_MUTABLE
                            }
                            val pi = PendingIntent.getBroadcast(this, 0, intent, flags)
                            usbManager.requestPermission(device, pi)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(permissionReceiver)
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    // คืนรายการอุปกรณ์ USB ทุกตัวที่โทรศัพท์เห็น พร้อมบอกว่าตัวไหนเป็นกล้อง
    private fun listDevices(): List<Map<String, Any>> =
        usbManager.deviceList.values.map { d ->
            val classes = (0 until d.interfaceCount).map { d.getInterface(it).interfaceClass }
            mapOf<String, Any>(
                "deviceName" to d.deviceName,
                "vendorId" to d.vendorId,
                "productId" to d.productId,
                "productName" to (d.productName ?: ""),
                "manufacturerName" to (d.manufacturerName ?: ""),
                "interfaceClasses" to classes,
                // class 6 = Still Image (PTP) ซึ่งเป็นโปรโตคอลของกล้องถ่ายภาพ
                "isCamera" to classes.contains(UsbConstants.USB_CLASS_STILL_IMAGE),
                "hasPermission" to usbManager.hasPermission(d)
            )
        }
}
