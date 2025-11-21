package com.example.music_app

import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.music_app/ringtone"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingtone" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "Ringtone"
                    
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val ringtoneResult = setRingtone(filePath, title)
                        if (ringtoneResult.first) {
                            // Return a map with success status and whether it was set as default
                            result.success(mapOf(
                                "success" to true,
                                "setAsDefault" to ringtoneResult.second,
                                "needsPermission" to ringtoneResult.third
                            ))
                        } else {
                            result.error("SET_RINGTONE_FAILED", "Failed to set ringtone", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXCEPTION", e.message, null)
                    }
                }
                "checkWriteSettingsPermission" -> {
                    val canWrite = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.System.canWrite(this)
                    } else {
                        true
                    }
                    result.success(canWrite)
                }
                "openWriteSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Returns Triple<success, setAsDefault, needsPermission>
    private fun setRingtone(filePath: String, title: String): Triple<Boolean, Boolean, Boolean> {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                return Triple(false, false, false)
            }

            val extension = file.extension.ifEmpty { "mp3" }
            val sanitizedBaseName = sanitizeFileName(title.ifBlank { "ringtone" })
            val displayName = if (sanitizedBaseName.endsWith(".${extension.lowercase()}")) {
                sanitizedBaseName
            } else {
                "$sanitizedBaseName.$extension"
            }

            // Remove any previously saved ringtone with the same name to avoid duplicates
            deleteExistingRingtone(displayName)

            val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ (API 29+): Use MediaStore API
                val contentValues = ContentValues().apply {
                    put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
                    put(MediaStore.Audio.Media.MIME_TYPE, getMimeType(file))
                    put(MediaStore.Audio.Media.IS_RINGTONE, true)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, false)
                    put(MediaStore.Audio.Media.IS_ALARM, false)
                    put(MediaStore.Audio.Media.IS_MUSIC, false)
                    put(MediaStore.Audio.Media.RELATIVE_PATH, "Ringtones")
                }

                val insertedUri = contentResolver.insert(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    contentValues
                )

                // Copy file content to MediaStore
                insertedUri?.let {
                    contentResolver.openOutputStream(it)?.use { output ->
                        FileInputStream(file).use { input ->
                            input.copyTo(output)
                        }
                    }
                }

                insertedUri
            } else {
                // Android 9 and below: Use traditional file system
                @Suppress("DEPRECATION")
                val ringtonesDir = File(
                    android.os.Environment.getExternalStoragePublicDirectory(
                        android.os.Environment.DIRECTORY_RINGTONES
                    ),
                    ""
                )
                if (!ringtonesDir.exists()) {
                    ringtonesDir.mkdirs()
                }

                val ringtoneFile = File(ringtonesDir, displayName)

                FileInputStream(file).use { input ->
                    FileOutputStream(ringtoneFile).use { output ->
                        input.copyTo(output)
                    }
                }

                // Scan the file so it appears in MediaStore
                val mediaScanIntent = android.content.Intent(android.content.Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = Uri.fromFile(ringtoneFile)
                sendBroadcast(mediaScanIntent)

                Uri.fromFile(ringtoneFile)
            }

            if (uri != null) {
                // For Android 10+, we might need to wait a moment for MediaStore to index
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        Thread.sleep(500) // Give MediaStore time to index
                    } catch (e: InterruptedException) {
                        // Ignore
                    }
                }

                var setAsDefault = false
                var needsPermission = false

                // Try to set as default ringtone
                // On Android 6.0+, this requires WRITE_SETTINGS permission
                try {
                    // Check permission first (Android 6.0+)
                    val canWrite = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.System.canWrite(this)
                    } else {
                        @Suppress("DEPRECATION")
                        true
                    }

                    if (canWrite || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                        // We have permission or it's an older Android version
                        RingtoneManager.setActualDefaultRingtoneUri(
                            this,
                            RingtoneManager.TYPE_RINGTONE,
                            uri
                        )
                        setAsDefault = true
                    } else {
                        // Try anyway - some devices might allow it
                        try {
                            RingtoneManager.setActualDefaultRingtoneUri(
                                this,
                                RingtoneManager.TYPE_RINGTONE,
                                uri
                            )
                            setAsDefault = true
                        } catch (e: SecurityException) {
                            needsPermission = true
                        }
                    }
                } catch (e: SecurityException) {
                    needsPermission = true
                } catch (e: Exception) {
                    // Other exceptions - might be a different issue
                    e.printStackTrace()
                    needsPermission = true
                }

                Triple(true, setAsDefault, needsPermission)
            } else {
                Triple(false, false, false)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Triple(false, false, false)
        }
    }

    private fun getMimeType(file: File): String {
        val extension = file.extension.lowercase()
        return when (extension) {
            "mp3" -> "audio/mpeg"
            "m4a", "aac" -> "audio/mp4"
            "ogg" -> "audio/ogg"
            "wav" -> "audio/wav"
            else -> "audio/*"
        }
    }

    private fun sanitizeFileName(name: String): String {
        return name.replace(Regex("[\\\\/:*?\"<>|]"), "_").replace(Regex("\\s+"), " ").trim()
    }

    private fun deleteExistingRingtone(displayName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val selection = "${MediaStore.Audio.Media.DISPLAY_NAME} = ? AND ${MediaStore.Audio.Media.IS_RINGTONE} = 1"
            val selectionArgs = arrayOf(displayName)
            contentResolver.delete(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, selection, selectionArgs)
        } else {
            @Suppress("DEPRECATION")
            val ringtonesDir = File(
                android.os.Environment.getExternalStoragePublicDirectory(
                    android.os.Environment.DIRECTORY_RINGTONES
                ),
                ""
            )
            if (ringtonesDir.exists()) {
                val targetFile = File(ringtonesDir, displayName)
                if (targetFile.exists()) {
                    targetFile.delete()
                }
            }
        }
    }
}
