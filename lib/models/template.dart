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
    description: 'Comprehensive khutbah about the importance and rewards of the Islamic greeting with full HTML formatting',
    type: TemplateType.social,
    content: '''HTML:assets/templates/AssalamoAlaykumGreeting.html''',
  );

  static const livingBookTemplate = Template(
    id: 'living_book',
    name: 'The Living Book for Living People',
    description: 'Powerful khutbah on remembering Allah and making the Quran a living part of our daily lives',
    type: TemplateType.general,
    content: '''HTML:assets/templates/LivingBookForLivingPeople.html''',
  );

  static List<Template> get all => [
    standardTemplate, 
    eidTemplate, 
    salaamGreetingTemplate,
    livingBookTemplate,
  ];
}