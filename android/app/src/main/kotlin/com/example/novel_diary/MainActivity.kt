package com.example.novel_diary

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourapp.screentime"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (hasUsageStatsPermission()) {
                        result.success(true)
                    } else {
                        // 사용 통계 권한 설정 화면으로 이동
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(false)
                    }
                }
                "checkPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "getTodayScreenTime" -> {
                    if (hasUsageStatsPermission()) {
                        val todayStats = getTodayUsageStats()
                        result.success(todayStats)
                    } else {
                        result.error("NO_PERMISSION", "Usage stats permission not granted", null)
                    }
                }
                "isScreenTimeAvailable" -> {
                    // Android API 21(Lollipop) 이상에서만 지원
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 사용 통계 권한 확인
     */
    private fun hasUsageStatsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false
        }

        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * 오늘의 앱 사용 통계 가져오기
     */
    private fun getTodayUsageStats(): String {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // 오늘 00:00부터 현재까지
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        // JSON 형식으로 변환
        val jsonObject = JSONObject()
        val appsArray = JSONArray()
        var totalScreenTime = 0L

        usageStatsList.filter { it.totalTimeInForeground > 0 }
            .sortedByDescending { it.totalTimeInForeground }
            .take(20) // 상위 20개 앱만
            .forEach { stats ->
                val appJson = JSONObject()
                appJson.put("packageName", stats.packageName)
                appJson.put("appName", getAppName(stats.packageName))
                appJson.put("usageTime", stats.totalTimeInForeground / 1000) // 초 단위
                appJson.put("lastTimeUsed", stats.lastTimeUsed)
                appsArray.put(appJson)
                totalScreenTime += stats.totalTimeInForeground
            }

        jsonObject.put("date", Date().time)
        jsonObject.put("totalScreenTime", totalScreenTime / 1000) // 초 단위
        jsonObject.put("appUsageList", appsArray)

        return jsonObject.toString()
    }

    /**
     * 패키지명으로 앱 이름 가져오기
     */
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
}
