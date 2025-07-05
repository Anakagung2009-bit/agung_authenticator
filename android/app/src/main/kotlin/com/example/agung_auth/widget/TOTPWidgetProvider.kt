package com.example.agung_auth.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.Toast
import com.example.agung_auth.MainActivity
import com.example.agung_auth.R
import org.json.JSONArray
import java.security.InvalidKeyException
import java.security.NoSuchAlgorithmException
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.math.pow

class TOTPWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "TOTPWidget"
        private const val PREFS_NAME = "totp_widget_prefs"
        private const val KEY_TOTP_DATA = "totp_data"
        private const val ACTION_COPY_CODE = "com.example.agung_auth.COPY_CODE"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.totp_widget_layout)

            // Load TOTP data
            val totpData = loadTOTPData(context)
            val currentTime = System.currentTimeMillis() / 1000
            val timeLeft = 30 - (currentTime % 30).toInt()

            Log.d(TAG, "Loaded ${totpData.size} TOTP items")

            // Update timer
            views.setTextViewText(R.id.widget_timer, "${timeLeft}s")

            // Update TOTP items
            updateTOTPItems(views, totpData, currentTime)

            // Set click listeners
            setClickListeners(context, views)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget", e)
        }
    }

    private fun loadTOTPData(context: Context): List<TOTPData> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString(KEY_TOTP_DATA, "[]")
        val totpList = mutableListOf<TOTPData>()

        Log.d(TAG, "Raw JSON from SharedPreferences: $jsonString")

        try {
            val jsonArray = JSONArray(jsonString ?: "[]")
            Log.d(TAG, "JSON Array length: ${jsonArray.length()}")
            
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val name = jsonObject.getString("name")
                val secret = jsonObject.getString("secret")
                
                Log.d(TAG, "Loading TOTP: $name")
                
                totpList.add(TOTPData(name = name, secret = secret))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing TOTP data", e)
        }

        Log.d(TAG, "Final TOTP list size: ${totpList.size}")
        return totpList
    }

    private fun updateTOTPItems(views: RemoteViews, totpData: List<TOTPData>, currentTime: Long) {
        // Hide all items first
        views.setViewVisibility(R.id.totp_item_1, android.view.View.GONE)
        views.setViewVisibility(R.id.totp_item_2, android.view.View.GONE)
        views.setViewVisibility(R.id.totp_item_3, android.view.View.GONE)

        if (totpData.isEmpty()) {
            Log.d(TAG, "No TOTP data found, showing empty state")
            // Show empty state
            views.setTextViewText(R.id.totp_name_1, "No TOTP codes")
            views.setTextViewText(R.id.totp_code_1, "Add in app")
            views.setViewVisibility(R.id.totp_item_1, android.view.View.VISIBLE)
        } else {
            Log.d(TAG, "Showing ${totpData.size} TOTP items")
            // Show up to 3 items
            for (i in 0 until minOf(totpData.size, 3)) {
                val totp = totpData[i]
                val code = generateTOTP(totp.secret, currentTime)
                val formattedCode = "${code.substring(0, 3)} ${code.substring(3)}"

                Log.d(TAG, "Item $i: ${totp.name} = $formattedCode")

                when (i) {
                    0 -> {
                        views.setTextViewText(R.id.totp_name_1, totp.name)
                        views.setTextViewText(R.id.totp_code_1, formattedCode)
                        views.setViewVisibility(R.id.totp_item_1, android.view.View.VISIBLE)
                    }
                    1 -> {
                        views.setTextViewText(R.id.totp_name_2, totp.name)
                        views.setTextViewText(R.id.totp_code_2, formattedCode)
                        views.setViewVisibility(R.id.totp_item_2, android.view.View.VISIBLE)
                    }
                    2 -> {
                        views.setTextViewText(R.id.totp_name_3, totp.name)
                        views.setTextViewText(R.id.totp_code_3, formattedCode)
                        views.setViewVisibility(R.id.totp_item_3, android.view.View.VISIBLE)
                    }
                }
            }
        }
    }

    // ALGORITMA TOTP YANG BENAR - SAMA SEPERTI DI FLUTTER!
    private fun generateTOTP(secret: String, currentTime: Long, digits: Int = 6, period: Int = 30): String {
        return try {
            // Normalisasi secret seperti di Flutter
            var normalizedSecret = secret.uppercase()
            while (normalizedSecret.length % 8 != 0) {
                normalizedSecret += "=" // Tambahkan padding
            }

            // Decode Base32 secret
            val secretBytes = decodeBase32(normalizedSecret)

            // Hitung time counter
            val timeCounter = currentTime / period
            val timeBytes = int64ToBytes(timeCounter)

            // Generate HMAC-SHA1
            val mac = Mac.getInstance("HmacSHA1")
            val keySpec = SecretKeySpec(secretBytes, "HmacSHA1")
            mac.init(keySpec)
            val hash = mac.doFinal(timeBytes)

            // Dynamic truncation
            val offset = (hash.last().toInt() and 0xf).coerceAtMost(hash.size - 4)
            val binary = ((hash[offset].toInt() and 0x7f) shl 24) or
                        ((hash[offset + 1].toInt() and 0xff) shl 16) or
                        ((hash[offset + 2].toInt() and 0xff) shl 8) or
                        (hash[offset + 3].toInt() and 0xff)

            val otp = binary % 10.0.pow(digits).toInt()
            otp.toString().padStart(digits, '0')

        } catch (e: Exception) {
            Log.e(TAG, "Error generating TOTP for secret: $secret", e)
            "000000"
        }
    }

    // Base32 decoder - sama seperti algoritma di Flutter
    private fun decodeBase32(input: String): ByteArray {
        val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        val output = mutableListOf<Byte>()
        var buffer = 0
        var bitsLeft = 0

        for (char in input) {
            if (char == '=') break
            
            val value = alphabet.indexOf(char.uppercaseChar())
            if (value == -1) continue

            buffer = (buffer shl 5) or value
            bitsLeft += 5

            if (bitsLeft >= 8) {
                output.add((buffer shr (bitsLeft - 8)).toByte())
                bitsLeft -= 8
            }
        }

        return output.toByteArray()
    }

    // Konversi int64 ke bytes - sama seperti di Flutter
    private fun int64ToBytes(value: Long): ByteArray {
        val result = ByteArray(8)
        var temp = value
        for (i in 7 downTo 0) {
            result[i] = (temp and 0xff).toByte()
            temp = temp shr 8
        }
        return result
    }

    private fun setClickListeners(context: Context, views: RemoteViews) {
        // Open app intent
        val openAppIntent = Intent(context, MainActivity::class.java)
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_open_app, openAppPendingIntent)

        // Copy intents for each item
        for (i in 1..3) {
            val copyIntent = Intent(context, TOTPWidgetProvider::class.java).apply {
                action = ACTION_COPY_CODE
                putExtra("item_index", i - 1)
            }
            val copyPendingIntent = PendingIntent.getBroadcast(
                context, i, copyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val itemId = when (i) {
                1 -> R.id.totp_item_1
                2 -> R.id.totp_item_2
                3 -> R.id.totp_item_3
                else -> R.id.totp_item_1
            }
            views.setOnClickPendingIntent(itemId, copyPendingIntent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive: ${intent.action}")

        when (intent.action) {
            ACTION_COPY_CODE -> {
                val itemIndex = intent.getIntExtra("item_index", -1)
                copyCodeToClipboard(context, itemIndex)
            }
        }
    }

    private fun copyCodeToClipboard(context: Context, itemIndex: Int) {
        val totpData = loadTOTPData(context)
        if (itemIndex >= 0 && itemIndex < totpData.size) {
            val totp = totpData[itemIndex]
            val currentTime = System.currentTimeMillis() / 1000
            val code = generateTOTP(totp.secret, currentTime)

            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("TOTP Code", code)
            clipboard.setPrimaryClip(clip)

            Toast.makeText(context, "${totp.name}: $code copied!", Toast.LENGTH_SHORT).show()
        }
    }

    data class TOTPData(
        val name: String,
        val secret: String
    )
}
