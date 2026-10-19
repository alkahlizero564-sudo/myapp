class PhoneSpec {
  final String screen;
  final String processor;
  final String ram;
  final String camera;
  final String battery;
  final String os;

  const PhoneSpec({
    required this.screen,
    required this.processor,
    required this.ram,
    required this.camera,
    required this.battery,
    required this.os,
  });

  Map<String, dynamic> toJson() => {
        'screen': screen,
        'processor': processor,
        'ram': ram,
        'camera': camera,
        'battery': battery,
        'os': os,
      };

  factory PhoneSpec.fromJson(Map<String, dynamic> json) => PhoneSpec(
        screen: json['screen'] ?? '',
        processor: json['processor'] ?? '',
        ram: json['ram'] ?? '',
        camera: json['camera'] ?? '',
        battery: json['battery'] ?? '',
        os: json['os'] ?? '',
      );
}

class PhoneVariant {
  final String storage;
  final double price;
  final double? originalPrice;

  const PhoneVariant({
    required this.storage,
    required this.price,
    this.originalPrice,
  });

  Map<String, dynamic> toJson() => {
        'storage': storage,
        'price': price,
        'originalPrice': originalPrice,
      };

  factory PhoneVariant.fromJson(Map<String, dynamic> json) => PhoneVariant(
        storage: json['storage'] ?? '',
        price: (json['price'] as num).toDouble(),
        originalPrice: json['originalPrice'] != null
            ? (json['originalPrice'] as num).toDouble()
            : null,
      );
}

class Phone {
  final String id;
  final String name;
  final String brand;
  final String description;
  final List<String> images;
  final List<String> colors;
  final List<PhoneVariant> variants;
  final PhoneSpec specs;
  final double rating;
  final int reviewsCount;
  final bool isFeatured;
  final bool isNew;

  const Phone({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.images,
    required this.colors,
    required this.variants,
    required this.specs,
    required this.rating,
    required this.reviewsCount,
    this.isFeatured = false,
    this.isNew = false,
  });

  double get basePrice => variants.isNotEmpty ? variants.first.price : 0;
  double? get baseOriginalPrice =>
      variants.isNotEmpty ? variants.first.originalPrice : null;
}
