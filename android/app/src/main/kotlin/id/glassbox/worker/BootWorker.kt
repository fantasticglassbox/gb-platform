package id.glassbox.worker
import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import android.content.Intent

class BootWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {

    override fun doWork(): Result {
        Log.d("BootWorker", "doWork called")
        val launchIntent = applicationContext.packageManager.getLaunchIntentForPackage(applicationContext.packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext.startActivity(launchIntent)
            Log.d("BootWorker", "MainActivity started")
            return Result.success()
        } else {
            Log.e("BootWorker", "Failed to get launch intent")
            return Result.failure()
        }
    }
}

