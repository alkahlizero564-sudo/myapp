class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double oldPrice;
  final String emoji;
  final String color;
  final double rating;
  final int reviews;
  final bool isNew;
  final List<String> features;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.emoji,
    required this.color,
    required this.rating,
    required this.reviews,
    required this.isNew,
    required this.features,
  });

  int get discount => ((1 - price / oldPrice) * 100).round();
}

const products = <Product>[
  Product(
    id: 'iphone-15-pro',
    name: 'iPhone 15 Pro Max',
    brand: 'Apple',
    description:
        'هاتف احترافي بأداء مذهل وتصميم من التيتانيوم، مزود بكاميرا متطورة وشريحة A17 Pro.',
    price: 4899,
    oldPrice: 5299,
    emoji: '📱',
    color: '0xFFE8EAF6',
    rating: 4.9,
    reviews: 328,
    isNew: true,
    features: [
      'شريحة A17 Pro',
      'كاميرا رئيسية 48 ميجابكسل',
      'شاشة Super Retina XDR',
      'ذاكرة 256 جيجابايت',
    ],
  ),
  Product(
    id: 'galaxy-s24-ultra',
    name: 'Galaxy S24 Ultra',
    brand: 'Samsung',
    description:
        'تجربة ذكاء اصطناعي متكاملة مع قلم S Pen وكاميرا احترافية وتقريب بصري مذهل.',
    price: 3999,
    oldPrice: 4499,
    emoji: '📱',
    color: '0xFFE0F2F1',
    rating: 4.8,
    reviews: 241,
    isNew: true,
    features: [
      'معالج Snapdragon 8 Gen 3',
      'كاميرا 200 ميجابكسل',
      'قلم S Pen مدمج',
      'ذاكرة 256 جيجابايت',
    ],
  ),
  Product(
    id: 'pixel-8-pro',
    name: 'Pixel 8 Pro',
    brand: 'Google',
    description:
        'التقط صوراً استثنائية مع أفضل تقنيات الذكاء الاصطناعي من Google وتجربة أندرويد نقية.',
    price: 2899,
    oldPrice: 3199,
    emoji: '📱',
    color: '0xFFFFF3E0',
    rating: 4.7,
    reviews: 156,
    isNew: false,
    features: [
      'معالج Google Tensor G3',
      'كاميرا ثلاثية احترافية',
      'شاشة LTPO OLED',
      'ذاكرة 128 جيجابايت',
    ],
  ),
  Product(
    id: 'xiaomi-14',
    name: 'Xiaomi 14',
    brand: 'Xiaomi',
    description:
        'أداء فائق وشحن سريع جداً في هاتف أنيق وخفيف يناسب احتياجاتك اليومية.',
    price: 2199,
    oldPrice: 2499,
    emoji: '📱',
    color: '0xFFF3E5F5',
    rating: 4.6,
    reviews: 189,
    isNew: false,
    features: [
      'معالج Snapdragon 8 Gen 3',
      'كاميرا Leica',
      'شحن سريع 90 واط',
      'ذاكرة 256 جيجابايت',
    ],
  ),
  Product(
    id: 'oneplus-12',
    name: 'OnePlus 12',
    brand: 'OnePlus',
    description:
        'سرعة استثنائية وتجربة استخدام سلسة مع شاشة مذهلة وبطارية تدوم طوال اليوم.',
    price: 2499,
    oldPrice: 2799,
    emoji: '📱',
    color: '0xFFE8F5E9',
    rating: 4.5,
    reviews: 114,
    isNew: false,
    features: [
      'معالج Snapdragon 8 Gen 3',
      'شاشة 120Hz',
      'بطارية 5400mAh',
      'شحن سريع 100 واط',
    ],
  ),
  Product(
    id: 'iphone-15',
    name: 'iPhone 15',
    brand: 'Apple',
    description:
        'تصميم أنيق وأداء قوي مع كاميرا عالية الدقة وتجربة iOS المميزة.',
    price: 3199,
    oldPrice: 3499,
    emoji: '📱',
    color: '0xFFE3F2FD',
    rating: 4.8,
    reviews: 276,
    isNew: false,
    features: [
      'شريحة A16 Bionic',
      'كاميرا رئيسية 48 ميجابكسل',
      'منفذ USB-C',
      'ذاكرة 128 جيجابايت',
    ],
  ),
];
