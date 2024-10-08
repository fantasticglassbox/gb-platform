package id.glassbox

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi

object BatteryOptimizationHelper {
    @RequiresApi(Build.VERSION_CODES.M)
    fun requestIgnoreBatteryOptimizations(context: Context) {
        val intent = Intent()
        val packageName = context.packageName
        val pm = context.packageManager

        // Check if the app is already excluded from battery optimizations
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
            // Request to exclude app from battery optimizations
            intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            intent.data = Uri.parse("package:$packageName")
            if (intent.resolveActivity(pm) != null) {
                context.startActivity(intent)
            }
        }
    }
}
