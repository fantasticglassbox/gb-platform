package id.glassbox.receiver
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import id.glassbox.worker.BootWorker
class BootReceiver : BroadcastReceiver() {

  override fun onReceive(context: Context, intent: Intent) {
    Log.d("BootReceiver", "onReceive called")
    if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
      Log.d("BootReceiver", "Boot completed received in app")
      val workRequest = OneTimeWorkRequestBuilder<BootWorker>().build()
      WorkManager.getInstance(context).enqueue(workRequest)
    } else {
      Log.d("BootReceiver", "Received unknown action: ${intent.action}")
    }
  }
}
