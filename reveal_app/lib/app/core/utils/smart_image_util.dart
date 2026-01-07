class SmartImageUtil {
  static const Map<String, String> _keywordToAsset = {
    'بيتزا': 'assets/images/pizza.png',
    'pizza': 'assets/images/pizza.png',
    'برغر': 'assets/images/burger.png',
    'برجر': 'assets/images/burger.png',
    'burger': 'assets/images/burger.png',
    'قهوة': 'assets/images/coffee_placeholder.png',
    'coffee': 'assets/images/coffee_placeholder.png',
    'مشروبات': 'assets/images/drinks.png',
    'مشروب': 'assets/images/drinks.png',
    'عصير': 'assets/images/drinks.png',
    'ماء': 'assets/images/drinks.png',
    'juice': 'assets/images/drinks.png',
    'water': 'assets/images/drinks.png',
    'حلويات': 'assets/images/dessert.png',
    'حلو': 'assets/images/dessert.png',
    'dessert': 'assets/images/dessert.png',
    'cake': 'assets/images/dessert.png',
  };

  static String getImagePath(String productName, String? serverImageUrl) {
    if (serverImageUrl != null && serverImageUrl.isNotEmpty && serverImageUrl.startsWith('http')) {
      return serverImageUrl;
    }

    final name = productName.toLowerCase();
    for (final entry in _keywordToAsset.entries) {
      if (name.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return 'assets/images/logo.png';
  }

  static bool isNetworkImage(String path) {
    return path.startsWith('http');
  }
}
