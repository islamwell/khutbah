-- Sample data for PulpitFlow Database

-- Helper function to insert users into auth.users and return their UUID
CREATE OR REPLACE FUNCTION insert_user_to_auth(email TEXT, password TEXT)
RETURNS UUID AS $$
DECLARE
    user_id UUID;
BEGIN
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
    VALUES (
        '00000000-0000-0000-0000-000000000000', -- Default instance_id
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        email,
        crypt(password, gen_salt('bf')),
        NOW(),
        NOW(),
        NOW()
    )
    RETURNING id INTO user_id;
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert users into auth.users and then into the public.users table
INSERT INTO users (id, email, full_name)
SELECT insert_user_to_auth('john.doe@example.com', 'password123'), 'john.doe@example.com', 'John Doe'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'john.doe@example.com');

INSERT INTO users (id, email, full_name)
SELECT insert_user_to_auth('jane.smith@example.com', 'securepass'), 'jane.smith@example.com', 'Jane Smith'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'jane.smith@example.com');

INSERT INTO users (id, email, full_name)
SELECT insert_user_to_auth('admin@pulpitflow.com', 'adminpass'), 'admin@pulpitflow.com', 'PulpitFlow Admin'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@pulpitflow.com');


-- Insert Folders
INSERT INTO folders (user_id, name, description)
SELECT id, 'My First Khutbahs', 'A collection of my initial khutbah drafts.'
FROM users
WHERE email = 'john.doe@example.com';

INSERT INTO folders (user_id, name, description)
SELECT id, 'Eid Khutbahs', 'Special khutbahs for Eid al-Fitr and Eid al-Adha.'
FROM users
WHERE email = 'john.doe@example.com';

INSERT INTO folders (user_id, name, description)
SELECT id, 'Community Talks', 'Khutbahs prepared for local community events.'
FROM users
WHERE email = 'jane.smith@example.com';


-- Insert Khutbahs
INSERT INTO khutbahs (user_id, folder_id, title, content, tags, estimated_minutes)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    (SELECT id FROM folders WHERE user_id = (SELECT id FROM users WHERE email = 'john.doe@example.com') AND name = 'My First Khutbahs'),
    'The Importance of Gratitude',
    'Bismillah ar-Rahman ar-Rahim. All praise is due to Allah, Lord of the worlds... Brothers and sisters, today we reflect on the profound importance of gratitude in our lives. Gratitude is not merely a fleeting emotion, but a fundamental principle in Islam, a cornerstone of our faith. Allah (SWT) reminds us in the Quran, "If you are grateful, I will surely increase you [in favor]; but if you deny, indeed, My punishment is severe." (Surah Ibrahim, 14:7). This verse encapsulates the essence of our discussion today. Gratitude, or ''shukr'' in Arabic, is a state of being that encompasses acknowledging, appreciating, and expressing thanks for the blessings bestowed upon us by our Creator. It''s a recognition that everything we possess, from our health to our wealth, from our families to our faith, originates from Allah''s infinite mercy and generosity. When we cultivate a heart of gratitude, we open ourselves to further blessings. It shifts our perspective from what we lack to what we have, fostering contentment and inner peace. It also strengthens our relationship with Allah, as we constantly remember His favors upon us. Let us strive to be among the grateful, for indeed, gratitude is a key to unlocking immense blessings in this life and the Hereafter. May Allah make us among those who are truly thankful. Ameen.',
    'gratitude, shukr, blessings, islam, faith',
    20;

