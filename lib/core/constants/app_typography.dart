import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayTitle => GoogleFonts.philosopher(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle get screenHeading => GoogleFonts.philosopher(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyText => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get tagText => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );
}
