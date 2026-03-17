import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class QuranAyat {
  final int surahNumber;
  final int ayatNumber;
  final String arabic;
  final String english;
  final String urdu;
  final String surahName;
  final String surahNameArabic;

  QuranAyat({
    required this.surahNumber,
    required this.ayatNumber,
    required this.arabic,
    required this.english,
    required this.urdu,
    required this.surahName,
    required this.surahNameArabic,
  });

  Map<String, dynamic> toJson() => {
    'surah': surahNumber, 'ayat': ayatNumber,
    'arabic': arabic, 'english': english, 'urdu': urdu,
    'surahName': surahName, 'surahNameArabic': surahNameArabic,
  };

  factory QuranAyat.fromJson(Map<String, dynamic> json) {
    return QuranAyat(
      surahNumber: json['surah'] ?? 1,
      ayatNumber: json['ayat'] ?? 1,
      arabic: json['arabic'] ?? '',
      english: json['english'] ?? '',
      urdu: json['urdu'] ?? '',
      surahName: json['surahName'] ?? '',
      surahNameArabic: json['surahNameArabic'] ?? '',
    );
  }
}

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _cachePrefix = 'quran_surah_';
  static const String _positionKey = 'quran_position';

  // Get current reading position
  static Future<Map<String, int>> getCurrentPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt('${_positionKey}_surah') ?? 1;
    final ayat = prefs.getInt('${_positionKey}_ayat') ?? 1;
    return {'surah': surah, 'ayat': ayat};
  }

  // Save current reading position
  static Future<void> savePosition(int surah, int ayat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_positionKey}_surah', surah);
    await prefs.setInt('${_positionKey}_ayat', ayat);
  }

  // Load a Surah — try cache first, then API, then backup
  static Future<List<QuranAyat>> loadSurah(int surahNumber) async {
    // 1. Try cache
    final cached = await _loadFromCache(surahNumber);
    if (cached.isNotEmpty) return cached;

    // 2. Try API
    final apiData = await _loadFromApi(surahNumber);
    if (apiData.isNotEmpty) {
      await _saveToCache(surahNumber, apiData);
      return apiData;
    }

    // 3. Try backup JSON
    final backup = await _loadFromBackup(surahNumber);
    if (backup.isNotEmpty) return backup;

    // 4. Fallback
    return [
      QuranAyat(
        surahNumber: surahNumber, ayatNumber: 1,
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
        english: 'In the name of Allah, the Most Gracious, the Most Merciful.',
        urdu: 'اللہ کے نام سے جو بے حد مہربان نہایت رحم والا ہے',
        surahName: 'Al-Fatiha', surahNameArabic: 'الفاتحة',
      ),
    ];
  }

  // Load from API
  static Future<List<QuranAyat>> _loadFromApi(int surahNumber) async {
    try {
      // Get Arabic
      final arabicResponse = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/ar.alafasy'),
      ).timeout(const Duration(seconds: 10));

      // Get English translation
      final englishResponse = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/en.sahih'),
      ).timeout(const Duration(seconds: 10));

      // Get Urdu translation
      final urduResponse = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/ur.jalandhry'),
      ).timeout(const Duration(seconds: 10));

      if (arabicResponse.statusCode == 200 && englishResponse.statusCode == 200 && urduResponse.statusCode == 200) {
        final arabicData = jsonDecode(arabicResponse.body)['data'];
        final englishData = jsonDecode(englishResponse.body)['data'];
        final urduData = jsonDecode(urduResponse.body)['data'];

        final arabicAyahs = arabicData['ayahs'] as List;
        final englishAyahs = englishData['ayahs'] as List;
        final urduAyahs = urduData['ayahs'] as List;

        final surahName = arabicData['englishName'] ?? 'Surah $surahNumber';
        final surahNameArabic = arabicData['name'] ?? '';

        List<QuranAyat> ayats = [];
        for (int i = 0; i < arabicAyahs.length; i++) {
          ayats.add(QuranAyat(
            surahNumber: surahNumber,
            ayatNumber: arabicAyahs[i]['numberInSurah'] ?? (i + 1),
            arabic: arabicAyahs[i]['text'] ?? '',
            english: i < englishAyahs.length ? (englishAyahs[i]['text'] ?? '') : '',
            urdu: i < urduAyahs.length ? (urduAyahs[i]['text'] ?? '') : '',
            surahName: surahName,
            surahNameArabic: surahNameArabic,
          ));
        }
        return ayats;
      }
    } catch (e) {
      // API failed
    }
    return [];
  }

  // Load from cache
  static Future<List<QuranAyat>> _loadFromCache(int surahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachePrefix$surahNumber');
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((j) => QuranAyat.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Save to cache
  static Future<void> _saveToCache(int surahNumber, List<QuranAyat> ayats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = ayats.map((a) => a.toJson()).toList();
      await prefs.setString('$_cachePrefix$surahNumber', jsonEncode(jsonList));
    } catch (_) {}
  }

  // Load from backup JSON asset
  static Future<List<QuranAyat>> _loadFromBackup(int surahNumber) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/quran/surah_$surahNumber.json');
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => QuranAyat.fromJson(j)).toList();
    } catch (_) {}
    return [];
  }

  // Get Surah info
  static final List<Map<String, dynamic>> surahList = [
    {'number': 1, 'name': 'Al-Fatiha', 'arabic': 'الفاتحة', 'ayahs': 7},
    {'number': 2, 'name': 'Al-Baqarah', 'arabic': 'البقرة', 'ayahs': 286},
    {'number': 3, 'name': 'Aal-Imran', 'arabic': 'آل عمران', 'ayahs': 200},
    {'number': 4, 'name': 'An-Nisa', 'arabic': 'النساء', 'ayahs': 176},
    {'number': 5, 'name': 'Al-Maidah', 'arabic': 'المائدة', 'ayahs': 120},
    {'number': 6, 'name': 'Al-Anam', 'arabic': 'الأنعام', 'ayahs': 165},
    {'number': 7, 'name': 'Al-Araf', 'arabic': 'الأعراف', 'ayahs': 206},
    {'number': 8, 'name': 'Al-Anfal', 'arabic': 'الأنفال', 'ayahs': 75},
    {'number': 9, 'name': 'At-Tawbah', 'arabic': 'التوبة', 'ayahs': 129},
    {'number': 10, 'name': 'Yunus', 'arabic': 'يونس', 'ayahs': 109},
    {'number': 11, 'name': 'Hud', 'arabic': 'هود', 'ayahs': 123},
    {'number': 12, 'name': 'Yusuf', 'arabic': 'يوسف', 'ayahs': 111},
    {'number': 13, 'name': 'Ar-Rad', 'arabic': 'الرعد', 'ayahs': 43},
    {'number': 14, 'name': 'Ibrahim', 'arabic': 'إبراهيم', 'ayahs': 52},
    {'number': 15, 'name': 'Al-Hijr', 'arabic': 'الحجر', 'ayahs': 99},
    {'number': 16, 'name': 'An-Nahl', 'arabic': 'النحل', 'ayahs': 128},
    {'number': 17, 'name': 'Al-Isra', 'arabic': 'الإسراء', 'ayahs': 111},
    {'number': 18, 'name': 'Al-Kahf', 'arabic': 'الكهف', 'ayahs': 110},
    {'number': 19, 'name': 'Maryam', 'arabic': 'مريم', 'ayahs': 98},
    {'number': 20, 'name': 'Ta-Ha', 'arabic': 'طه', 'ayahs': 135},
    {'number': 21, 'name': 'Al-Anbiya', 'arabic': 'الأنبياء', 'ayahs': 112},
    {'number': 22, 'name': 'Al-Hajj', 'arabic': 'الحج', 'ayahs': 78},
    {'number': 23, 'name': 'Al-Muminun', 'arabic': 'المؤمنون', 'ayahs': 118},
    {'number': 24, 'name': 'An-Nur', 'arabic': 'النور', 'ayahs': 64},
    {'number': 25, 'name': 'Al-Furqan', 'arabic': 'الفرقان', 'ayahs': 77},
    {'number': 26, 'name': 'Ash-Shuara', 'arabic': 'الشعراء', 'ayahs': 227},
    {'number': 27, 'name': 'An-Naml', 'arabic': 'النمل', 'ayahs': 93},
    {'number': 28, 'name': 'Al-Qasas', 'arabic': 'القصص', 'ayahs': 88},
    {'number': 29, 'name': 'Al-Ankabut', 'arabic': 'العنكبوت', 'ayahs': 69},
    {'number': 30, 'name': 'Ar-Rum', 'arabic': 'الروم', 'ayahs': 60},
    {'number': 31, 'name': 'Luqman', 'arabic': 'لقمان', 'ayahs': 34},
    {'number': 32, 'name': 'As-Sajdah', 'arabic': 'السجدة', 'ayahs': 30},
    {'number': 33, 'name': 'Al-Ahzab', 'arabic': 'الأحزاب', 'ayahs': 73},
    {'number': 34, 'name': 'Saba', 'arabic': 'سبأ', 'ayahs': 54},
    {'number': 35, 'name': 'Fatir', 'arabic': 'فاطر', 'ayahs': 45},
    {'number': 36, 'name': 'Ya-Sin', 'arabic': 'يس', 'ayahs': 83},
    {'number': 37, 'name': 'As-Saffat', 'arabic': 'الصافات', 'ayahs': 182},
    {'number': 38, 'name': 'Sad', 'arabic': 'ص', 'ayahs': 88},
    {'number': 39, 'name': 'Az-Zumar', 'arabic': 'الزمر', 'ayahs': 75},
    {'number': 40, 'name': 'Ghafir', 'arabic': 'غافر', 'ayahs': 85},
    {'number': 41, 'name': 'Fussilat', 'arabic': 'فصلت', 'ayahs': 54},
    {'number': 42, 'name': 'Ash-Shura', 'arabic': 'الشورى', 'ayahs': 53},
    {'number': 43, 'name': 'Az-Zukhruf', 'arabic': 'الزخرف', 'ayahs': 89},
    {'number': 44, 'name': 'Ad-Dukhan', 'arabic': 'الدخان', 'ayahs': 59},
    {'number': 45, 'name': 'Al-Jathiyah', 'arabic': 'الجاثية', 'ayahs': 37},
    {'number': 46, 'name': 'Al-Ahqaf', 'arabic': 'الأحقاف', 'ayahs': 35},
    {'number': 47, 'name': 'Muhammad', 'arabic': 'محمد', 'ayahs': 38},
    {'number': 48, 'name': 'Al-Fath', 'arabic': 'الفتح', 'ayahs': 29},
    {'number': 49, 'name': 'Al-Hujurat', 'arabic': 'الحجرات', 'ayahs': 18},
    {'number': 50, 'name': 'Qaf', 'arabic': 'ق', 'ayahs': 45},
    {'number': 51, 'name': 'Adh-Dhariyat', 'arabic': 'الذاريات', 'ayahs': 60},
    {'number': 52, 'name': 'At-Tur', 'arabic': 'الطور', 'ayahs': 49},
    {'number': 53, 'name': 'An-Najm', 'arabic': 'النجم', 'ayahs': 62},
    {'number': 54, 'name': 'Al-Qamar', 'arabic': 'القمر', 'ayahs': 55},
    {'number': 55, 'name': 'Ar-Rahman', 'arabic': 'الرحمن', 'ayahs': 78},
    {'number': 56, 'name': 'Al-Waqiah', 'arabic': 'الواقعة', 'ayahs': 96},
    {'number': 57, 'name': 'Al-Hadid', 'arabic': 'الحديد', 'ayahs': 29},
    {'number': 58, 'name': 'Al-Mujadila', 'arabic': 'المجادلة', 'ayahs': 22},
    {'number': 59, 'name': 'Al-Hashr', 'arabic': 'الحشر', 'ayahs': 24},
    {'number': 60, 'name': 'Al-Mumtahanah', 'arabic': 'الممتحنة', 'ayahs': 13},
    {'number': 61, 'name': 'As-Saff', 'arabic': 'الصف', 'ayahs': 14},
    {'number': 62, 'name': 'Al-Jumuah', 'arabic': 'الجمعة', 'ayahs': 11},
    {'number': 63, 'name': 'Al-Munafiqun', 'arabic': 'المنافقون', 'ayahs': 11},
    {'number': 64, 'name': 'At-Taghabun', 'arabic': 'التغابن', 'ayahs': 18},
    {'number': 65, 'name': 'At-Talaq', 'arabic': 'الطلاق', 'ayahs': 12},
    {'number': 66, 'name': 'At-Tahrim', 'arabic': 'التحريم', 'ayahs': 12},
    {'number': 67, 'name': 'Al-Mulk', 'arabic': 'الملك', 'ayahs': 30},
    {'number': 68, 'name': 'Al-Qalam', 'arabic': 'القلم', 'ayahs': 52},
    {'number': 69, 'name': 'Al-Haqqah', 'arabic': 'الحاقة', 'ayahs': 52},
    {'number': 70, 'name': 'Al-Maarij', 'arabic': 'المعارج', 'ayahs': 44},
    {'number': 71, 'name': 'Nuh', 'arabic': 'نوح', 'ayahs': 28},
    {'number': 72, 'name': 'Al-Jinn', 'arabic': 'الجن', 'ayahs': 28},
    {'number': 73, 'name': 'Al-Muzzammil', 'arabic': 'المزمل', 'ayahs': 20},
    {'number': 74, 'name': 'Al-Muddathir', 'arabic': 'المدثر', 'ayahs': 56},
    {'number': 75, 'name': 'Al-Qiyamah', 'arabic': 'القيامة', 'ayahs': 40},
    {'number': 76, 'name': 'Al-Insan', 'arabic': 'الإنسان', 'ayahs': 31},
    {'number': 77, 'name': 'Al-Mursalat', 'arabic': 'المرسلات', 'ayahs': 50},
    {'number': 78, 'name': 'An-Naba', 'arabic': 'النبأ', 'ayahs': 40},
    {'number': 79, 'name': 'An-Naziat', 'arabic': 'النازعات', 'ayahs': 46},
    {'number': 80, 'name': 'Abasa', 'arabic': 'عبس', 'ayahs': 42},
    {'number': 81, 'name': 'At-Takwir', 'arabic': 'التكوير', 'ayahs': 29},
    {'number': 82, 'name': 'Al-Infitar', 'arabic': 'الانفطار', 'ayahs': 19},
    {'number': 83, 'name': 'Al-Mutaffifin', 'arabic': 'المطففين', 'ayahs': 36},
    {'number': 84, 'name': 'Al-Inshiqaq', 'arabic': 'الانشقاق', 'ayahs': 25},
    {'number': 85, 'name': 'Al-Buruj', 'arabic': 'البروج', 'ayahs': 22},
    {'number': 86, 'name': 'At-Tariq', 'arabic': 'الطارق', 'ayahs': 17},
    {'number': 87, 'name': 'Al-Ala', 'arabic': 'الأعلى', 'ayahs': 19},
    {'number': 88, 'name': 'Al-Ghashiyah', 'arabic': 'الغاشية', 'ayahs': 26},
    {'number': 89, 'name': 'Al-Fajr', 'arabic': 'الفجر', 'ayahs': 30},
    {'number': 90, 'name': 'Al-Balad', 'arabic': 'البلد', 'ayahs': 20},
    {'number': 91, 'name': 'Ash-Shams', 'arabic': 'الشمس', 'ayahs': 15},
    {'number': 92, 'name': 'Al-Layl', 'arabic': 'الليل', 'ayahs': 21},
    {'number': 93, 'name': 'Ad-Duha', 'arabic': 'الضحى', 'ayahs': 11},
    {'number': 94, 'name': 'Ash-Sharh', 'arabic': 'الشرح', 'ayahs': 8},
    {'number': 95, 'name': 'At-Tin', 'arabic': 'التين', 'ayahs': 8},
    {'number': 96, 'name': 'Al-Alaq', 'arabic': 'العلق', 'ayahs': 19},
    {'number': 97, 'name': 'Al-Qadr', 'arabic': 'القدر', 'ayahs': 5},
    {'number': 98, 'name': 'Al-Bayyinah', 'arabic': 'البينة', 'ayahs': 8},
    {'number': 99, 'name': 'Az-Zalzalah', 'arabic': 'الزلزلة', 'ayahs': 8},
    {'number': 100, 'name': 'Al-Adiyat', 'arabic': 'العاديات', 'ayahs': 11},
    {'number': 101, 'name': 'Al-Qariah', 'arabic': 'القارعة', 'ayahs': 11},
    {'number': 102, 'name': 'At-Takathur', 'arabic': 'التكاثر', 'ayahs': 8},
    {'number': 103, 'name': 'Al-Asr', 'arabic': 'العصر', 'ayahs': 3},
    {'number': 104, 'name': 'Al-Humazah', 'arabic': 'الهمزة', 'ayahs': 9},
    {'number': 105, 'name': 'Al-Fil', 'arabic': 'الفيل', 'ayahs': 5},
    {'number': 106, 'name': 'Quraysh', 'arabic': 'قريش', 'ayahs': 4},
    {'number': 107, 'name': 'Al-Maun', 'arabic': 'الماعون', 'ayahs': 7},
    {'number': 108, 'name': 'Al-Kawthar', 'arabic': 'الكوثر', 'ayahs': 3},
    {'number': 109, 'name': 'Al-Kafirun', 'arabic': 'الكافرون', 'ayahs': 6},
    {'number': 110, 'name': 'An-Nasr', 'arabic': 'النصر', 'ayahs': 3},
    {'number': 111, 'name': 'Al-Masad', 'arabic': 'المسد', 'ayahs': 5},
    {'number': 112, 'name': 'Al-Ikhlas', 'arabic': 'الإخلاص', 'ayahs': 4},
    {'number': 113, 'name': 'Al-Falaq', 'arabic': 'الفلق', 'ayahs': 5},
    {'number': 114, 'name': 'An-Nas', 'arabic': 'الناس', 'ayahs': 6},
  ];

  // Get next ayat in sequence
  static Future<QuranAyat?> getNextAyat() async {
    final position = await getCurrentPosition();
    int surah = position['surah']!;
    int ayat = position['ayat']!;

    final ayats = await loadSurah(surah);
    if (ayats.isEmpty) return null;

    // Find current ayat
    final currentIndex = ayats.indexWhere((a) => a.ayatNumber == ayat);
    if (currentIndex >= 0 && currentIndex < ayats.length) {
      return ayats[currentIndex];
    }

    // If not found, return first ayat of surah
    return ayats.first;
  }

  // Move to next ayat
  static Future<void> moveToNext() async {
    final position = await getCurrentPosition();
    int surah = position['surah']!;
    int ayat = position['ayat']!;

    final surahInfo = surahList.firstWhere((s) => s['number'] == surah, orElse: () => surahList.first);
    final totalAyahs = surahInfo['ayahs'] as int;

    ayat++;
    if (ayat > totalAyahs) {
      // Move to next surah
      surah++;
      if (surah > 114) surah = 1; // Loop back to beginning
      ayat = 1;
    }

    await savePosition(surah, ayat);
  }
}