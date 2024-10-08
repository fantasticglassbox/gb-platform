package id.glassbox

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "wifi_channel"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "connectToWifi") {
                // Check for permission
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.CHANGE_WIFI_STATE) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.CHANGE_WIFI_STATE), PERMISSION_REQUEST_CODE)
                } else {
                    connectToWifiManager(call, result)
                }
            }else if(call.method == "getAndroidId"){
                val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                result.success(androidId)
            }
            else {
                result.notImplemented()
            }
        }
    }

    // Handle permission request result
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.i("Permission", "Wi-Fi permission granted.")
            } else {
                Log.e("Permission", "Wi-Fi permission denied.")
            }
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun connectToWifiManager(call: MethodCall, result: MethodChannel.Result) {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifiManager.isWifiEnabled) {
            wifiManager.isWifiEnabled = true
        }

        val ssid = call.argument<String>("ssid")
        val password = call.argument<String>("password")

        if (ssid != null && password != null) {
            connectToWifi(ssid, password, result)
        } else {
            result.error("INVALID_ARGUMENTS", "SSID or password is missing", null)
        }
    }

    private fun connectToWifi(ssid: String?, password: String?, result: MethodChannel.Result) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            // Android 10+ logic: Users need to manually connect via Wi-Fi settings
            openWifiSettings(result)
        } else {
            // Android < 10 logic
            connectToWifiForOlderVersions(ssid, password, result)
        }
    }

    private fun openWifiSettings(result: MethodChannel.Result) {
        Log.i("WifiConnection", "Android 10 and above: Opening Wi-Fi settings for manual connection.")
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
        startActivity(intent)
        result.success("Opened Wi-Fi settings")
    }

    private fun connectToWifiForOlderVersions(ssid: String?, password: String?, result: MethodChannel.Result) {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiConfig = WifiConfiguration().apply {
            SSID = "\"$ssid\""
            preSharedKey = "\"$password\""
        }

        val netId = wifiManager.addNetwork(wifiConfig)
        if (netId != -1) {
            wifiManager.disconnect()
            wifiManager.enableNetwork(netId, true)
            wifiManager.reconnect()
            Log.i("WifiConnection", "Connected to $ssid")
            result.success("Connected to $ssid")
        } else {
            Log.e("WifiConnection", "Unable to connect to $ssid")
            result.error("CONNECTION_FAILED", "Unable to connect to $ssid", null)
        }
    }
}
