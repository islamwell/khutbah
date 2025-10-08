enum TemplateType { standard, eid, social, youth, general }

class Template {
  final String id;
  final String name;
  final String content;
  final TemplateType type;
  final String description;
  final String? thumbnail;

  const Template({
    required this.id,
    required this.name,
    required this.content,
    required this.type,
    required this.description,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'type': type.name,
        'description': description,
        'thumbnail': thumbnail,
      };

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        type: TemplateType.values.firstWhere((e) => e.name == json['type']),
        description: json['description'] as String,
        thumbnail: json['thumbnail'] as String?,
      );
}

// Predefined templates
class DefaultTemplates {
  static const standardTemplate = Template(
    id: 'standard',
    name: 'Standard Khutbah',
    description: 'Traditional Friday Khutbah structure with Arabic openings and closings',
    type: TemplateType.standard,
    content: '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ

الْحَمْدُ لِلَّهِ نَحْمَدُهُ وَنَسْتَعِينُهُ وَنَسْتَغْفِرُهُ، وَنَعُوذُ بِاللَّهِ مِنْ شُرُورِ أَنْفُسِنَا وَمِنْ سَيِّئَاتِ أَعْمَالِنَا، مَنْ يَهْدِهِ اللَّهُ فَلَا مُضِلَّ لَهُ، وَمَنْ يُضْلِلْ فَلَا هَادِيَ لَهُ، وَأَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ.

يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ حَقَّ تُقَاتِهِ وَلَا تَمُوتُنَّ إِلَّا وَأَنْتُمْ مُسْلِمُونَ

Brothers and sisters in Islam,

[MAIN TOPIC - First Part]

---

[Break for sitting/jalsah]

---

[MAIN TOPIC - Second Part]

الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى أَشْرَفِ الْأَنْبِيَاءِ وَالْمُرْسَلِينَ نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ.

رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ''',
  );

  static const eidTemplate = Template(
    id: 'eid',
    name: 'Eid Khutbah',
    description: 'Special template for Eid celebrations',
    type: TemplateType.eid,
    content: '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ

اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ لَا إِلَهَ إِلَّا اللَّهُ
اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ وَلِلَّهِ الْحَمْدُ

الْحَمْدُ لِلَّهِ الَّذِي شَرَعَ لَنَا الْأَعْيَادَ وَجَعَلَهَا مَوَاسِمَ لِلْفَرَحِ وَالسُّرُورِ

Brothers and sisters, on this blessed day of Eid,

[EID TOPIC - Gratitude and Joy in Islam]

---

[Break for sitting/jalsah]

---

[EID TOPIC - Community and Unity]

نَسْأَلُ اللَّهَ أَنْ يَتَقَبَّلَ مِنَّا وَمِنْكُمْ صَالِحَ الْأَعْمَالِ
رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ''',
  );

  static const salaamGreetingTemplate = Template(
    id: 'salaam_greeting',
    name: 'Assalamo Alaykum - Spreading Peace',
    description: 'Comprehensive khutbah about the importance and rewards of the Islamic greeting',
    type: TemplateType.social,
    content: '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ

الْحَمْدُ لِلَّهِ نَحْمَدُهُ وَنَسْتَعِينُهُ وَنَسْتَغْفِرُهُ، وَنَعُوذُ بِاللَّهِ مِنْ شُرُورِ أَنْفُسِنَا وَمِنْ سَيِّئَاتِ أَعْمَالِنَا

يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ حَقَّ تُقَاتِهِ وَلَا تَمُوتُنَّ إِلَّا وَأَنْتُمْ مُسْلِمُونَ

Introduction: The Timeless Sunnah of Salaam

Assalamo alaykum.

Dear Brothers and sisters, we live in a world hungry for connection, troubled by division, and yearning for peace. Yet, Allah ﷻ has given this Ummah a key to healing and unity—a practice that is simple, profound, and life-changing: the greeting of Assalamo alaykum.

This greeting is NOT just words. It is:
• The DNA of Islam
• A direct link to paradise
• A powerful daily Sunnah of our beloved Prophet ﷺ

---

The Quranic Command on Salaam

وَإِذَا حُيِّيتُم بِتَحِيَّةٍ فَحَيُّوا بِأَحْسَنَ مِنْهَا أَوْ رُدُّوهَا

"And when you are greeted with a greeting, greet in return with what is better than it or (at least) return it equally." (Quran 4:86)

---

The Story of Adam: The First Salaam

The Prophet ﷺ said: "When Allah created Adam, He said: 'Go to those angels and say, As-Salamu alaikum.' They replied, 'Wa Alaika as-Salamu wa Rahmatullah.' Then He said: 'This is your greeting and the greeting of your children among each other.'" (Sahih Bukhari & Muslim)

---

Greet Those You Know AND Those You Don't Know

The Messenger of Allah ﷺ was asked: "Which deed in Islam is the best?" He said: "Feeding people and greeting those you know and those you do not know." (Sahih Bukhari & Muslim)

---

The Reward for Being FIRST to Give Salaam

The Prophet ﷺ said: "The person nearest to Allah is one who is the first to offer greeting." (Abu Dawud, At-Tirmidhi)

The one who initiates salaam:
1. Rises above the ego
2. Conquers shyness
3. Takes the first step toward connection
4. Is CLOSEST TO ALLAH!

---

Salaam: The Path to Paradise

The Prophet ﷺ said: "You will not enter Paradise until you believe, and you will not believe until you love one another. Shall I not guide you to something which, if you do, you will love one another? Spread Salaam among yourselves." (Sahih Muslim)

---

[Break for sitting/jalsah]

---

The Chain to Paradise:
1. Salaam → Leads to Love for each other
2. Love for each other → Leads to Faith/iman
3. Faith/iman → Leads to Paradise

الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ''',
  );

  static List<Template> get all => [standardTemplate, eidTemplate, salaamGreetingTemplate];
}