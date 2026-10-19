import '../models/phone.dart';

final List<Phone> samplePhones = [
  const Phone(
    id: 'iphone_15_pro_max',
    name: 'آبل آيفون 15 برو ماكس',
    brand: 'آبل',
    description:
        'تصميم استثنائي من التيتانيوم فائق القوة والخفة مع حواف أنحف وأقوى زجاج في هاتف ذكي، مزود بشريحة A17 Pro الرائدة ونظام كاميرات احترافي بدقة 48 ميجابكسل وزوم بصري 5x.',
    images: [
      'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1695048065059-d4bf453bc9fe?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['تيتانيوم طبيعي', 'تيتانيوم أزرق', 'تيتانيوم أسود', 'تيتانيوم أبيض'],
    variants: [
      PhoneVariant(storage: '256 جيجابايت', price: 4799, originalPrice: 5199),
      PhoneVariant(storage: '512 جيجابايت', price: 5499, originalPrice: 5899),
      PhoneVariant(storage: '1 تيرابايت', price: 6399, originalPrice: 6799),
    ],
    specs: PhoneSpec(
      screen: '6.7 بوصة Super Retina XDR OLED (120Hz)',
      processor: 'Apple A17 Pro (3 نانومتر)',
      ram: '8 جيجابايت',
      camera: 'ثلاثية: 48 + 12 + 12 ميجابكسل، وتقريب 5x',
      battery: '4422 مللي أمبير تدعم الشحن اللاسلكي MagSafe',
      os: 'iOS 17 قابل للتحديث لـ iOS 18',
    ),
    rating: 4.9,
    reviewsCount: 342,
    isFeatured: true,
    isNew: true,
  ),
  const Phone(
    id: 'samsung_s24_ultra',
    name: 'سامسونج جالاكسي S24 ألترا',
    brand: 'سامسونج',
    description:
        'عصر الذكاء الاصطناعي Galaxy AI وصل. إطار متين من التيتانيوم، قلم S-Pen مدمج، شاشة مسطحة مذهلة بتقنية مضادة للانعكاس، ومعالج Snapdragon 8 Gen 3 فائق القوة.',
    images: [
      'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['رمادي تيتانيوم', 'أسود تيتانيوم', 'بنفسجي تيتانيوم', 'أصفر تيتانيوم'],
    variants: [
      PhoneVariant(storage: '256 جيجابايت', price: 4499, originalPrice: 4899),
      PhoneVariant(storage: '512 جيجابايت', price: 5199, originalPrice: 5599),
      PhoneVariant(storage: '1 تيرابايت', price: 6199, originalPrice: 6599),
    ],
    specs: PhoneSpec(
      screen: '6.8 بوصة Dynamic LTPO AMOLED 2X (120Hz، 2600 nits)',
      processor: 'Snapdragon 8 Gen 3 مخصص لجالاكسي',
      ram: '12 جيجابايت',
      camera: 'رباعية: 200 + 50 + 10 + 12 ميجابكسل وزوم 100x',
      battery: '5000 مللي أمبير، شحن سريع بقدرة 45W',
      os: 'أندرويد 14 مع واجهة One UI 6.1 وذكاء اصطناعي',
    ),
    rating: 4.8,
    reviewsCount: 289,
    isFeatured: true,
    isNew: true,
  ),
  const Phone(
    id: 'google_pixel_8_pro',
    name: 'جوجل بكسل 8 برو',
    brand: 'جوجل',
    description:
        'أذكى هاتف ذكي مع معالج Google Tensor G3 المطور، شاشة Super Actua ساطعة، وأقوى كاميرا معالجة بالذكاء الاصطناعي لالتقاط صور وفيديوهات تحبس الأنفاس.',
    images: [
      'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['أزرق خلاب', 'بورسلان', 'أسود سبج'],
    variants: [
      PhoneVariant(storage: '128 جيجابايت', price: 3299, originalPrice: 3599),
      PhoneVariant(storage: '256 جيجابايت', price: 3699, originalPrice: 3999),
      PhoneVariant(storage: '512 جيجابايت', price: 4299),
    ],
    specs: PhoneSpec(
      screen: '6.7 بوصة LTPO OLED بدقة QHD+ (120Hz)',
      processor: 'Google Tensor G3 (4 نانومتر)',
      ram: '12 جيجابايت',
      camera: 'ثلاثية: 50 + 48 + 48 ميجابكسل، ميزة Best Take',
      battery: '5050 مللي أمبير، شحن سريع 30W',
      os: 'أندرويد 14 الخام مع 7 سنوات تحديثات مؤكدة',
    ),
    rating: 4.7,
    reviewsCount: 154,
    isFeatured: true,
    isNew: false,
  ),
  const Phone(
    id: 'xiaomi_14_ultra',
    name: 'شاومي 14 ألترا Leica',
    brand: 'شاومي',
    description:
        'قمة التصوير الاحترافي بالتعاون مع Leica الألمانية. مستشعر رئيسي بحجم 1 بوصة بفتحة عدسة متغيرة، وشاشة مذهلة بدقة WQHD+ وسطوع خيالي.',
    images: [
      'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['جلد نباتي أسود', 'جلد نباتي أبيض'],
    variants: [
      PhoneVariant(storage: '512 جيجابايت', price: 4299, originalPrice: 4699),
    ],
    specs: PhoneSpec(
      screen: '6.73 بوصة LTPO AMOLED بدقة 1440x3200 (120Hz)',
      processor: 'Qualcomm Snapdragon 8 Gen 3',
      ram: '16 جيجابايت',
      camera: 'رباعية 50 ميجابكسل بجميع العدسات بالتعاون مع لايكا',
      battery: '5000 مللي أمبير وشحن فائق السرعة 90W سلكي / 80W لاسلكي',
      os: 'Xiaomi HyperOS مبني على أندرويد 14',
    ),
    rating: 4.8,
    reviewsCount: 198,
    isFeatured: false,
    isNew: true,
  ),
  const Phone(
    id: 'oneplus_12',
    name: 'وان بلس 12 Flagship',
    brand: 'وان بلس',
    description:
        'السرعة والنعومة المطلقة بفضل كاميرات Hasselblad الجيل الرابع، وشحن بقوة 100 واط يعيد شحن هاتفك بالكامل في 26 دقيقة فقط.',
    images: [
      'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['زمردي مموج', 'أسود حريري'],
    variants: [
      PhoneVariant(storage: '256 جيجابايت', price: 2999, originalPrice: 3399),
      PhoneVariant(storage: '512 جيجابايت', price: 3499, originalPrice: 3799),
    ],
    specs: PhoneSpec(
      screen: '6.82 بوصة ProXDR LTPO بدقة 3168x1440 سطوع 4500 nits',
      processor: 'Snapdragon 8 Gen 3 مع تبريد Dual Cryo-velocity',
      ram: '16 جيجابايت LPDDR5X',
      camera: 'ثلاثية: 50 + 64 (بيريسكوب 3x) + 48 ميجابكسل',
      battery: '5400 مللي أمبير وشحن SuperVOOC 100W',
      os: 'OxygenOS 14 المستند إلى أندرويد 14',
    ),
    rating: 4.7,
    reviewsCount: 140,
    isFeatured: false,
    isNew: false,
  ),
  const Phone(
    id: 'iphone_15_base',
    name: 'آبل آيفون 15 الأساسي',
    brand: 'آبل',
    description:
        'الميزة الديناميكية Dynamic Island، كاميرا رئيسية بدقة 48 ميجابكسل بتكبير 2x بجودة بصرية، وتصميم زجاجي خلفي متين بلمسة مطفية ومنفذ USB-C العالمي.',
    images: [
      'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1530319067432-f2a729c03db5?w=800&auto=format&fit=crop&q=80',
    ],
    colors: ['وردي', 'أزرق سماوي', 'أخضر باستيل', 'أصفر', 'أسود'],
    variants: [
      PhoneVariant(storage: '128 جيجابايت', price: 3249, originalPrice: 3499),
      PhoneVariant(storage: '256 جيجابايت', price: 3649, originalPrice: 3899),
    ],
    specs: PhoneSpec(
      screen: '6.1 بوصة Super Retina XDR OLED',
      processor: 'Apple A16 Bionic',
      ram: '6 جيجابايت',
      camera: 'مزدوجة: 48 + 12 ميجابكسل بدقة تصوير سينمائي 4K HDR',
      battery: '3349 مللي أمبير تدوم يوماً كاملاً',
      os: 'iOS 17',
    ),
    rating: 4.6,
    reviewsCount: 220,
    isFeatured: false,
    isNew: false,
  ),
];
