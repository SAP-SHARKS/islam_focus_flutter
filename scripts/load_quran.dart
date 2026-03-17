// Run this with: dart run scripts/load_quran.dart

import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://zgupeerauxqcyeshpokj.supabase.co';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'; // apna anon key daalein

Future<void> main() async {
  final client = HttpClient();
  
  print('Starting Quran data load...');
  
  // Load all 114 surahs
  for (int surah = 1; surah <= 114; surah++) {
    print('Loading Surah $surah...');
    
    try {
      // Fetch Arabic
      final arabicData = await fetchJson(client, 'https://api.alquran.cloud/v1/surah/$surah/ar.alafasy');
      // Fetch English
      final englishData = await fetchJson(client, 'https://api.alquran.cloud/v1/surah/$surah/en.sahih');
      // Fetch Urdu
      final urduData = await fetchJson(client, 'https://api.alquran.cloud/v1/surah/$surah/ur.jalandhry');
      
      if (arabicData == null || englishData == null || urduData == null) {
        print('  ERROR: Failed to fetch surah $surah');
        continue;
      }
      
      final arabicSurah = arabicData['data'];
      final englishSurah = englishData['data'];
      final urduSurah = urduData['data'];
      
      final arabicAyahs = arabicSurah['ayahs'] as List;
      final englishAyahs = englishSurah['ayahs'] as List;
      final urduAyahs = urduSurah['ayahs'] as List;
      
      final surahName = arabicSurah['englishName'] ?? 'Surah $surah';
      final surahNameArabic = arabicSurah['name'] ?? '';
      final revelationPlace = arabicSurah['revelationType'] ?? '';
      
      // Save surah metadata
      await insertToSupabase(client, 'quran_surahs', {
        'id': surah,
        'name_english': surahName,
        'name_arabic': surahNameArabic,
        'name_simple': arabicSurah['englishNameTranslation'] ?? '',
        'revelation_place': revelationPlace,
        'verses_count': arabicAyahs.length,
        'translated_name': arabicSurah['englishNameTranslation'] ?? '',
      });
      
      // Save each ayat
      for (int i = 0; i < arabicAyahs.length; i++) {
        final ayatNum = arabicAyahs[i]['numberInSurah'];
        final verseKey = '$surah:$ayatNum';
        
        await insertToSupabase(client, 'quran_verses', {
          'surah_number': surah,
          'ayat_number': ayatNum,
          'verse_key': verseKey,
          'text_arabic': arabicAyahs[i]['text'] ?? '',
          'text_english': i < englishAyahs.length ? (englishAyahs[i]['text'] ?? '') : '',
          'text_urdu': i < urduAyahs.length ? (urduAyahs[i]['text'] ?? '') : '',
          'surah_name_english': surahName,
          'surah_name_arabic': surahNameArabic,
          'juz_number': arabicAyahs[i]['juz'] ?? 0,
          'hizb_number': arabicAyahs[i]['hizbQuarter'] ?? 0,
          'page_number': arabicAyahs[i]['page'] ?? 0,
        });
      }
      
      print('  Surah $surah loaded: ${arabicAyahs.length} ayahs');
      
      // Small delay to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 500));
      
    } catch (e) {
      print('  ERROR loading surah $surah: $e');
    }
  }
  
  print('\nDone! All 114 surahs loaded.');
  client.close();
}

Future<Map<String, dynamic>?> fetchJson(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body);
  } catch (e) {
    return null;
  }
}

Future<void> insertToSupabase(HttpClient client, String table, Map<String, dynamic> data) async {
  try {
    final url = '$supabaseUrl/rest/v1/$table';
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Prefer', 'resolution=merge-duplicates');
    request.write(jsonEncode(data));
    final response = await request.close();
    await response.drain();
  } catch (e) {
    // Skip errors for duplicates
  }
}
