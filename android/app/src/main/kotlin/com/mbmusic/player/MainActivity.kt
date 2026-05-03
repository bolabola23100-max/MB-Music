package com.mbmusic.player

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "com.example.music/delete"
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ إنشاء Notification Channel للأندرويد 8+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "com.music.app.channel.audio",
                "Music Playback",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Music player controls"
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deleteSongs" -> {
                        val songIds = call.argument<List<Int>>("songIds")
                        if (songIds == null || songIds.isEmpty()) {
                            result.error("INVALID_ARGS", "songIds is required", null)
                            return@setMethodCallHandler
                        }
                        deleteSongs(songIds, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun deleteSongs(songIds: List<Int>, result: MethodChannel.Result) {
        try {
            val contentResolver = contentResolver
            val uris = mutableListOf<Uri>()

            // ✅ Find MediaStore URIs for the song IDs
            for (songId in songIds) {
                val uri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    songId.toLong()
                )
                uris.add(uri)
            }

            if (uris.isEmpty()) {
                result.success(mapOf("deleted" to true, "count" to 0))
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // ✅ Android 11+ : Use createDeleteRequest (shows system dialog)
                deleteWithMediaStoreRequest(uris, result)
            } else {
                // ✅ Android 10 and below : Use ContentResolver.delete directly
                var deletedCount = 0
                for (uri in uris) {
                    try {
                        val rows = contentResolver.delete(uri, null, null)
                        if (rows > 0) deletedCount++
                    } catch (e: Exception) {
                        // Try file-based deletion as fallback
                        try {
                            val cursor = contentResolver.query(
                                uri, arrayOf(MediaStore.Audio.Media.DATA),
                                null, null, null
                            )
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val path = it.getString(0)
                                    val file = java.io.File(path)
                                    if (file.exists() && file.delete()) {
                                        deletedCount++
                                        // Also remove from MediaStore
                                        contentResolver.delete(uri, null, null)
                                    }
                                }
                            }
                        } catch (ex: Exception) {
                            // ignore
                        }
                    }
                }
                result.success(mapOf("deleted" to true, "count" to deletedCount))
            }
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun deleteWithMediaStoreRequest(uris: List<Uri>, result: MethodChannel.Result) {
        try {
            pendingResult = result
            val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
            startIntentSenderForResult(
                pendingIntent.intentSender,
                DELETE_REQUEST_CODE,
                null, 0, 0, 0
            )
        } catch (e: Exception) {
            pendingResult = null
            result.error("DELETE_REQUEST_ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == DELETE_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null

            if (result != null) {
                if (resultCode == Activity.RESULT_OK) {
                    result.success(mapOf("deleted" to true, "count" to -1))
                } else {
                    // User canceled the delete request
                    result.success(mapOf("deleted" to false, "count" to 0))
                }
            }
        }
    }

    companion object {
        private const val DELETE_REQUEST_CODE = 1001
    }
}