INSERT INTO khutbahs (user_id, folder_id, title, content, tags, estimated_minutes)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    (SELECT id FROM folders WHERE user_id = (SELECT id FROM users WHERE email = 'john.doe@example.com') AND name = 'Eid Khutbahs'),
    'Eid al-Fitr: A Celebration of Thankfulness',
    'Assalamu Alaikum wa Rahmatullahi wa Barakatuh. Eid Mubarak! On this blessed day of Eid al-Fitr, after a month of spiritual reflection and devotion during Ramadan, we gather to celebrate the completion of our fasting and to express our profound gratitude to Allah (SWT). This Eid is not just a day of festivities, but a day of immense thankfulness. We thank Allah for giving us the strength to fast, to stand in prayer, and to recite His glorious Quran. We thank Him for the countless blessings He has showered upon us, seen and unseen. The spirit of Eid is one of joy, forgiveness, and community. It is a time to strengthen family bonds, reach out to neighbors, and extend charity to those less fortunate. Let us remember the teachings of Ramadan and carry its spirit of piety, generosity, and self-discipline into the rest of the year. May Allah accept our fasting, our prayers, and our good deeds. May He unite our hearts and grant us peace and prosperity. Eid Mubarak once again!',
    'eid, ramadan, celebration, thankfulness, community',
    18;

INSERT INTO khutbahs (user_id, folder_id, title, content, tags, estimated_minutes)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    (SELECT id FROM folders WHERE user_id = (SELECT id FROM users WHERE email = 'jane.smith@example.com') AND name = 'Community Talks'),
    'Building Strong Communities',
    'Dear respected brothers and sisters, it is a great honor to stand before you today to discuss a topic that is vital for our collective well-being: building strong communities. In Islam, the concept of community, or ''ummah'', is paramount. Our Prophet Muhammad (PBUH) taught us that believers are like a single structure, each part supporting the other. A strong community is built on principles of mutual respect, compassion, cooperation, and justice. It is where individuals feel safe, supported, and empowered to contribute positively. We must strive to foster environments where our youth can thrive, where the elderly are honored, and where the vulnerable are protected. This requires active participation from each one of us – volunteering our time, sharing our knowledge, and extending a helping hand. Let us work together to create communities that reflect the beautiful values of Islam, serving as beacons of light and hope for all. May Allah guide us in our efforts. Ameen.',
    'community, ummah, unity, cooperation, youth',
    22;


-- Insert Templates
INSERT INTO templates (user_id, name, content, type, description, is_public)
SELECT
    NULL, -- System template
    'Standard Khutbah Structure',
    'Bismillah ar-Rahman ar-Rahim. All praise is due to Allah, Lord of the worlds...
[Introduction: Praise Allah, send salutations upon the Prophet (PBUH), and briefly introduce the topic.]

[First Part of Khutbah: Develop the main theme, using Quranic verses, Hadith, and Islamic wisdom. Provide examples and explanations.]

[Second Part of Khutbah: Continue developing the theme, perhaps with practical advice, warnings, or encouragement. Emphasize action and reflection.]

[Dua/Supplication: Conclude with a heartfelt prayer for the community, the Ummah, and humanity. Ask for forgiveness, guidance, and blessings.]

[Closing: Briefly remind the congregation of the main message and end with a final salutation.]
Assalamu Alaikum wa Rahmatullahi wa Barakatuh.',
    'standard',
    'A general template for structuring a typical Friday khutbah.',
    TRUE;

INSERT INTO templates (user_id, name, content, type, description, is_public)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'My Personal Reflection Template',
    'Opening: Reflect on a personal experience or observation related to the topic.
Quranic Insight: Connect the experience to a relevant Quranic verse.
Hadith Guidance: Support with a Hadith that provides further guidance.
Practical Steps: Offer 2-3 actionable steps for the audience.
Closing Dua: A short, personal supplication.',
    'general',
    'A template for khutbahs that incorporate personal reflections.',
    FALSE;

INSERT INTO templates (user_id, name, content, type, description, is_public)
SELECT
    NULL, -- System template
    'Eid Khutbah Outline',
    'Opening Takbirat: Allahu Akbar, Allahu Akbar, La ilaha illallah...
Praise and Salutations: Praise Allah, send salutations upon the Prophet (PBUH).
Eid Significance: Briefly explain the significance of Eid (Fitr or Adha).
Ramadan/Hajj Reflection: Connect to the preceding acts of worship (Ramadan for Fitr, Hajj for Adha).
Community & Charity: Emphasize unity, forgiveness, and giving to the needy.
Dua: Special Eid supplication for the Ummah.
Closing: Eid Mubarak!',
    'eid',
    'A structured outline specifically for Eid khutbahs.',
    TRUE;


