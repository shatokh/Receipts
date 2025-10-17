package app.receipts

import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDDocumentNameDictionary
import com.tom_roush.pdfbox.pdmodel.common.PDNameTreeNode
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.pdmodel.common.filespecification.PDComplexFileSpecification
import com.tom_roush.pdfbox.pdmodel.common.filespecification.PDEmbeddedFile
import com.tom_roush.pdfbox.pdmodel.common.filespecification.PDFileSpecification
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationFileAttachment
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.security.MessageDigest
import java.text.Normalizer
import java.util.zip.GZIPInputStream
import java.util.zip.ZipInputStream
import kotlin.text.Charsets.UTF_8
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pdf_text_extractor"
    private val TAG = "ReceiptsPdfExtractor"

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
                        Log.e(TAG, "extractTextPages failed for $safUri", e)
                        result.error("EXTRACTION_ERROR", e.message, e.toString())
                    }
                }
                "pageCount" -> {
                    val safUri = call.arguments as String
                    try {
                        val count = getPageCount(safUri)
                        result.success(count)
                    } catch (e: Exception) {
                        Log.e(TAG, "pageCount failed for $safUri", e)
                        result.error("PAGE_COUNT_ERROR", e.message, e.toString())
                    }
                }
                "fileHash" -> {
                    val safUri = call.arguments as String
                    try {
                        val hash = getFileHash(safUri)
                        result.success(hash)
                    } catch (e: Exception) {
                        Log.e(TAG, "fileHash failed for $safUri", e)
                        result.error("HASH_ERROR", e.message, e.toString())
                    }
                }
                "readTextFile" -> {
                    val safUri = call.arguments as String
                    try {
                        val text = readTextFile(safUri)
                        result.success(text)
                    } catch (e: Exception) {
                        Log.e(TAG, "readTextFile failed for $safUri", e)
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
                extractEmbeddedReceipt(document)?.let { payload ->
                    return payload
                }

                val stripper = PDFTextStripper().apply {
                    sortByPosition = true
                }
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

    private fun extractEmbeddedReceipt(document: PDDocument): List<String>? {
        val nameDictionary: PDDocumentNameDictionary? = document.documentCatalog.names
        val embeddedTree = nameDictionary?.embeddedFiles
        extractFromEmbeddedTree(embeddedTree)?.let { return listOf(it) }

        // Some PDFs store attachments directly on pages as annotations.
        for (page in document.pages) {
            for (annotation in page.annotations) {
                if (annotation is PDAnnotationFileAttachment) {
                    decodeEmbeddedFile(annotation.file)?.let { return listOf(it) }
                }
            }
        }

        return null
    }

    private fun extractFromEmbeddedTree(
        node: PDNameTreeNode<PDComplexFileSpecification>?,
    ): String? {
        if (node == null) {
            return null
        }

        val names = node.names
        if (names != null) {
            for ((_, spec) in names) {
                decodeEmbeddedFile(spec)?.let { return it }
            }
        }

        val kids = node.kids
        if (kids != null) {
            for (child in kids) {
                extractFromEmbeddedTree(child)?.let { return it }
            }
        }

        return null
    }

    private fun decodeEmbeddedFile(spec: PDFileSpecification?): String? {
        val complexSpec = when (spec) {
            null -> return null
            is PDComplexFileSpecification -> spec
            else -> {
                Log.w(TAG, "Unsupported embedded file specification type: ${spec.javaClass.simpleName}")
                return null
            }
        }

        val embeddedFile: PDEmbeddedFile =
            complexSpec.embeddedFile ?: complexSpec.embeddedFileUnicode ?: return null

        return embeddedFile.createInputStream().use { stream ->
            val rawBytes = stream.readAllBytes()
            val decoded = decodeEmbeddedBytes(rawBytes, embeddedFile.subtype)
            val text = decoded.toString(UTF_8)
            val cleanedText = sanitizeEmbeddedText(text)

            if (cleanedText.isEmpty()) {
                Log.w(TAG, "Embedded receipt payload was empty")
                return@use null
            }

            val mimeType = embeddedFile.subtype
            val isJsonPayload = isJsonMimeType(mimeType) || isValidJson(cleanedText)

            if (isJsonPayload) cleanedText else null
        }
    }

    private fun decodeEmbeddedBytes(
        bytes: ByteArray,
        mimeType: String?
    ): ByteArray {
        val lowerMime = mimeType?.lowercase() ?: ""

        return when {
            isZipPayload(lowerMime, bytes) -> decodeZip(bytes)
            isGzipPayload(lowerMime, bytes) -> decodeGzip(bytes)
            else -> bytes
        }
    }

    private fun isZipPayload(mimeType: String, bytes: ByteArray): Boolean {
        if (mimeType.contains("zip")) {
            return true
        }

        return bytes.size > 4 &&
            bytes[0] == 0x50.toByte() &&
            bytes[1] == 0x4b.toByte() &&
            (bytes[2] == 0x03.toByte() || bytes[2] == 0x05.toByte())
    }

    private fun isGzipPayload(
        mimeType: String,
        bytes: ByteArray
    ): Boolean {
        if (mimeType.contains("gzip")) {
            return true
        }

        return bytes.size > 2 &&
            bytes[0] == 0x1f.toByte() &&
            bytes[1] == 0x8b.toByte()
    }

    private fun decodeZip(bytes: ByteArray): ByteArray {
        return try {
            ZipInputStream(ByteArrayInputStream(bytes)).use { zip ->
                var entry = zip.nextEntry
                while (entry != null) {
                    if (!entry.isDirectory) {
                        val name = entry.name.lowercase()
                        if (name.endsWith(".json") || name.endsWith(".txt")) {
                            return zip.readAllBytes()
                        }
                    }
                    entry = zip.nextEntry
                }
            }
            bytes
        } catch (_: Exception) {
            bytes
        }
    }

    private fun decodeGzip(bytes: ByteArray): ByteArray {
        return try {
            GZIPInputStream(ByteArrayInputStream(bytes)).use { it.readAllBytes() }
        } catch (_: Exception) {
            bytes
        }
    }

    private fun sanitizeEmbeddedText(text: String): String {
        val trimmed = text.trim()
        return if (trimmed.startsWith("\uFEFF")) {
            trimmed.removePrefix("\uFEFF").trimStart()
        } else {
            trimmed
        }
    }

    private fun isJsonMimeType(mimeType: String?): Boolean {
        val lowerMime = mimeType?.lowercase() ?: return false
        return lowerMime.contains("json")
    }

    private fun isValidJson(text: String): Boolean {
        if (text.isEmpty()) {
            return false
        }

        val firstChar = text.first()
        return try {
            when (firstChar) {
                '{' -> JSONObject(text)
                '[' -> JSONArray(text)
                else -> return false
            }
            true
        } catch (_: JSONException) {
            false
        }
    }

    private fun InputStream.readAllBytes(): ByteArray {
        val buffer = ByteArrayOutputStream()
        val chunk = ByteArray(8192)
        var read: Int
        while (this.read(chunk).also { read = it } != -1) {
            buffer.write(chunk, 0, read)
        }
        return buffer.toByteArray()
    }
}
