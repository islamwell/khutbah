import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pulpitflow/models/khutbah.dart';
import 'package:pulpitflow/models/content_item.dart';

class StorageService {
  static Database? _database;
  static const String khutbahTable = 'khutbahs';
  static const String contentTable = 'content_items';

  // Keys for web storage
  static const String _webKhutbahsKey = 'pf_web_khutbahs';
  static const String _webContentKey = 'pf_web_content_items';

  static Future<Database> get database async {
    if (kIsWeb) {
      // Web does not use a local SQLite database; callers should branch accordingly
      throw Exception('Database not available on web');
    }
    _database ??= await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'al_minbar.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $khutbahTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT,
        createdAt TEXT NOT NULL,
        modifiedAt TEXT NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        folderId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $contentTable (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        translation TEXT NOT NULL,
        source TEXT NOT NULL,
        type TEXT NOT NULL,
        authenticity TEXT,
        surahName TEXT,
        verseNumber INTEGER,
        keywords TEXT NOT NULL
      )
    ''');

    await _insertSampleContentSQLite(db);
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new content items for version 2 (Quran ayats)
      await _insertNewContentItems(db);
    }
    if (oldVersion < 3) {
      // Add new sayings for version 3
      await _insertNewSayings(db);
    }
    if (oldVersion < 4) {
      // Add new hadith for version 4
      await _insertNewHadith(db);
    }
  }

  static Future<void> _insertNewContentItems(Database db) async {
    final newContent = _sampleContentItems().where((item) => 
      int.tryParse(item.id) != null && int.parse(item.id) >= 19 && int.parse(item.id) <= 30
    ).toList();
    
    for (final content in newContent) {
      try {
        await db.insert(contentTable, content.toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        debugPrint('Error inserting content item ${content.id}: $e');
      }
    }
  }

  static Future<void> _insertNewSayings(Database db) async {
    final newSayings = _sampleContentItems().where((item) => 
      int.tryParse(item.id) != null && int.parse(item.id) >= 31 && int.parse(item.id) <= 33
    ).toList();
    
    for (final saying in newSayings) {
      try {
        await db.insert(contentTable, saying.toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        debugPrint('Error inserting saying ${saying.id}: $e');
      }
    }
  }

  static Future<void> _insertNewHadith(Database db) async {
    final newHadith = _sampleContentItems().where((item) => 
      int.tryParse(item.id) != null && int.parse(item.id) >= 34
    ).toList();
    
    for (final hadith in newHadith) {
      try {
        await db.insert(contentTable, hadith.toJson(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        debugPrint('Error inserting hadith ${hadith.id}: $e');
      }
    }
  }

  // ---------- Web helpers ----------
  static Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> _prefsGetJsonList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(key) ?? <String>[];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> _prefsSetJsonList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    final raw = list.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(key, raw);
  }

  static Future<void> _ensureWebContentInitialized() async {
    final prefs = await _prefs;
    final exists = prefs.containsKey(_webContentKey);
    if (!exists) {
      final items = _sampleContentItems().map((c) => c.toJson()).toList();
      await _prefsSetJsonList(_webContentKey, items);
    } else {
      // Check if we need to add new content items
      await _updateWebContentIfNeeded();
    }
  }

  static Future<void> _updateWebContentIfNeeded() async {
    final currentItems = await _prefsGetJsonList(_webContentKey);
    final currentIds = currentItems.map((item) => item['id'] as String).toSet();
    final allSampleItems = _sampleContentItems();
    
    bool needsUpdate = false;
    final updatedItems = List<Map<String, dynamic>>.from(currentItems);
    
    for (final sampleItem in allSampleItems) {
      if (!currentIds.contains(sampleItem.id)) {
        updatedItems.add(sampleItem.toJson());
        needsUpdate = true;
      }
    }
    
    if (needsUpdate) {
      await _prefsSetJsonList(_webContentKey, updatedItems);
    }
  }

  // ---------- Sample content ----------
  static Future<void> _insertSampleContentSQLite(Database db) async {
    final sampleContent = _sampleContentItems();
    for (final content in sampleContent) {
      await db.insert(contentTable, content.toJson());
    }
  }

  static List<ContentItem> _sampleContentItems() {
    return [
      // Quran verses
      const ContentItem(
        id: '1',
        text: 'وَمَن يَشْكُرْ فَإِنَّمَا يَشْكُرُ لِنَفْسِهِ',
        translation: 'And whoever is grateful - he is only grateful for his own soul.',
        source: 'Surah Luqman',
        type: ContentType.quran,
        surahName: 'Luqman',
        verseNumber: 12,
        keywords: ['gratitude', 'thankfulness', 'shukr'],
      ),
      // New Quran ayats
      const ContentItem(
        id: '19',
        text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
        translation: 'Those that have faith! Seek divine aide by patience and praying. Without a doubt Allah is with those who are patient.',
        source: 'Surah Al-Baqarah',
        type: ContentType.quran,
        surahName: 'Al-Baqarah',
        verseNumber: 153,
        keywords: ['patience', 'prayer', 'faith', 'divine help', 'sabr'],
      ),
      const ContentItem(
        id: '20',
        text: 'وَكُلُّ صَغِيرٍ وَكَبِيرٍ مُّسْتَطَرٌ',
        translation: 'And everything small and everything big is being recorded in a written record.',
        source: 'Surah Al-Qamar',
        type: ContentType.quran,
        surahName: 'Al-Qamar',
        verseNumber: 53,
        keywords: ['record', 'accountability', 'deeds', 'written'],
      ),
      const ContentItem(
        id: '21',
        text: 'وَاعْبُدُوا اللَّهَ وَلَا تُشْرِكُوا بِهِ شَيْئًا ۖ وَبِالْوَالِدَيْنِ إِحْسَانًا وَبِذِي الْقُرْبَىٰ وَالْيَتَامَىٰ وَالْمَسَاكِينِ وَالْجَارِ ذِي الْقُرْبَىٰ وَالْجَارِ الْجُنُبِ وَالصَّاحِبِ بِالْجَنبِ وَابْنِ السَّبِيلِ وَمَا مَلَكَتْ أَيْمَانُكُمْ ۗ إِنَّ اللَّهَ لَا يُحِبُّ مَن كَانَ مُخْتَالًا فَخُورًا',
        translation: 'Worship Allah and do not attribute anything as a partner to HIM and especially to both parents show nothing short of excellence and to those of close relations and orphans and the helpless and the neighbor in proximity and the neighbor further away and the companion by your side in travel and the traveler and whoever is at your command. Certainly Allah does not love anyone that has been self deluded, full of pride.',
        source: 'Surah An-Nisa',
        type: ContentType.quran,
        surahName: 'An-Nisa',
        verseNumber: 36,
        keywords: ['worship', 'parents', 'kindness', 'neighbors', 'excellence', 'pride'],
      ),
      const ContentItem(
        id: '22',
        text: 'لِلَّهِ مُلْكُ السَّمَاوَاتِ وَالْأَرْضِ وَمَا فِيهِنَّ ۚ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
        translation: 'The kingdom of the skies and the earth and whatever is within them belong to Allah alone and over all things He is in complete control.',
        source: 'Surah Al-Maidah',
        type: ContentType.quran,
        surahName: 'Al-Maidah',
        verseNumber: 120,
        keywords: ['sovereignty', 'control', 'kingdom', 'power', 'dominion'],
      ),
      const ContentItem(
        id: '23',
        text: 'وَإِن يَمْسَسْكَ اللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُ إِلَّا هُوَ ۖ وَإِن يَمْسَسْكَ بِخَيْرٍ فَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
        translation: 'If Allah were to touch you with a slightest harm then none but He is in any position to be a reliever except He and if He were to touch you with any good at all then He is in complete control over everything.',
        source: 'Surah Al-An\'am',
        type: ContentType.quran,
        surahName: 'Al-An\'am',
        verseNumber: 17,
        keywords: ['harm', 'relief', 'good', 'control', 'power'],
      ),
      const ContentItem(
        id: '24',
        text: 'وَالَّذِينَ عَمِلُوا السَّيِّئَاتِ ثُمَّ تَابُوا مِن بَعْدِهَا وَآمَنُوا إِنَّ رَبَّكَ مِن بَعْدِهَا لَغَفُورٌ رَّحِيمٌ',
        translation: 'And the ones who had committed sins deliberately and much after having committed them repented and came back to faith, no doubt your master even after them truly is extremely forgiving always loving and merciful.',
        source: 'Surah Al-A\'raf',
        type: ContentType.quran,
        surahName: 'Al-A\'raf',
        verseNumber: 153,
        keywords: ['repentance', 'forgiveness', 'mercy', 'faith', 'sins'],
      ),
      const ContentItem(
        id: '25',
        text: 'إِنَّمَا الْمُؤْمِنُونَ الَّذِينَ إِذَا ذُكِرَ اللَّهُ وَجِلَتْ قُلُوبُهُمْ وَإِذَا تُلِيَتْ عَلَيْهِمْ آيَاتُهُ زَادَتْهُمْ إِيمَانًا وَعَلَىٰ رَبِّهِمْ يَتَوَكَّلُونَ',
        translation: 'True believers constant in their faith are the ones whom when Allah is mentioned their hearts tremble and when His revelations are recited on to them enhance them in faith as they continue to rely on their master alone',
        source: 'Surah Al-Anfal',
        type: ContentType.quran,
        surahName: 'Al-Anfal',
        verseNumber: 2,
        keywords: ['believers', 'faith', 'hearts', 'revelation', 'trust', 'tawakkul'],
      ),
      const ContentItem(
        id: '26',
        text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ وَكُونُوا مَعَ الصَّادِقِينَ',
        translation: 'Those of you who have come to believe be mindful of Allah and be among the truthful.',
        source: 'Surah At-Tawbah',
        type: ContentType.quran,
        surahName: 'At-Tawbah',
        verseNumber: 119,
        keywords: ['taqwa', 'mindfulness', 'truthfulness', 'believers', 'honesty'],
      ),
      const ContentItem(
        id: '27',
        text: 'يَوْمَ نَدْعُو كُلَّ أُنَاسٍ بِإِمَامِهِمْ ۖ فَمَنْ أُوتِيَ كِتَابَهُ بِيَمِينِهِ فَأُولَٰئِكَ يَقْرَءُونَ كِتَابَهُمْ وَلَا يُظْلَمُونَ فَتِيلًا',
        translation: 'The day on which We will call upon each group of people by the one who leads them, then the one who will be given his book in his right hand then they themselves are going to be reading their book, it will not be wronged in the amount of an atom.',
        source: 'Surah Al-Isra',
        type: ContentType.quran,
        surahName: 'Al-Isra',
        verseNumber: 71,
        keywords: ['judgment day', 'book of deeds', 'justice', 'accountability', 'leaders'],
      ),
      const ContentItem(
        id: '28',
        text: 'وَاتْلُ مَا أُوحِيَ إِلَيْكَ مِن كِتَابِ رَبِّكَ ۖ لَا مُبَدِّلَ لِكَلِمَاتِهِ وَلَن تَجِدَ مِن دُونِهِ مُلْتَحَدًا',
        translation: 'And read whatever has been inspired to you from within the book of your master. There is no power whatsoever that can change His words and you will not find even the weakest form of refuge anywhere besides Him.',
        source: 'Surah Al-Kahf',
        type: ContentType.quran,
        surahName: 'Al-Kahf',
        verseNumber: 27,
        keywords: ['revelation', 'book', 'unchangeable', 'refuge', 'guidance'],
      ),
      const ContentItem(
        id: '29',
        text: 'وَعِبَادُ الرَّحْمَٰنِ الَّذِينَ يَمْشُونَ عَلَى الْأَرْضِ هَوْنًا وَإِذَا خَاطَبَهُمُ الْجَاهِلُونَ قَالُوا سَلَامًا',
        translation: 'The slaves of the incredibly loving and merciful one are those who walk on the earth humbly and when the obnoxious address them they speak peacefully.',
        source: 'Surah Al-Furqan',
        type: ContentType.quran,
        surahName: 'Al-Furqan',
        verseNumber: 63,
        keywords: ['humility', 'peace', 'mercy', 'character', 'gentleness'],
      ),
      const ContentItem(
        id: '30',
        text: 'وَأَنَّهُ هُوَ أَضْحَكَ وَأَبْكَىٰ',
        translation: 'And that He and only He is the one that causes laughter and causes tears.',
        source: 'Surah An-Najm',
        type: ContentType.quran,
        surahName: 'An-Najm',
        verseNumber: 43,
        keywords: ['laughter', 'tears', 'emotions', 'control', 'divine power'],
      ),
      const ContentItem(
        id: '2',
        text: 'وَاصْبِرْ وَمَا صَبْرُكَ إِلَّا بِاللَّهِ',
        translation: 'And be patient, and your patience is not but through Allah.',
        source: 'Surah An-Nahl',
        type: ContentType.quran,
        surahName: 'An-Nahl',
        verseNumber: 127,
        keywords: ['patience', 'sabr', 'trials', 'perseverance'],
      ),
      const ContentItem(
        id: '3',
        text: 'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
        translation: 'And We have not sent you except as a mercy to the worlds.',
        source: 'Surah Al-Anbiya',
        type: ContentType.quran,
        surahName: 'Al-Anbiya',
        verseNumber: 107,
        keywords: ['mercy', 'prophet', 'rahma', 'compassion'],
      ),
      const ContentItem(
        id: '4',
        text: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
        translation: 'Indeed, with hardship comes ease.',
        source: 'Surah Ash-Sharh',
        type: ContentType.quran,
        surahName: 'Ash-Sharh',
        verseNumber: 6,
        keywords: ['hardship', 'ease', 'hope', 'relief', 'difficulty'],
      ),
      const ContentItem(
        id: '5',
        text: 'وَبَشِّرِ الصَّابِرِينَ',
        translation: 'And give good tidings to the patient.',
        source: 'Surah Al-Baqarah',
        type: ContentType.quran,
        surahName: 'Al-Baqarah',
        verseNumber: 155,
        keywords: ['patience', 'good news', 'perseverance', 'sabr'],
      ),
      const ContentItem(
        id: '6',
        text: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
        translation: 'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
        source: 'Surah Al-Baqarah',
        type: ContentType.quran,
        surahName: 'Al-Baqarah',
        verseNumber: 152,
        keywords: ['remembrance', 'dhikr', 'gratitude', 'shukr'],
      ),
      // Hadith
      ContentItem(
        id: '7',
        text: 'مَنْ لَمْ يَشْكُرِ النَّاسَ لَمْ يَشْكُرِ اللَّهَ',
        translation: 'Whoever does not thank people, does not thank Allah.',
        source: 'Abu Dawud,  Abu Hurayrah',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['gratitude', 'people', 'thankfulness'],
      ),
      ContentItem(
        id: '8',
        text: 'الْمُؤْمِنُ لِلْمُؤْمِنِ كَالْبُنْيَانِ يَشُدُّ بَعْضُهُ بَعْضًا',
        translation: 'The believer to another believer is like a building whose different parts enforce each other.',
        source: 'Bukhari Muslim. Abu Musa',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['unity', 'brotherhood', 'support', 'community'],
      ),
      ContentItem(
        id: '9',
        text: 'خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ',
        translation: 'The best of people are those who are most beneficial to others.',
        source: 'Al-Tabarani',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.hasan,
        keywords: ['service', 'helping others', 'benefit', 'charity'],
      ),
      ContentItem(
        id: '10',
        text: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        translation: 'Actions are but by intention.',
        source: 'Bukhari. Umar bin Al-Khattab',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['intention', 'niyyah', 'sincerity', 'deeds'],
      ),
      ContentItem(
        id: '11',
        text: 'الدِّينُ النَّصِيحَةُ',
        translation: 'Religion is sincere advice.',
        source: 'Muslim',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['advice', 'sincerity', 'counsel', 'nasiha'],
      ),
      ContentItem(
        id: '12',
        text: 'مَنْ كَانَ فِي حَاجَةِ أَخِيهِ كَانَ اللَّهُ فِي حَاجَتِهِ',
        translation: 'Whoever fulfills the needs of his brother, Allah will fulfill his needs.',
        source: 'Bukhari',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['helping others', 'needs', 'service', 'brotherhood'],
      ),
      // New Hadith
      ContentItem(
        id: '34',
        text: 'لَا تُؤْمِنُوا حَتَّى تُحِبُّوا، وَلَا تُحِبُّوا حَتَّى تَحَابُّوا، أَوَلَا أَدُلُّكُمْ عَلَى شَيْءٍ إِذَا فَعَلْتُمُوهُ تَحَابَبْتُمْ؟ أَفْشُوا السَّلَامَ بَيْنَكُمْ',
        translation: 'You will not enter Paradise until you believe, and you will not believe until you love one another. Should I direct you to something that if you do it, you will love one another? Spread the greeting of peace (Salaam) among yourselves.',
        source: 'Sahih Muslim, # 54 Abu Hurayrah',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['love', 'brotherhood', 'salaam'],
      ),
      ContentItem(
        id: '35',
        text: 'يَا عِبَادِي إِنِّي حَرَّمْتُ الظُّلْمَ عَلَى نَفْسِي وَجَعَلْتُهُ بَيْنَكُمْ مُحَرَّمًا فَلَا تَظَالَمُوا، يَا عِبَادِي كُلُّكُمْ ضَالٌّ إِلَّا مَنْ هَدَيْتُهُ فَاسْتَهْدُونِي أَهْدِكُمْ، يَا عِبَادِي كُلُّكُمْ جَائِعٌ إِلَّا مَنْ أَطْعَمْتُهُ فَاسْتَطْعِمُونِي أُطْعِمْكُمْ، يَا عِبَادِي كُلُّكُمْ عَارٍ إِلَّا مَنْ كَسَوْتُهُ فَاسْتَكْسُونِي أَكْسُكُمْ',
        translation: 'O My servants, I have made oppression forbidden for Myself and I have made it forbidden among you, so do not oppress one another. O My servants, all of you are astray except those whom I guide, so seek guidance from Me and I will guide you. O My servants, all of you are hungry except those whom I feed, so seek food from Me and I will feed you. O My servants, all of you are naked except those whom I clothe, so seek clothing from Me and I will clothe you.',
        source: 'Sahih Muslim, # 2577 by Abu Dharr',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['oppression', 'guidance', 'divine mercy'],
      ),
      ContentItem(
        id: '36',
        text: 'إِنَّ أَحْسَنَكُمْ أَخْلَاقًا أَحَاسِنُكُمْ',
        translation: 'The best among you are those with the best manners and character.',
        source: 'Sahih al-Bukhari, # 6036. Abdullah ibn Amr',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['character', 'manners', 'behavior'],
      ),
      ContentItem(
        id: '37',
        text: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
        translation: 'Whoever believes in Allah and the Last Day should speak good or remain silent.',
        source: 'Sahih Muslim, #47. Abu Hurairah',
        type: ContentType.hadith,
        authenticity: AuthenticityLevel.sahih,
        keywords: ['speech', 'faith', 'judgment day'],
      ),
      // Quotes
      const ContentItem(
        id: '13',
        text: 'الصَّبْرُ مِفْتَاحُ الْفَرَجِ',
        translation: 'Patience is the key to relief.',
        source: 'Ali ibn Abi Talib',
        type: ContentType.quote,
        keywords: ['patience', 'sabr', 'relief', 'trials'],
      ),
      const ContentItem(
        id: '14',
        text: 'مَنْ طَلَبَ الْعِلْمَ لِغَيْرِ اللَّهِ أَوْ أَرَادَ بِهِ غَيْرَ اللَّهِ فَلْيَتَبَوَّأْ مَقْعَدَهُ مِنَ النَّارِ',
        translation: 'Whoever seeks knowledge for other than Allah or intends other than Allah with it, let him take his seat in the Fire.',
        source: 'Ibn Abbas',
        type: ContentType.quote,
        keywords: ['knowledge', 'sincerity', 'intention', 'learning'],
      ),
      const ContentItem(
        id: '15',
        text: 'إِذَا مَاتَ الإِنْسَانُ انْقَطَعَ عَنْهُ عَمَلُهُ إِلاَّ مِنْ ثَلاَثَةٍ',
        translation: 'When a person dies, his deeds come to an end except for three: ongoing charity, knowledge that benefits others, or a righteous child who prays for him.',
        source: 'Abu Hurairah',
        type: ContentType.quote,
        keywords: ['legacy', 'charity', 'knowledge', 'children', 'afterlife'],
      ),
      const ContentItem(
        id: '16',
        text: 'أَحِبُّوا اللَّهَ لِمَا يَغْذُوكُمْ مِنْ نِعَمِهِ',
        translation: 'Love Allah for the blessings He nourishes you with.',
        source: 'Umar ibn Al-Khattab',
        type: ContentType.quote,
        keywords: ['love', 'blessings', 'gratitude', 'devotion'],
      ),
      const ContentItem(
        id: '17',
        text: 'الدُّنْيَا دَارُ مَنْ لا دَارَ لَهُ، وَمَالُ مَنْ لا مَالَ لَهُ',
        translation: 'This world is the home of one who has no home, and the wealth of one who has no wealth.',
        source: 'Ali ibn Abi Talib',
        type: ContentType.quote,
        keywords: ['worldly life', 'perspective', 'priorities', 'detachment'],
      ),
      const ContentItem(
        id: '18',
        text: 'لا تَكُنْ رَطْبًا فَتُعْصَرَ وَلا يَابِسًا فَتُكْسَرَ',
        translation: 'Do not be so soft that you are squeezed, nor so hard that you are broken.',
        source: 'Umar ibn Al-Khattab',
        type: ContentType.quote,
        keywords: ['balance', 'character', 'wisdom', 'moderation'],
      ),
      // New Sayings/Quotes
      const ContentItem(
        id: '31',
        text: ' ',
        translation: 'Our hands are a gift. How much did you pay for your hand? Did you buy it from Amazon.com?',
        source: 'A Wise Man',
        type: ContentType.quote,
        keywords: ['grateful', 'thankful', 'gratitude'],
      ),
      const ContentItem(
        id: '32',
        text: '',
        translation: 'If you give a gift to someone, and they start thanking the gift instead of you. Then, there is something wrong.',
        source: 'iERA',
        type: ContentType.quote,
        keywords: ['grateful', 'thankful', 'gratitude'],
      ),
      const ContentItem(
        id: '33',
        text: '',
        translation: 'The comedian and actor Robin Williams had millions of dollars. He had fame and fortune. He killed himself. He hanged himself. What was he missing? The remembrance of Allah',
        source: 'Thinker',
        type: ContentType.quote,
        keywords: ['peace', 'tranquility', 'death'],
      ),
    ];
  }

  // ---------- Khutbah operations ----------
  static Future<void> saveKhutbah(Khutbah khutbah) async {
    try {
      if (kIsWeb) {
        final list = await _prefsGetJsonList(_webKhutbahsKey);
        final existingIndex = list.indexWhere((e) => e['id'] == khutbah.id);
        if (existingIndex >= 0) {
          list[existingIndex] = khutbah.toJson();
        } else {
          list.add(khutbah.toJson());
        }
        await _prefsSetJsonList(_webKhutbahsKey, list);
      } else {
        final db = await database;
        await db.insert(
          khutbahTable,
          khutbah.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw Exception('Failed to save khutbah: ${e.toString()}');
    }
  }

  static Future<List<Khutbah>> getAllKhutbahs() async {
    try {
      if (kIsWeb) {
        final list = await _prefsGetJsonList(_webKhutbahsKey);
        // Sort by modifiedAt DESC
        list.sort((a, b) => (b['modifiedAt'] as String).compareTo(a['modifiedAt'] as String));
        return list.map((map) => Khutbah.fromJson(map)).toList();
      } else {
        final db = await database;
        final maps = await db.query(khutbahTable, orderBy: 'modifiedAt DESC');
        return maps.map((map) => Khutbah.fromJson(map)).toList();
      }
    } catch (e) {
      throw Exception('Failed to load khutbahs: ${e.toString()}');
    }
  }

  static Future<Khutbah?> getKhutbah(String id) async {
    if (kIsWeb) {
      final list = await _prefsGetJsonList(_webKhutbahsKey);
      final map = list.cast<Map<String, dynamic>?>().firstWhere((e) => e?['id'] == id, orElse: () => null);
      return map != null ? Khutbah.fromJson(map) : null;
    } else {
      final db = await database;
      final maps = await db.query(khutbahTable, where: 'id = ?', whereArgs: [id]);
      return maps.isNotEmpty ? Khutbah.fromJson(maps.first) : null;
    }
  }

  static Future<void> deleteKhutbah(String id) async {
    if (kIsWeb) {
      final list = await _prefsGetJsonList(_webKhutbahsKey);
      list.removeWhere((e) => e['id'] == id);
      await _prefsSetJsonList(_webKhutbahsKey, list);
    } else {
      final db = await database;
      await db.delete(khutbahTable, where: 'id = ?', whereArgs: [id]);
    }
  }

  // ---------- Content operations ----------
  static Future<List<ContentItem>> searchContent(String query) async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      final q = query.toLowerCase();
      final results = list.where((m) {
        final text = (m['text'] as String).toLowerCase();
        final translation = (m['translation'] as String).toLowerCase();
        final keywords = (m['keywords'] as String? ?? '').toLowerCase();
        return text.contains(q) || translation.contains(q) || keywords.contains(q);
      }).toList();
      return results.map((m) => ContentItem.fromJson(m)).toList();
    } else {
      final db = await database;
      final maps = await db.query(
        contentTable,
        where: 'keywords LIKE ? OR text LIKE ? OR translation LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );
      return maps.map((map) => ContentItem.fromJson(map)).toList();
    }
  }

  static Future<List<ContentItem>> getContentByType(ContentType type) async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      final filtered = list.where((m) => m['type'] == type.name).toList();
      return filtered.map((m) => ContentItem.fromJson(m)).toList();
    } else {
      final db = await database;
      final maps = await db.query(
        contentTable,
        where: 'type = ?',
        whereArgs: [type.name],
      );
      return maps.map((map) => ContentItem.fromJson(map)).toList();
    }
  }

  static Future<void> addContentItem(ContentItem item) async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      final existingIndex = list.indexWhere((e) => e['id'] == item.id);
      if (existingIndex >= 0) {
        list[existingIndex] = item.toJson();
      } else {
        list.add(item.toJson());
      }
      await _prefsSetJsonList(_webContentKey, list);
    } else {
      final db = await database;
      await db.insert(
        contentTable,
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<ContentItem>> getAllContent() async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      list.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
      return list.map((m) => ContentItem.fromJson(m)).toList();
    } else {
      final db = await database;
      final maps = await db.query(contentTable, orderBy: 'id ASC');
      return maps.map((map) => ContentItem.fromJson(map)).toList();
    }
  }

  static Future<void> deleteContentItem(String id) async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      list.removeWhere((e) => e['id'] == id);
      await _prefsSetJsonList(_webContentKey, list);
    } else {
      final db = await database;
      await db.delete(contentTable, where: 'id = ?', whereArgs: [id]);
    }
  }

  static Future<void> updateContentItem(ContentItem item) async {
    if (kIsWeb) {
      await addContentItem(item);
    } else {
      final db = await database;
      await db.update(
        contentTable,
        item.toJson(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
  }

  static Future<bool> contentItemExists(String id) async {
    if (kIsWeb) {
      await _ensureWebContentInitialized();
      final list = await _prefsGetJsonList(_webContentKey);
      return list.any((e) => e['id'] == id);
    } else {
      final db = await database;
      final maps = await db.query(contentTable, where: 'id = ?', whereArgs: [id]);
      return maps.isNotEmpty;
    }
  }

  /// Manually update content library with new items (for existing users)
  static Future<void> updateContentLibrary() async {
    final allSampleItems = _sampleContentItems();
    
    for (final item in allSampleItems) {
      final exists = await contentItemExists(item.id);
      if (!exists) {
        await addContentItem(item);
      }
    }
  }
}