-- Insert Content Items
INSERT INTO content_items (user_id, text, translation, source, type, authenticity, surah_name, verse_number, keywords, is_public)
SELECT
    NULL, -- System content
    'إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّىٰ يُغَيِّرُوا مَا بِأَنفُسِهِمْ',
    'Indeed, Allah will not change the condition of a people until they change what is in themselves.',
    'Quran 13:11',
    'quran',
    NULL,
    'Ar-Ra''d',
    11,
    'change, self-improvement, divine decree',
    TRUE;

INSERT INTO content_items (user_id, text, translation, source, type, authenticity, surah_name, verse_number, keywords, is_public)
SELECT
    NULL, -- System content
    'قُلْ هُوَ اللَّهُ أَحَدٌ اللَّهُ الصَّمَدُ لَمْ يَلِدْ وَلَمْ يُولَدْ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    'Say, "He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent."',
    'Quran 112:1-4',
    'quran',
    NULL,
    'Al-Ikhlas',
    1,
    'tawhid, oneness of Allah, sincerity',
    TRUE;

INSERT INTO content_items (user_id, text, translation, source, type, authenticity, surah_name, verse_number, keywords, is_public)
SELECT
    NULL, -- System content
    'عَنْ أَبِي هُرَيْرَةَ رَضِيَ اللَّهُ عَنْهُ قَالَ: قَالَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ: "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ"',
    'Narrated Abu Huraira: The Prophet (PBUH) said, "Whoever believes in Allah and the Last Day should speak good or remain silent."',
    'Sahih Bukhari',
    'hadith',
    'sahih',
    NULL,
    NULL,
    'speech, silence, belief, last day',
    TRUE;

INSERT INTO content_items (user_id, text, translation, source, type, authenticity, surah_name, verse_number, keywords, is_public)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'The best way to predict the future is to create it.',
    'The best way to predict the future is to create it.',
    'Peter Drucker',
    'quote',
    NULL,
    NULL,
    NULL,
    'future, creation, motivation',
    FALSE;

INSERT INTO content_items (user_id, text, translation, source, type, authenticity, surah_name, verse_number, keywords, is_public)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    'Seek knowledge from the cradle to the grave.',
    'Seek knowledge from the cradle to the grave.',
    'Prophetic Saying (attributed)',
    'quote',
    'unknown',
    NULL,
    NULL,
    'knowledge, learning, education',
    FALSE;


-- Insert User Favorites
INSERT INTO user_favorites (user_id, item_type, item_id)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'content_item',
    (SELECT id FROM content_items WHERE source = 'Quran 13:11' AND user_id IS NULL);

INSERT INTO user_favorites (user_id, item_type, item_id)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'template',
    (SELECT id FROM templates WHERE name = 'Standard Khutbah Structure' AND user_id IS NULL);

INSERT INTO user_favorites (user_id, item_type, item_id)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    'content_item',
    (SELECT id FROM content_items WHERE source = 'Sahih Bukhari' AND user_id IS NULL);

INSERT INTO user_favorites (user_id, item_type, item_id)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    'template',
    (SELECT id FROM templates WHERE name = 'Eid Khutbah Outline' AND user_id IS NULL);


-- Insert Search History
INSERT INTO search_history (user_id, query, result_count)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'gratitude khutbah',
    5;

INSERT INTO search_history (user_id, query, result_count)
SELECT
    (SELECT id FROM users WHERE email = 'john.doe@example.com'),
    'eid al-fitr',
    3;

INSERT INTO search_history (user_id, query, result_count)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    'community building',
    7;

INSERT INTO search_history (user_id, query, result_count)
SELECT
    (SELECT id FROM users WHERE email = 'jane.smith@example.com'),
    'hadith on patience',
    12;

-- Clean up the helper function
DROP FUNCTION IF EXISTS insert_user_to_auth(TEXT, TEXT);