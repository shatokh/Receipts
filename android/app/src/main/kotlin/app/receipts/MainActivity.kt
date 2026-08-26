package app.receipts

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
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
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream
import java.security.MessageDigest
import java.text.Normalizer
import java.util.Locale
import java.util.zip.GZIPInputStream
import java.util.zip.ZipInputStream
import kotlin.math.max
import kotlin.text.Charsets.UTF_8
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pdf_text_extractor"
    private val RECEIPT_SOURCE_OPENER_CHANNEL = "receipt_source_opener"
    private val TAG = "ReceiptsPdfExtractor"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val backgroundExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize PDFBox
        PDFBoxResourceLoader.init(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractTextPages" -> {
                    val safUri = call.arguments as String
                    backgroundExecutor.execute {
                        try {
                            val pages = extractTextPages(safUri)
                            mainHandler.post { result.success(pages) }
                        } catch (e: Exception) {
                            Log.e(TAG, "extractTextPages failed for redacted source", e)
                            mainHandler.post {
                                if (e is EmptyPdfTextException) {
                                    result.error(
                                        "EMPTY_PDF_TEXT",
                                        e.message,
                                        e.stages,
                                    )
                                } else {
                                    result.error("EXTRACTION_ERROR", e.message, e.toString())
                                }
                            }
                        }
                    }
                }
                "pageCount" -> {
                    val safUri = call.arguments as String
                    backgroundExecutor.execute {
                        try {
                            val count = getPageCount(safUri)
                            mainHandler.post { result.success(count) }
                        } catch (e: Exception) {
                            Log.e(TAG, "pageCount failed for redacted source", e)
                            mainHandler.post {
                                result.error("PAGE_COUNT_ERROR", e.message, e.toString())
                            }
                        }
                    }
                }
                "fileHash" -> {
                    val safUri = call.arguments as String
                    backgroundExecutor.execute {
                        try {
                            val hash = getFileHash(safUri)
                            mainHandler.post { result.success(hash) }
                        } catch (e: Exception) {
                            Log.e(TAG, "fileHash failed for redacted source", e)
                            mainHandler.post {
                                result.error("HASH_ERROR", e.message, e.toString())
                            }
                        }
                    }
                }
                "readTextFile" -> {
                    val safUri = call.arguments as String
                    backgroundExecutor.execute {
                        try {
                            val text = readTextFile(safUri)
                            mainHandler.post { result.success(text) }
                        } catch (e: Exception) {
                            Log.e(TAG, "readTextFile failed for redacted source", e)
                            mainHandler.post {
                                result.error("READ_TEXT_ERROR", e.message, e.toString())
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECEIPT_SOURCE_OPENER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> {
                    val sourceUri = call.arguments as? String
                    if (sourceUri.isNullOrBlank()) {
                        result.error("OPEN_SOURCE_ERROR", "Unable to open source file.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        openReceiptSource(sourceUri)
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("OPEN_SOURCE_ERROR", "Unable to open source file.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openReceiptSource(source: String) {
        val uri = toShareableUri(source)
        val mimeType = contentResolver.getType(uri) ?: "application/pdf"
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, mimeType)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        if (intent.resolveActivity(packageManager) == null) {
            throw ActivityNotFoundException()
        }
        startActivity(Intent.createChooser(intent, null))
    }

    private fun toShareableUri(source: String): Uri {
        val parsed = Uri.parse(source)
        if (parsed.scheme == "content") {
            return parsed
        }

        val file = when (parsed.scheme) {
            "file" -> File(requireNotNull(parsed.path))
            else -> File(source)
        }
        return FileProvider.getUriForFile(
            this,
            "$packageName.receipt-source-provider",
            file,
        )
    }

    private fun extractTextPages(safUri: String): List<String> {
        val uri = Uri.parse(safUri)
        val inputStream: InputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open file")

        return inputStream.use { stream ->
            PDDocument.load(stream).use { document ->
                val embeddedResult = extractEmbeddedReceipt(document)
                logExtractionStage(safUri, "embedded", embeddedResult.status)
                embeddedResult.value?.let { payload ->
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

                val stripperStatus = if (hasMeaningfulText(pages)) {
                    StageStatus.SUCCESS
                } else {
                    StageStatus.EMPTY
                }
                logExtractionStage(safUri, "stripper", stripperStatus)

                if (stripperStatus == StageStatus.SUCCESS) {
                    return pages
                }

                val ocrResult = extractTextWithOcr(uri)
                logExtractionStage(safUri, "ocr", ocrResult.status)
                if (hasMeaningfulText(ocrResult.value ?: emptyList())) {
                    Log.i(TAG, "Falling back to OCR text extraction for redacted source")
                    return ocrResult.value ?: pages
                }

                val stages = mapOf(
                    "embedded" to embeddedResult.status.value,
                    "stripper" to stripperStatus.value,
                    "ocr" to ocrResult.status.value,
                )

                throw EmptyPdfTextException(stages)
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

    private fun extractEmbeddedReceipt(document: PDDocument): StageResult<List<String>> {
        val nameDictionary: PDDocumentNameDictionary? = document.documentCatalog.names
        val embeddedTree = nameDictionary?.embeddedFiles
        val treeResult = extractFromEmbeddedTree(embeddedTree)
        treeResult.value?.let { payload ->
            return StageResult(listOf(payload), StageStatus.SUCCESS)
        }

        var status = treeResult.status

        // Some PDFs store attachments directly on pages as annotations.
        for (page in document.pages) {
            for (annotation in page.annotations) {
                if (annotation is PDAnnotationFileAttachment) {
                    val attachmentResult = decodeEmbeddedFile(annotation.file)
                    status = dominantStatus(status, attachmentResult.status)
                    attachmentResult.value?.let { payload ->
                        return StageResult(listOf(payload), StageStatus.SUCCESS)
                    }
                }
            }
        }

        return StageResult(null, status)
    }

    private fun extractTextWithOcr(uri: Uri): StageResult<List<String>> {
        return try {
            contentResolver.openFileDescriptor(uri, "r")?.use { descriptor ->
                PdfRenderer(descriptor).use { renderer ->
                    if (renderer.pageCount == 0) {
                        return StageResult(emptyList(), StageStatus.EMPTY)
                    }

                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    try {
                        val pages = mutableListOf<String>()
                        var status = StageStatus.EMPTY

                        for (i in 0 until renderer.pageCount) {
                            renderer.openPage(i).use { page ->
                                val primaryScale = computeOcrScale(page.width, page.height)
                                val primaryText = runOcrPass(page, recognizer, primaryScale, applyBinarization = false)

                                val normalizedPrimary = Normalizer.normalize(primaryText, Normalizer.Form.NFC)

                                val finalText = if (normalizedPrimary.isNotBlank()) {
                                    normalizedPrimary
                                } else {
                                    val enhancedScale = (primaryScale * 1.35f).coerceAtMost(3.5f)
                                    val secondaryText = runOcrPass(
                                        page,
                                        recognizer,
                                        enhancedScale,
                                        applyBinarization = true,
                                    )
                                    Normalizer.normalize(secondaryText, Normalizer.Form.NFC)
                                }

                                if (finalText.any { !it.isWhitespace() }) {
                                    status = StageStatus.SUCCESS
                                }

                                pages.add(finalText)
                            }
                        }

                        StageResult(pages, status)
                    } finally {
                        recognizer.close()
                    }
                }
            } ?: StageResult(emptyList(), StageStatus.EMPTY)
        } catch (e: Exception) {
            Log.e(TAG, "OCR fallback failed for redacted source", e)
            StageResult(emptyList(), StageStatus.ERROR)
        }
    }

    private fun runOcrPass(
        page: PdfRenderer.Page,
        recognizer: com.google.mlkit.vision.text.TextRecognizer,
        scale: Float,
        applyBinarization: Boolean,
    ): String {
        val width = (page.width * scale).toInt().coerceAtLeast(1)
        val height = (page.height * scale).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        return try {
            bitmap.eraseColor(Color.WHITE)
            val matrix = Matrix().apply { postScale(scale, scale) }
            page.render(bitmap, null, matrix, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

            if (applyBinarization) {
                binarizeBitmap(bitmap)
            }

            val image = InputImage.fromBitmap(bitmap, 0)
            val result = Tasks.await(recognizer.process(image))
            result.text
        } finally {
            bitmap.recycle()
        }
    }

    private fun binarizeBitmap(bitmap: Bitmap) {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        for (index in pixels.indices) {
            val color = pixels[index]
            val red = Color.red(color)
            val green = Color.green(color)
            val blue = Color.blue(color)
            val luminance = (0.299 * red + 0.587 * green + 0.114 * blue).toInt()
            pixels[index] = if (luminance > 180) Color.WHITE else Color.BLACK
        }

        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
    }

    private fun computeOcrScale(width: Int, height: Int): Float {
        val maxDimension = 2000f
        val largestSide = max(width, height).toFloat()
        val scaleToMax = maxDimension / largestSide
        val normalizedScale = if (largestSide > maxDimension) {
            scaleToMax
        } else {
            scaleToMax.coerceAtMost(2.5f)
        }
        return normalizedScale
    }

    private fun hasMeaningfulText(pages: List<String>): Boolean {
        for (page in pages) {
            if (page.any { !it.isWhitespace() }) {
                return true
            }
        }
        return false
    }

    private fun logExtractionStage(safUri: String, stage: String, status: StageStatus) {
        Log.d(TAG, "Extraction stage $stage=${status.value} for redacted source")
    }

    private fun extractFromEmbeddedTree(
        node: PDNameTreeNode<PDComplexFileSpecification>?,
    ): StageResult<String> {
        if (node == null) {
            return StageResult(null, StageStatus.ABSENT)
        }

        var status = StageStatus.ABSENT

        val names = node.names
        if (names != null) {
            for ((_, spec) in names) {
                val result = decodeEmbeddedFile(spec)
                status = dominantStatus(status, result.status)
                result.value?.let { return StageResult(it, StageStatus.SUCCESS) }
            }
        }

        val kids = node.kids
        if (kids != null) {
            for (child in kids) {
                val result = extractFromEmbeddedTree(child)
                status = dominantStatus(status, result.status)
                result.value?.let { return result }
            }
        }

        return StageResult(null, status)
    }

    private fun decodeEmbeddedFile(spec: PDFileSpecification?): StageResult<String> {
        val complexSpec = when (spec) {
            null -> return StageResult(null, StageStatus.ABSENT)
            is PDComplexFileSpecification -> spec
            else -> {
                Log.w(TAG, "Unsupported embedded file specification type: ${spec.javaClass.simpleName}")
                return StageResult(null, StageStatus.INVALID)
            }
        }

        val embeddedFile: PDEmbeddedFile = complexSpec.embeddedFile
            ?: complexSpec.embeddedFileUnicode
            ?: return StageResult(null, StageStatus.EMPTY)

        val attachmentName = listOfNotNull(
            complexSpec.file,
            complexSpec.fileUnicode,
            embeddedFile.subtype,
        ).firstOrNull().orEmpty()

        return embeddedFile.createInputStream().use { stream ->
            val rawBytes = stream.readAllBytes()
            if (rawBytes.isNotEmpty()) {
                dumpAttachment("${attachmentName}_raw", rawBytes)
            }

            val decoded = decodeEmbeddedBytes(rawBytes, embeddedFile.subtype, attachmentName)
            if (decoded.isNotEmpty()) {
                dumpAttachment("${attachmentName}_decoded", decoded)
            }

            val text = decoded.toString(UTF_8)
            val cleanedText = sanitizeEmbeddedText(text)

            if (cleanedText.isEmpty()) {
                Log.w(TAG, "Embedded receipt payload was empty")
                return@use StageResult(null, StageStatus.EMPTY)
            }

            val mimeType = embeddedFile.subtype
            val isJsonPayload = isJsonMimeType(mimeType) || isValidJson(cleanedText)

            if (isJsonPayload) {
                Log.i(TAG, "Embedded receipt payload decoded from redacted attachment")
                StageResult(cleanedText, StageStatus.SUCCESS)
            } else {
                Log.w(TAG, "Embedded receipt payload was not JSON")
                StageResult(null, StageStatus.INVALID)
            }
        }
    }

    private fun decodeEmbeddedBytes(
        bytes: ByteArray,
        mimeType: String?,
        sourceName: String,
    ): ByteArray {
        val lowerMime = mimeType?.lowercase(Locale.ROOT) ?: ""

        var decoded = when {
            isZipPayload(lowerMime, bytes) -> decodeZip(bytes, sourceName)
            isGzipPayload(lowerMime, bytes) -> decodeGzip(bytes)
            else -> bytes
        }

        decoded = decodeNestedContainers(decoded, sourceName)

        return decoded
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

    private fun decodeZip(bytes: ByteArray, sourceName: String? = null): ByteArray {
        return try {
            ZipInputStream(ByteArrayInputStream(bytes)).use { zip ->
                var entry = zip.nextEntry
                while (entry != null) {
                    if (!entry.isDirectory) {
                        val entryName = entry.name ?: "unnamed"
                        val entryBytes = zip.readEntryBytes()
                        val combinedName = listOfNotNull(sourceName, entryName).joinToString("_")
                        if (entryBytes.isNotEmpty()) {
                            dumpAttachment("${combinedName}_entry", entryBytes)
                        }

                        val candidate = decodeNestedContainers(entryBytes, entryName)
                        val text = sanitizeEmbeddedText(candidate.toString(UTF_8))
                        if (isValidJson(text)) {
                            Log.i(TAG, "Decoded JSON from zip entry with redacted name")
                            return candidate
                        }
                    }
                    entry = zip.nextEntry
                }
            }
            bytes
        } catch (e: Exception) {
            Log.w(TAG, "Failed to decode zip payload with redacted name", e)
            bytes
        }
    }

    private fun decodeNestedContainers(bytes: ByteArray, sourceName: String): ByteArray {
        var current = bytes
        var iteration = 0

        while (iteration < 3) {
            iteration += 1
            when {
                isZipPayload("", current) -> {
                    val decoded = decodeZip(current, sourceName)
                    if (!decoded.contentEquals(current)) {
                        current = decoded
                        continue
                    }
                }
                isGzipPayload("", current) -> {
                    val decoded = decodeGzip(current)
                    if (!decoded.contentEquals(current)) {
                        current = decoded
                        continue
                    }
                }
                else -> {
                    val decoded = tryDecodeBase64(current)
                    if (decoded != null && !decoded.contentEquals(current)) {
                        current = decoded
                        continue
                    }
                }
            }
            break
        }

        return current
    }

    private fun tryDecodeBase64(bytes: ByteArray): ByteArray? {
        val text = bytes.toString(UTF_8).trim()
        if (text.length < 16) {
            return null
        }

        val normalized = text
            .replace("\n", "")
            .replace("\r", "")
            .trim()

        if (normalized.length % 4 != 0) {
            return null
        }

        if (normalized.any { !isBase64Character(it) }) {
            return null
        }

        return try {
            Base64.decode(normalized, Base64.DEFAULT)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun isBase64Character(char: Char): Boolean {
        return char.isLetterOrDigit() || char == '+' || char == '/' || char == '='
    }

    private fun decodeGzip(bytes: ByteArray): ByteArray {
        return try {
            GZIPInputStream(ByteArrayInputStream(bytes)).use { it.readAllBytes() }
        } catch (_: Exception) {
            bytes
        }
    }

    private fun dumpAttachment(rawName: String, bytes: ByteArray) {
        // Intentionally disabled: embedded payloads may contain raw receipt data.
    }

    private fun ZipInputStream.readEntryBytes(): ByteArray {
        val buffer = ByteArrayOutputStream()
        val chunk = ByteArray(8192)

        while (true) {
            val read = read(chunk)
            if (read <= 0) {
                break
            }
            buffer.write(chunk, 0, read)
        }

        return buffer.toByteArray()
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

    private enum class StageStatus(val value: String, val priority: Int) {
        SUCCESS("success", 4),
        ERROR("error", 3),
        INVALID("invalid", 2),
        EMPTY("empty", 1),
        ABSENT("absent", 0);
    }

    private data class StageResult<T>(val value: T?, val status: StageStatus)

    private class EmptyPdfTextException(
        val stages: Map<String, String>,
    ) : IllegalStateException(
        "PDF does not contain any machine-readable text or embedded receipt data.",
    )

    private fun dominantStatus(first: StageStatus, second: StageStatus): StageStatus {
        return if (first.priority >= second.priority) first else second
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
