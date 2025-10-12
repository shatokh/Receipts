package app.receipts

import android.content.Context
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import java.io.InputStream
import java.security.MessageDigest
import java.text.Normalizer
import kotlin.text.Charsets.UTF_8

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pdf_text_extractor"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize PDFBox
        PDFBoxResourceLoader.init(applicationContext)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractTextPages" -> {
                    val safUri = call.arguments as String
                    try {
                        val pages = extractTextPages(safUri)
                        result.success(pages)
                    } catch (e: Exception) {
                        result.error("EXTRACTION_ERROR", e.message, e.toString())
                    }
                }
                "pageCount" -> {
                    val safUri = call.arguments as String
                    try {
                        val count = getPageCount(safUri)
                        result.success(count)
                    } catch (e: Exception) {
                        result.error("PAGE_COUNT_ERROR", e.message, e.toString())
                    }
                }
                "fileHash" -> {
                    val safUri = call.arguments as String
                    try {
                        val hash = getFileHash(safUri)
                        result.success(hash)
                    } catch (e: Exception) {
                        result.error("HASH_ERROR", e.message, e.toString())
                    }
                }
                "readTextFile" -> {
                    val safUri = call.arguments as String
                    try {
                        val text = readTextFile(safUri)
                        result.success(text)
                    } catch (e: Exception) {
                        result.error("READ_TEXT_ERROR", e.message, e.toString())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractTextPages(safUri: String): List<String> {
        val uri = Uri.parse(safUri)
        val inputStream: InputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open file")
        
        return inputStream.use { stream ->
            PDDocument.load(stream).use { document ->
                val stripper = PDFTextStripper()
                val pages = mutableListOf<String>()
                
                for (i in 1..document.numberOfPages) {
                    stripper.startPage = i
                    stripper.endPage = i
                    var text = stripper.getText(document)
                    
                    // Normalize Unicode to NFC form
                    text = Normalizer.normalize(text, Normalizer.Form.NFC)
                    
                    pages.add(text)
                }
                pages
            }
        }
    }

    private fun getPageCount(safUri: String): Int {
        val uri = Uri.parse(safUri)
        val inputStream: InputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open file")
        
        return inputStream.use { stream ->
            PDDocument.load(stream).use { document ->
                document.numberOfPages
            }
        }
    }

    private fun getFileHash(safUri: String): String {
        val uri = Uri.parse(safUri)
        val inputStream: InputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open file")

        return inputStream.use { stream ->
            val digest = MessageDigest.getInstance("SHA-256")
            val buffer = ByteArray(8192)
            var bytesRead: Int

            while (stream.read(buffer).also { bytesRead = it } != -1) {
                digest.update(buffer, 0, bytesRead)
            }

            digest.digest().joinToString("") { "%02x".format(it) }
        }
    }

    private fun readTextFile(safUri: String): String {
        val uri = Uri.parse(safUri)
        val inputStream: InputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open file")

        return inputStream.bufferedReader(UTF_8).use { it.readText() }
    }
}
