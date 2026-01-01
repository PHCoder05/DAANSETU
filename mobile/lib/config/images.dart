class AppImages {
  // Zomato/Premium Style Category Images (Unsplash Source)
  static const String food = 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&q=80&w=1000';
  static const String clothes = 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&q=80&w=1000';
  static const String books = 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&q=80&w=1000';
  static const String medical = 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=1000';
  static const String electronics = 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&q=80&w=1000';
  static const String furniture = 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=1000';
  static const String toys = 'https://images.unsplash.com/photo-1566576912902-1dcd47e3032d?auto=format&fit=crop&q=80&w=1000';
  static const String other = 'https://images.unsplash.com/photo-1444418776041-9c7e33cc5a9c?auto=format&fit=crop&q=80&w=1000';

  // Fallback
  static const String placeholder = 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&q=80&w=1000';

  static String getByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food': return food;
      case 'clothes':
      case 'clothing': return clothes;
      case 'books':
      case 'stationery': return books;
      case 'medical':
      case 'medicine': return medical;
      case 'electronics': return electronics;
      case 'furniture': return furniture;
      case 'toys': return toys;
      default: return other;
    }
  }
}
