package com.example.cyberguard

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.telephony.TelephonyManager
import android.annotation.SuppressLint

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.cyberguard/device_info"
    private val PERMISSION_REQUEST_CODE = 1001
    private val REQUIRED_PERMISSIONS = mutableListOf(
        Manifest.permission.CAMERA,
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
        Manifest.permission.INTERNET,
        Manifest.permission.ACCESS_NETWORK_STATE
    ).apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            add(Manifest.permission.READ_MEDIA_IMAGES)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            add(Manifest.permission.READ_PHONE_STATE)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPermissions()
    }

    private fun requestPermissions() {
        val permissionsToRequest = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            // Permissions handled, Flutter will start
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceId" -> {
                    val deviceId = getDeviceId()
                    if (deviceId != null) {
                        result.success(deviceId)
                    } else {
                        result.error("UNAVAILABLE", "Device ID not available.", null)
                    }
                }
                "getImei" -> {
                    val imei = getImei()
                    if (imei != null) {
                        result.success(imei)
                    } else {
                        result.error("UNAVAILABLE", "IMEI not available.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("HardwareIds")
    private fun getDeviceId(): String? {
        return try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
        } catch (e: Exception) {
            null
        }
    }

    @SuppressLint("HardwareIds", "MissingPermission")
    private fun getImei(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // For Android 10+, IMEI is restricted
                Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
            } else {
                val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) 
                    == PackageManager.PERMISSION_GRANTED) {
                    telephonyManager.imei
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }
}