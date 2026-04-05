import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'wallpaper_generator.dart';

// --- Theme Model ---
class WallpaperTheme {
  final String name;
  final String description;
  final Color backgroundColor;
  final List<Color>? backgroundGradient;
  final Color filledColor;
  final Color emptyColor;
  final Color? weekendColor;
  final Color textColor;
  final IconData icon;
  final WallpaperShape shape;
  final Map<int, Color>? specialDates;

  const WallpaperTheme({
    required this.name,
    required this.description,
    required this.backgroundColor,
    this.backgroundGradient,
    required this.filledColor,
    required this.emptyColor,
    this.weekendColor,
    required this.textColor,
    required this.icon,
    this.shape = WallpaperShape.circle,
    this.specialDates,
  });
}

// --- Theme Presets ---
final List<WallpaperTheme> themes = [
  const WallpaperTheme(
    name: "Minimal Dark",
    description: "Clean, sharp, and battery friendly.",
    backgroundColor: Colors.black,
    filledColor: Colors.white,
    emptyColor: Color(0xFF333333),
    textColor: Colors.white,
    icon: Icons.brightness_2,
    shape: WallpaperShape.circle,
  ),
  const WallpaperTheme(
    name: "Love Year",
    description: "Fill your year with love.",
    backgroundColor: Color(0xFFFFE5EC),
    filledColor: Color(0xFFFF006E),
    emptyColor: Color(0xFFFFC2D1),
    weekendColor: Color(0xFF8338EC), // Purple weekends
    textColor: Color(0xFFFF006E),
    icon: Icons.favorite,
    shape: WallpaperShape.heart,
  ),
  const WallpaperTheme(
    name: "Matrix",
    description: "Enter the code. Neon green squares.",
    backgroundColor: Colors.black,
    filledColor: Color(0xFF00FF00),
    emptyColor: Color(0xFF003300),
    textColor: Color(0xFF00FF00),
    icon: Icons.code,
    shape: WallpaperShape.square,
  ),
  const WallpaperTheme(
    name: "Sunset Gradient",
    description: "Relaxing vibes with rounded squares.",
    backgroundColor: Color(0xFF2D1B2E),
    backgroundGradient: [Color(0xFF2D1B2E), Color(0xFFB04B5A)],
    filledColor: Color(0xFFFFD166),
    emptyColor: Color(0xFF5D2E46),
    weekendColor: Color(0xFFFF9F1C),
    textColor: Color(0xFFFFD166),
    icon: Icons.wb_sunny,
    shape: WallpaperShape.roundedSquare,
  ),
  const WallpaperTheme(
    name: "Starry Night",
    description: "Reach for the stars.",
    backgroundColor: Color(0xFF0B1026),
    backgroundGradient: [Color(0xFF0B1026), Color(0xFF2B32B2)],
    filledColor: Color(0xFFFFD700), // Gold
    emptyColor: Color(0xFF4B5563),
    weekendColor: Colors.white,
    textColor: Colors.white,
    icon: Icons.star,
    shape: WallpaperShape.star,
  ),
  const WallpaperTheme(
    name: "Ocean Diamond",
    description: "Calm blue tones.",
    backgroundColor: Color(0xFF0D1B2A),
    filledColor: Color(0xFF48CAE4),
    emptyColor: Color(0xFF1B3A4B),
    textColor: Color(0xFFADE8F4),
    icon: Icons.water_drop,
    shape: WallpaperShape.diamond,
  ),
];

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final Map<int, File> _themeCache = {}; // Cache generated files by theme index
  
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preload the first one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateForIndex(0);
      // Preload next
      _generateForIndex(1);
    });
  }

  Future<void> _generateForIndex(int index) async {
    if (index < 0 || index >= themes.length) return;
    if (_themeCache.containsKey(index)) return; // Already cached

    final theme = themes[index];
    
    try {
      final size = MediaQuery.of(context).size;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final width = (size.width * pixelRatio).toInt();
      final height = (size.height * pixelRatio).toInt();

      final file = await WallpaperGenerator().generateYearProgressImage(
        width: width,
        height: height,
        backgroundColor: theme.backgroundColor,
        backgroundGradientColors: theme.backgroundGradient,
        filledColor: theme.filledColor,
        emptyColor: theme.emptyColor,
        weekendColor: theme.weekendColor,
        textColor: theme.textColor,
        shape: theme.shape,
        specialDates: theme.specialDates,
      );

      if (mounted) {
        setState(() {
          _themeCache[index] = file;
        });
      }
    } catch (e) {
      debugPrint("Error generating theme $index: $e");
    }
  }

  Future<void> _applyWallpaper(int index, int location) async {
    final file = _themeCache[index];
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      await WallpaperManagerFlutter().setWallpaper(
        file,
        location,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wallpaper updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApplyOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Apply Wallpaper",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              themes[index].name,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildApplyButton("Home Screen", Icons.home_filled, index, WallpaperManagerFlutter.homeScreen),
            const SizedBox(height: 12),
            _buildApplyButton("Lock Screen", Icons.lock_outline, index, WallpaperManagerFlutter.lockScreen),
            const SizedBox(height: 12),
            _buildApplyButton("Both Screens", Icons.phone_android, index, WallpaperManagerFlutter.bothScreens),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(String label, IconData icon, int index, int location) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        _applyWallpaper(index, location);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, // Dark background for gallery feel
      appBar: AppBar(
        title: const Text("Wallpaper Gallery"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading 
                ? null 
                : () async {
                    setState(() {
                      _themeCache.remove(_currentIndex);
                    });
                    await _generateForIndex(_currentIndex);
                  },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: themes.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              // Preload neighbor
              _generateForIndex(index + 1);
            },
            itemBuilder: (context, index) {
              final theme = themes[index];
              final file = _themeCache[index];
              
              // Animated Scale for focus effect
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  } else {
                     // Initial state
                     value = index == _currentIndex ? 1.0 : 0.8;
                  }
                  
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * MediaQuery.of(context).size.height * 0.7,
                      width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width * 0.85,
                      child: child,
                    ),
                  );
                },
                child: Hero(
                  tag: 'theme_${theme.name}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.filledColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : Container(
                            color: theme.backgroundColor,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          
          // 2. Info & Actions
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              children: [
                Text(
                  themes[_currentIndex].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  themes[_currentIndex].description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : () => _showApplyOptions(_currentIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Apply This Wallpaper", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
