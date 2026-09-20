class PlaceCategory {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<String> selectors;

  const PlaceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectors,
  });
}

const placeCategories = <PlaceCategory>[
  PlaceCategory(
    id: 'cafe',
    title: 'کافی‌شاپ',
    subtitle: 'کافه و نوشیدنی',
    icon: '☕',
    selectors: [
      'node["amenity"="cafe"]',
      'way["amenity"="cafe"]',
      'relation["amenity"="cafe"]',
    ],
  ),
  PlaceCategory(
    id: 'restaurant',
    title: 'رستوران',
    subtitle: 'رستوران و غذا',
    icon: '🍽️',
    selectors: [
      'node["amenity"="restaurant"]',
      'way["amenity"="restaurant"]',
      'relation["amenity"="restaurant"]',
    ],
  ),
  PlaceCategory(
    id: 'fun',
    title: 'تفریحی',
    subtitle: 'پارک، سینما و جاذبه',
    icon: '🎡',
    selectors: [
      'node["leisure"="park"]',
      'way["leisure"="park"]',
      'node["amenity"="cinema"]',
      'way["amenity"="cinema"]',
      'node["tourism"="attraction"]',
      'way["tourism"="attraction"]',
      'node["tourism"="museum"]',
      'way["tourism"="museum"]',
    ],
  ),
  PlaceCategory(
    id: 'library',
    title: 'کتابخانه',
    subtitle: 'کتابخانه و مطالعه',
    icon: '📚',
    selectors: [
      'node["amenity"="library"]',
      'way["amenity"="library"]',
      'relation["amenity"="library"]',
    ],
  ),
  PlaceCategory(
    id: 'mall',
    title: 'مرکز خرید',
    subtitle: 'مال و پاساژ',
    icon: '🛍️',
    selectors: [
      'node["shop"="mall"]',
      'way["shop"="mall"]',
      'relation["shop"="mall"]',
    ],
  ),
  PlaceCategory(
    id: 'fast_food',
    title: 'فست‌فود',
    subtitle: 'فست‌فود و غذای سریع',
    icon: '🍔',
    selectors: [
      'node["amenity"="fast_food"]',
      'way["amenity"="fast_food"]',
      'relation["amenity"="fast_food"]',
    ],
  ),
  PlaceCategory(
    id: 'bakery',
    title: 'نانوایی',
    subtitle: 'نانوایی و شیرینی',
    icon: '🥖',
    selectors: [
      'node["shop"="bakery"]',
      'way["shop"="bakery"]',
      'relation["shop"="bakery"]',
    ],
  ),
  PlaceCategory(
    id: 'ice_cream',
    title: 'بستنی',
    subtitle: 'بستنی‌فروشی و دسر',
    icon: '🍦',
    selectors: [
      'node["shop"="ice_cream"]',
      'way["shop"="ice_cream"]',
      'relation["shop"="ice_cream"]',
      'node["amenity"="ice_cream"]',
      'way["amenity"="ice_cream"]',
      'relation["amenity"="ice_cream"]',
    ],
  ),
];
