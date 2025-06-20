package com.example.screenshot_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "screenshot_channel"
    private val REQUEST_CODE_SCREENSHOT = 1000
    
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var methodResult: MethodChannel.Result? = null
    
    private var screenWidth = 0
    private var screenHeight = 0
    private var screenDensity = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configura o canal de comunicação com Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "takeScreenshot" -> {
                    methodResult = result
                    requestScreenshotPermission()
                }
                "checkPermission" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        initializeScreenshot()
    }

    private fun initializeScreenshot() {
        try {
            // Obtém o MediaProjectionManager
            mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            
            // Obtém as dimensões da tela
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val display = windowManager.defaultDisplay
            val metrics = DisplayMetrics()
            display.getMetrics(metrics)
            
            screenWidth = metrics.widthPixels
            screenHeight = metrics.heightPixels
            screenDensity = metrics.densityDpi
            
            Log.d("Screenshot", "Tela inicializada: ${screenWidth}x${screenHeight}, densidade: $screenDensity")
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao inicializar screenshot: ${e.message}")
        }
    }

    private fun requestScreenshotPermission() {
        try {
            mediaProjectionManager?.let { manager ->
                val intent = manager.createScreenCaptureIntent()
                startActivityForResult(intent, REQUEST_CODE_SCREENSHOT)
            } ?: run {
                methodResult?.error("ERROR", "MediaProjectionManager não disponível", null)
            }
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao solicitar permissão: ${e.message}")
            methodResult?.error("ERROR", "Erro ao solicitar permissão: ${e.message}", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE_SCREENSHOT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d("Screenshot", "Permissão concedida, iniciando captura")
                startScreenCapture(data)
            } else {
                Log.e("Screenshot", "Permissão negada pelo usuário")
                methodResult?.error("PERMISSION_DENIED", "Permissão para captura de tela negada", null)
            }
        }
    }

    private fun startScreenCapture(data: Intent) {
        try {
            // Cria o MediaProjection
            mediaProjection = mediaProjectionManager?.getMediaProjection(Activity.RESULT_OK, data)
            
            // Configura o ImageReader
            imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 1)
            
            // Configura o listener para quando a imagem estiver pronta
            imageReader?.setOnImageAvailableListener({
                try {
                    val image = imageReader?.acquireLatestImage()
                    image?.let { img ->
                        processImage(img)
                        img.close()
                    }
                } catch (e: Exception) {
                    Log.e("Screenshot", "Erro ao processar imagem: ${e.message}")
                    methodResult?.error("ERROR", "Erro ao processar imagem: ${e.message}", null)
                }
            }, Handler(Looper.getMainLooper()))
            
            // Cria o VirtualDisplay
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "Screenshot",
                screenWidth,
                screenHeight,
                screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                null
            )
            
            Log.d("Screenshot", "Captura iniciada")
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao iniciar captura: ${e.message}")
            methodResult?.error("ERROR", "Erro ao iniciar captura: ${e.message}", null)
        }
    }

    private fun processImage(image: Image) {
        try {
            Log.d("Screenshot", "Processando imagem...")
            
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * screenWidth
            
            // Cria bitmap
            val bitmap = Bitmap.createBitmap(
                screenWidth + rowPadding / pixelStride,
                screenHeight,
                Bitmap.Config.ARGB_8888
            )
            bitmap.copyPixelsFromBuffer(buffer)
            
            // Corta o bitmap para remover padding
            val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, screenWidth, screenHeight)
            
            // Salva a imagem
            saveImageToGallery(croppedBitmap)
            
            // Limpa recursos
            bitmap.recycle()
            croppedBitmap.recycle()
            cleanupScreenCapture()
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao processar imagem: ${e.message}")
            methodResult?.error("ERROR", "Erro ao processar imagem: ${e.message}", null)
            cleanupScreenCapture()
        }
    }

    private fun saveImageToGallery(bitmap: Bitmap) {
        try {
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val filename = "Screenshot_$timestamp.png"
            
            val saved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ - usa MediaStore
                saveImageMediaStore(bitmap, filename)
            } else {
                // Android 9 e anteriores - salva diretamente
                saveImageLegacy(bitmap, filename)
            }
            
            if (saved) {
                Log.d("Screenshot", "Imagem salva: $filename")
                methodResult?.success("success")
            } else {
                Log.e("Screenshot", "Falha ao salvar imagem")
                methodResult?.error("ERROR", "Falha ao salvar imagem", null)
            }
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao salvar: ${e.message}")
            methodResult?.error("ERROR", "Erro ao salvar: ${e.message}", null)
        }
    }

    private fun saveImageMediaStore(bitmap: Bitmap, filename: String): Boolean {
        return try {
            val resolver = contentResolver
            val contentValues = android.content.ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Screenshots")
            }
            
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            uri?.let { imageUri ->
                resolver.openOutputStream(imageUri)?.use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                }
                true
            } ?: false
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro MediaStore: ${e.message}")
            false
        }
    }

    private fun saveImageLegacy(bitmap: Bitmap, filename: String): Boolean {
        return try {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val screenshotsDir = File(picturesDir, "Screenshots")
            
            if (!screenshotsDir.exists()) {
                screenshotsDir.mkdirs()
            }
            
            val file = File(screenshotsDir, filename)
            FileOutputStream(file).use { outputStream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            }
            
            // Notifica a galeria sobre o novo arquivo
            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
            intent.data = Uri.fromFile(file)
            sendBroadcast(intent)
            
            true
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro legacy: ${e.message}")
            false
        }
    }

    private fun cleanupScreenCapture() {
        try {
            virtualDisplay?.release()
            virtualDisplay = null
            
            imageReader?.close()
            imageReader = null
            
            mediaProjection?.stop()
            mediaProjection = null
            
            Log.d("Screenshot", "Recursos liberados")
            
        } catch (e: Exception) {
            Log.e("Screenshot", "Erro ao limpar recursos: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupScreenCapture()
    }
}
