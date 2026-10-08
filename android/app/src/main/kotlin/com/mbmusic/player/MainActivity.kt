package com.mbmusic.player

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "com.mbmusic.player/delete"
    private val VIDEO_CHANNEL = "com.mbmusic.player/video"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingRenameResult: MethodChannel.Result? = null
    private var pendingRenameUri: Uri? = null
    private var pendingRenameName: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Media playback notification channels are created and configured by
        // audio_service. Do not create a second channel here with a different
        // ID/importance, otherwise Android can keep conflicting user settings.
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "renameVideo" -> {
                        val videoId = call.argument<String>("videoId")
                        val newName = call.argument<String>("newName")?.trim()
                        if (videoId.isNullOrBlank() || newName.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "videoId and newName are required", null)
                            return@setMethodCallHandler
                        }
                        renameVideo(videoId, newName, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun renameVideo(videoId: String, newName: String, result: MethodChannel.Result) {
        try {
            val id = videoId.toLong()
            val uri = ContentUris.withAppendedId(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                id
            )

            // Keep the original extension. Flutter sends only the filename
            // (for example "b"), so "b.mp4" stays an MP4 file.
            val currentName = contentResolver.query(
                uri,
                arrayOf(MediaStore.Video.Media.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }

            val extension = currentName
                ?.substringAfterLast('.', "")
                ?.takeIf { it.isNotEmpty() }

            val finalName = if (extension != null && !newName.contains('.')) {
                "$newName.$extension"
            } else {
                newName
            }

            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, finalName)
            }

            try {
                val updated = contentResolver.update(uri, values, null, null)
                if (updated > 0) {
                    result.success(true)
                } else {
                    result.error("RENAME_FAILED", "Video could not be renamed", null)
                }
            } catch (securityException: SecurityException) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    requestRenamePermission(uri, finalName, result)
                } else {
                    result.error("RENAME_PERMISSION", "Permission denied while renaming video", null)
                }
            }
        } catch (e: Exception) {
            result.error("RENAME_ERROR", e.message, null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun requestRenamePermission(
        uri: Uri,
        finalName: String,
        result: MethodChannel.Result,
    ) {
        try {
            pendingRenameResult = result
            pendingRenameUri = uri
            pendingRenameName = finalName

            val pendingIntent = MediaStore.createWriteRequest(
                contentResolver,
                listOf(uri)
            )

            startIntentSenderForResult(
                pendingIntent.intentSender,
                RENAME_REQUEST_CODE,
                null,
                0,
                0,
                0
            )
        } catch (e: Exception) {
            pendingRenameResult = null
            pendingRenameUri = null
            pendingRenameName = null
            result.error("RENAME_REQUEST_ERROR", e.message, null)
        }
    }

    private fun performPendingRename() {
        val result = pendingRenameResult ?: return
        val uri = pendingRenameUri
        val name = pendingRenameName

        pendingRenameResult = null
        pendingRenameUri = null
        pendingRenameName = null

        if (uri == null || name.isNullOrBlank()) {
            result.error("RENAME_ERROR", "Missing rename information", null)
            return
        }

        try {
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, name)
            }
            val updated = contentResolver.update(uri, values, null, null)
            if (updated > 0) {
                result.success(true)
            } else {
                result.error("RENAME_FAILED", "Video could not be renamed", null)
            }
        } catch (e: Exception) {
            result.error("RENAME_ERROR", e.message, null)
        }
    }

    private fun deleteSongs(songIds: List<Int>, result: MethodChannel.Result) {
        try {
            val contentResolver = contentResolver
            val uris = mutableListOf<Uri>()

            // Find MediaStore URIs for the song IDs.
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
                // Android 11+: use the system confirmation dialog.
                deleteWithMediaStoreRequest(uris, result)
            } else {
                // Android 10 and below: use ContentResolver directly.
                var deletedCount = 0
                for (uri in uris) {
                    try {
                        val rows = contentResolver.delete(uri, null, null)
                        if (rows > 0) deletedCount++
                    } catch (e: Exception) {
                        // Try file-based deletion as a fallback.
                        try {
                            val cursor = contentResolver.query(
                                uri,
                                arrayOf(MediaStore.Audio.Media.DATA),
                                null,
                                null,
                                null
                            )
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val path = it.getString(0)
                                    val file = java.io.File(path)
                                    if (file.exists() && file.delete()) {
                                        deletedCount++
                                        contentResolver.delete(uri, null, null)
                                    }
                                }
                            }
                        } catch (ex: Exception) {
                            // Ignore the fallback failure and continue.
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
                null,
                0,
                0,
                0
            )
        } catch (e: Exception) {
            pendingResult = null
            result.error("DELETE_REQUEST_ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            DELETE_REQUEST_CODE -> {
                val result = pendingResult
                pendingResult = null

                if (result != null) {
                    if (resultCode == Activity.RESULT_OK) {
                        result.success(mapOf("deleted" to true, "count" to -1))
                    } else {
                        result.success(mapOf("deleted" to false, "count" to 0))
                    }
                }
            }

            RENAME_REQUEST_CODE -> {
                val result = pendingRenameResult
                if (result != null) {
                    if (resultCode == Activity.RESULT_OK) {
                        performPendingRename()
                    } else {
                        pendingRenameResult = null
                        pendingRenameUri = null
                        pendingRenameName = null
                        result.success(false)
                    }
                }
            }
        }
    }

    companion object {
        private const val DELETE_REQUEST_CODE = 1001
        private const val RENAME_REQUEST_CODE = 1002
    }
}
