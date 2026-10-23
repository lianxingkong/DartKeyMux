package com.example.flutter_application_1

import android.os.SystemClock
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// 延迟测量探针（测完回滚为本来的 `class MainActivity : FlutterActivity()`）
///
/// 目的：拿到触摸事件的**内核时间戳** `MotionEvent.eventTime`。
/// 它比 Flutter 侧回调更接近"手指真正按下"的瞬间，用作端到端延迟测量的起点。
///
/// 时钟说明：
///   nativeTimeMs / uptimeMs 属于 `SystemClock.uptimeMillis()`（开机后单调时钟）
///   wallTimeMs 是同一时刻的墙钟，用于把 nativeTimeMs 换算到墙钟域
///   deltaMs = uptime - eventTime，即"内核收到事件 → 分发到 Activity"已过去的毫秒数
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        val nativeTimeMs = ev.eventTime                            // 内核触摸时间（uptimeMillis 域）
        val uptimeMs = SystemClock.uptimeMillis()
        try {
            channel?.invokeMethod("touch", mapOf(
                "nativeTimeMs" to nativeTimeMs,
                "uptimeMs" to uptimeMs,
                "wallTimeMs" to System.currentTimeMillis(),
                "deltaMs" to (uptimeMs - nativeTimeMs)
            ))
        } catch (_: Throwable) {
            // 测量探针绝不能影响正常触摸流程
        }
        return super.dispatchTouchEvent(ev)
    }

    private companion object {
        const val CHANNEL = "dkm_latency"
    }
}
