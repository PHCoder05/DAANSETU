import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum WallpaperShape { circle, square, roundedSquare, heart, star, diamond }

class WallpaperGenerator {
  /// Generates a year progress image with dots representing days.
  /// Returns the File object of the generated image.
  Future<File> generateYearProgressImage({
    required int width,
    required int height,
    Color backgroundColor = Colors.black,
    List<Color>? backgroundGradientColors,
    Color filledColor = Colors.green,
    Color emptyColor = Colors.grey,
    Color? weekendColor,
    Color textColor = Colors.white,
    WallpaperShape shape = WallpaperShape.circle,
    Map<int, Color>? specialDates, // Key is dayOfYear (1-366)
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // 1. Draw Background
    final bgRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final bgPaint = Paint();
    
    if (backgroundGradientColors != null && backgroundGradientColors.length >= 2) {
      bgPaint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, height.toDouble()),
        backgroundGradientColors,
      );
    } else {
      bgPaint.color = backgroundColor;
    }
    
    canvas.drawRect(bgRect, bgPaint);

    // 2. Calculate Progress
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(firstDayOfYear).inDays + 1;
    final isLeapYear = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
    final totalDays = isLeapYear ? 366 : 365;

    // 3. Draw Grid
    // Adjusted layout for better visual balance
    const int cols = 15;
    // Calculate rows needed
    final int rows = (totalDays / cols).ceil(); 
    
    final double padding = width * 0.12;
    final double gridWidth = width - (padding * 2);
    
    final double dotSpacing = gridWidth / (cols - 1);
    // Adjust size based on shape to ensure they don't overlap or look too small
    final double shapeSize = dotSpacing * (shape == WallpaperShape.star || shape == WallpaperShape.heart ? 0.45 : 0.35);

    final startX = padding;
    final startY = (height - ((rows - 1) * dotSpacing)) / 2; // Center vertically correctly

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < totalDays; i++) {
        final int col = i % cols;
        final int row = i ~/ cols;

        final double cx = startX + (col * dotSpacing);
        final double cy = startY + (row * dotSpacing);
        final center = Offset(cx, cy);

        // Determine Color
        // Calculate date for this index
        final currentDate = firstDayOfYear.add(Duration(days: i));
        final currentDayOfYear = i + 1;
        
        bool isWeekend = currentDate.weekday == DateTime.saturday || currentDate.weekday == DateTime.sunday;
        
        // Base color decision
        Color colorToUse;
        
        if (specialDates != null && specialDates.containsKey(currentDayOfYear)) {
           colorToUse = specialDates[currentDayOfYear]!;
        } else if (isWeekend && weekendColor != null) {
           // If it's a weekend, use weekend color. 
           // We might want different logic for past/future weekends?
           // For now, let's treat "filled" as passed, but if weekend, maybe we want that specific color 
           // REGARDLESS of passed status? Or only if passed?
           // User request: "for suunday and sat different colors"
           // Let's dim it if it's in the future
           if (i < dayOfYear) {
             colorToUse = weekendColor;
           } else {
             colorToUse = weekendColor.withOpacity(0.3);
           }
        } else {
           if (i < dayOfYear) {
            colorToUse = filledColor;
           } else {
            colorToUse = emptyColor.withOpacity(0.3);
           }
        }
        
        dotPaint.color = colorToUse;

        _drawShape(canvas, shape, center, shapeSize, dotPaint);
    }
    
    // Draw Text (Year Progress %)
    final percentage = ((dayOfYear / totalDays) * 100).toStringAsFixed(1);
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: "$percentage%",
          style: TextStyle(
            color: textColor,
            fontSize: width * 0.12,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
        ),
        TextSpan(
          text: "\nYear Complete",
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: width * 0.04,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: width.toDouble(), maxWidth: width.toDouble());
    
    // Position text below grid
    final textY = startY + ((rows - 1) * dotSpacing) + (width * 0.15);
    textPainter.paint(
      canvas, 
      Offset(0, textY)
    );

    // 4. Save to File
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) throw Exception("Failed to encode image");

    final buffer = byteData.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/wallpaper_$timestamp.png'); // Unique name to avoid cache issues
    await file.writeAsBytes(buffer);

    return file;
  }

  void _drawShape(Canvas canvas, WallpaperShape shape, Offset center, double radius, Paint paint) {
    switch (shape) {
      case WallpaperShape.circle:
        canvas.drawCircle(center, radius, paint);
        break;
      case WallpaperShape.square:
        canvas.drawRect(Rect.fromCircle(center: center, radius: radius), paint);
        break;
      case WallpaperShape.roundedSquare:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: center, radius: radius),
            Radius.circular(radius * 0.4),
          ),
          paint,
        );
        break;
      case WallpaperShape.diamond:
        // Rotate square by 45 degrees
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(3.14159 / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius * 1.6, height: radius * 1.6), 
          paint
        );
        canvas.restore();
        break;
      case WallpaperShape.heart:
        _drawHeart(canvas, center, radius, paint);
        break;
      case WallpaperShape.star:
        _drawStar(canvas, center, radius, paint);
        break;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double radius, Paint paint) {
    final width = radius * 2.2;
    final height = radius * 2.2;
    
    final Path heartPath = Path();
    heartPath.moveTo(0, height * 0.25);
    heartPath.cubicTo(
      -width * 0.5, -height * 0.2, 
      -width * 0.5, height * 0.4, 
      0, height * 0.8
    );
    heartPath.cubicTo(
      width * 0.5, height * 0.4, 
      width * 0.5, -height * 0.2, 
      0, height * 0.25
    );
    
    // Center the path
    final Rect bounds = heartPath.getBounds();
    final Offset pathCenter = bounds.center;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.translate(-pathCenter.dx, -pathCenter.dy); 
    // Slight visual adjustment to make it look centered visually
    canvas.translate(0, -radius * 0.1); 
    
    canvas.drawPath(heartPath, paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    final double outerRadius = radius * 1.2;
    final double innerRadius = radius * 0.5;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    path.moveTo(0, -outerRadius);
    path.lineTo(innerRadius * 0.58, -innerRadius * 0.8);
    path.lineTo(outerRadius * 0.95, -outerRadius * 0.3);
    path.lineTo(innerRadius * 0.58, innerRadius * 0.19);
    path.lineTo(outerRadius * 0.58, outerRadius * 0.8);
    path.lineTo(0, innerRadius * 0.5);
    path.lineTo(-outerRadius * 0.58, outerRadius * 0.8);
    path.lineTo(-innerRadius * 0.58, innerRadius * 0.19);
    path.lineTo(-outerRadius * 0.95, -outerRadius * 0.3);
    path.lineTo(-innerRadius * 0.58, -innerRadius * 0.8);
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}
