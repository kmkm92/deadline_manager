import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// モダンCupertinoスタイルのAppテーマ（バイオレット基調）
class AppTheme {
  // 基調色: M3 Violet（以前と同じ）
  static const primaryColor = Color(0xFF6750A4);
  // セカンダリ: より明るいバイオレット
  static const secondaryColor = Color(0xFF9A82DB);
  // 確認用グリーン
  static const confirmColor = Color(0xFF34C759);
  // 削除用レッド
  static const destructiveColor = Color(0xFFFF3B30);

  // グラデーション用カラー
  static const gradientStart = Color(0xFF6750A4);
  static const gradientEnd = Color(0xFF9A82DB);

  /// プライマリグラデーション
  static const primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cupertinoテーマデータ
  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      primaryColor: primaryColor,
      brightness: Brightness.light,
    );
  }

  static CupertinoThemeData get cupertinoDarkTheme {
    return const CupertinoThemeData(
      primaryColor: primaryColor,
      brightness: Brightness.dark,
    );
  }

  /// ライトテーマ（モダンCupertinoスタイル + バイオレット基調）
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.notoSansJpTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: destructiveColor,
      ).copyWith(
        surface: const Color(0xFFF8F7FC), // 薄いバイオレットティント
        surfaceContainer: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF8E8E93),
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF8E8E93),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shadowColor: primaryColor.withOpacity(0.1),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        minLeadingWidth: 28,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: primaryColor.withOpacity(0.1),
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return const Color(0xFFE9E9EA);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        elevation: 24,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 16,
      ),
    );
  }

  /// ダークテーマ（モダンCupertinoスタイル + バイオレット基調）
  static ThemeData get darkTheme {
    final baseTextTheme =
        GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: secondaryColor, // ダークモードではより明るいバイオレット
        secondary: primaryColor,
        error: destructiveColor,
      ).copyWith(
        surface: const Color(0xFF121212),
        surfaceContainer: const Color(0xFF1E1E1E),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: Colors.white,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          color: Colors.white,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          color: Colors.white,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          color: Colors.white,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF8E8E93),
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: Colors.white,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF8E8E93),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: secondaryColor),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1E1E1E),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        minLeadingWidth: 28,
        textColor: Colors.white,
        iconColor: Color(0xFF8E8E93),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryColor.withOpacity(0.2),
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }
          return const Color(0xFF39393D);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor.withOpacity(0.2),
        selectedColor: secondaryColor,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 24,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 16,
      ),
    );
  }
}
