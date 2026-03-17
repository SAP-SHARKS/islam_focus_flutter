package com.example.islamfocus

import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

data class Ayat(
    val surahNumber: Int,
    val ayatNumber: Int,
    val arabic: String,
    val english: String,
    val urdu: String,
    val surahName: String,
    val surahNameArabic: String
)

object QuranLoader {

    private const val POS_SURAH = "quran_current_surah"
    private const val POS_AYAT = "quran_current_ayat"
    private const val CACHE_PREFIX = "quran_cache_surah_"
    private const val BASE_URL = "https://api.alquran.cloud/v1"

    private val surahAyahCounts = intArrayOf(
        7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
        112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,
        59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,
        52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,
        21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
    )

    private val surahNames = arrayOf(
        "Al-Fatiha","Al-Baqarah","Aal-Imran","An-Nisa","Al-Maidah","Al-Anam","Al-Araf","Al-Anfal","At-Tawbah","Yunus",
        "Hud","Yusuf","Ar-Rad","Ibrahim","Al-Hijr","An-Nahl","Al-Isra","Al-Kahf","Maryam","Ta-Ha",
        "Al-Anbiya","Al-Hajj","Al-Muminun","An-Nur","Al-Furqan","Ash-Shuara","An-Naml","Al-Qasas","Al-Ankabut","Ar-Rum",
        "Luqman","As-Sajdah","Al-Ahzab","Saba","Fatir","Ya-Sin","As-Saffat","Sad","Az-Zumar","Ghafir",
        "Fussilat","Ash-Shura","Az-Zukhruf","Ad-Dukhan","Al-Jathiyah","Al-Ahqaf","Muhammad","Al-Fath","Al-Hujurat","Qaf",
        "Adh-Dhariyat","At-Tur","An-Najm","Al-Qamar","Ar-Rahman","Al-Waqiah","Al-Hadid","Al-Mujadila","Al-Hashr","Al-Mumtahanah",
        "As-Saff","Al-Jumuah","Al-Munafiqun","At-Taghabun","At-Talaq","At-Tahrim","Al-Mulk","Al-Qalam","Al-Haqqah","Al-Maarij",
        "Nuh","Al-Jinn","Al-Muzzammil","Al-Muddathir","Al-Qiyamah","Al-Insan","Al-Mursalat","An-Naba","An-Naziat","Abasa",
        "At-Takwir","Al-Infitar","Al-Mutaffifin","Al-Inshiqaq","Al-Buruj","At-Tariq","Al-Ala","Al-Ghashiyah","Al-Fajr","Al-Balad",
        "Ash-Shams","Al-Layl","Ad-Duha","Ash-Sharh","At-Tin","Al-Alaq","Al-Qadr","Al-Bayyinah","Az-Zalzalah","Al-Adiyat",
        "Al-Qariah","At-Takathur","Al-Asr","Al-Humazah","Al-Fil","Quraysh","Al-Maun","Al-Kawthar","Al-Kafirun","An-Nasr",
        "Al-Masad","Al-Ikhlas","Al-Falaq","An-Nas"
    )

    private val surahArabicNames = arrayOf(
        "الفاتحة","البقرة","آل عمران","النساء","المائدة","الأنعام","الأعراف","الأنفال","التوبة","يونس",
        "هود","يوسف","الرعد","إبراهيم","الحجر","النحل","الإسراء","الكهف","مريم","طه",
        "الأنبياء","الحج","المؤمنون","النور","الفرقان","الشعراء","النمل","القصص","العنكبوت","الروم",
        "لقمان","السجدة","الأحزاب","سبأ","فاطر","يس","الصافات","ص","الزمر","غافر",
        "فصلت","الشورى","الزخرف","الدخان","الجاثية","الأحقاف","محمد","الفتح","الحجرات","ق",
        "الذاريات","الطور","النجم","القمر","الرحمن","الواقعة","الحديد","المجادلة","الحشر","الممتحنة",
        "الصف","الجمعة","المنافقون","التغابن","الطلاق","التحريم","الملك","القلم","الحاقة","المعارج",
        "نوح","الجن","المزمل","المدثر","القيامة","الإنسان","المرسلات","النبأ","النازعات","عبس",
        "التكوير","الانفطار","المطففين","الانشقاق","البروج","الطارق","الأعلى","الغاشية","الفجر","البلد",
        "الشمس","الليل","الضحى","الشرح","التين","العلق","القدر","البينة","الزلزلة","العاديات",
        "القارعة","التكاثر","العصر","الهمزة","الفيل","قريش","الماعون","الكوثر","الكافرون","النصر",
        "المسد","الإخلاص","الفلق","الناس"
    )

    fun getCurrentAyat(prefs: SharedPreferences): Ayat {
        val surah = prefs.getInt(POS_SURAH, 1)
        val ayat = prefs.getInt(POS_AYAT, 1)

        val cached = getCachedAyat(prefs, surah, ayat)
        if (cached != null) return cached

        val sIdx = (surah - 1).coerceIn(0, 113)
        return Ayat(surah, ayat, "Loading...", "Loading ayat $surah:$ayat...", "آیت لوڈ ہو رہی ہے...", surahNames[sIdx], surahArabicNames[sIdx])
    }

    fun moveToNextAndGet(prefs: SharedPreferences): Ayat {
        var surah = prefs.getInt(POS_SURAH, 1)
        var ayat = prefs.getInt(POS_AYAT, 1)

        ayat++
        val maxAyat = if (surah in 1..114) surahAyahCounts[surah - 1] else 7
        if (ayat > maxAyat) {
            surah++
            if (surah > 114) surah = 1
            ayat = 1
        }

        prefs.edit().putInt(POS_SURAH, surah).putInt(POS_AYAT, ayat).apply()

        val cached = getCachedAyat(prefs, surah, ayat)
        if (cached != null) return cached

        val sIdx = (surah - 1).coerceIn(0, 113)
        return Ayat(surah, ayat, "Loading...", "Loading ayat $surah:$ayat...", "آیت لوڈ ہو رہی ہے...", surahNames[sIdx], surahArabicNames[sIdx])
    }

    fun getCurrentIndex(prefs: SharedPreferences): Int {
        val surah = prefs.getInt(POS_SURAH, 1)
        val ayat = prefs.getInt(POS_AYAT, 1)
        var total = 0
        for (i in 0 until (surah - 1).coerceIn(0, 113)) {
            total += surahAyahCounts[i]
        }
        return total + ayat
    }

    fun getTotalAyats(): Int = 6236

    /**
     * Check if a surah is already cached
     */
    fun isSurahCached(prefs: SharedPreferences, surahNumber: Int): Boolean {
        return prefs.getString("$CACHE_PREFIX$surahNumber", null) != null
    }

    /**
     * Download and cache a surah from API (call from background thread)
     * Skips if already cached
     */
    fun downloadAndCacheSurah(prefs: SharedPreferences, surahNumber: Int): Boolean {
        // Skip if already cached
        if (isSurahCached(prefs, surahNumber)) return true

        try {
            // Fetch all 3 editions in parallel-ish (sequential but fast)
            val arabicJson = fetchUrl("$BASE_URL/surah/$surahNumber/ar.alafasy") ?: return false
            val englishJson = fetchUrl("$BASE_URL/surah/$surahNumber/en.sahih") ?: return false
            val urduJson = fetchUrl("$BASE_URL/surah/$surahNumber/ur.jalandhry") ?: return false

            val arabicAyahs = JSONObject(arabicJson).getJSONObject("data").getJSONArray("ayahs")
            val englishAyahs = JSONObject(englishJson).getJSONObject("data").getJSONArray("ayahs")
            val urduAyahs = JSONObject(urduJson).getJSONObject("data").getJSONArray("ayahs")

            val sIdx = (surahNumber - 1).coerceIn(0, 113)
            val arr = JSONArray()

            for (i in 0 until arabicAyahs.length()) {
                val obj = JSONObject()
                obj.put("surah", surahNumber)
                obj.put("ayat", arabicAyahs.getJSONObject(i).optInt("numberInSurah", i + 1))
                obj.put("arabic", arabicAyahs.getJSONObject(i).optString("text", ""))
                obj.put("english", if (i < englishAyahs.length()) englishAyahs.getJSONObject(i).optString("text", "") else "")
                obj.put("urdu", if (i < urduAyahs.length()) urduAyahs.getJSONObject(i).optString("text", "") else "")
                obj.put("surahName", surahNames[sIdx])
                obj.put("surahNameArabic", surahArabicNames[sIdx])
                arr.put(obj)
            }

            prefs.edit().putString("$CACHE_PREFIX$surahNumber", arr.toString()).apply()
            return true
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Preload next N surahs in background
     * Only downloads surahs that are not already cached
     */
    fun preloadNextSurahs(prefs: SharedPreferences, currentSurah: Int, count: Int = 3) {
        for (i in 1..count) {
            val nextSurah = if (currentSurah + i > 114) (currentSurah + i - 114) else (currentSurah + i)
            if (!isSurahCached(prefs, nextSurah)) {
                downloadAndCacheSurah(prefs, nextSurah)
            }
        }
    }

    private fun getCachedAyat(prefs: SharedPreferences, surah: Int, ayat: Int): Ayat? {
        try {
            val cached = prefs.getString("$CACHE_PREFIX$surah", null) ?: return null
            val arr = JSONArray(cached)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.getInt("ayat") == ayat) {
                    return Ayat(
                        obj.getInt("surah"), obj.getInt("ayat"),
                        obj.getString("arabic"), obj.getString("english"), obj.getString("urdu"),
                        obj.getString("surahName"), obj.getString("surahNameArabic")
                    )
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun fetchUrl(urlString: String): String? {
        return try {
            val conn = URL(urlString).openConnection() as HttpURLConnection
            conn.connectTimeout = 10000
            conn.readTimeout = 10000
            conn.requestMethod = "GET"
            if (conn.responseCode == 200) {
                BufferedReader(InputStreamReader(conn.inputStream)).readText()
            } else null
        } catch (_: Exception) { null }
    }
}