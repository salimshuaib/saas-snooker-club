import 'package:flutter/material.dart';

/// Centralized color palette for the S&B Manager application.
/// All colors used throughout the app should be referenced from here.
class AppColors {
  AppColors._();

  // ─── Brand Colors ───
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color secondary = Color(0xFF8B5CF6); // Violet
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryDark = Color(0xFF7C3AED);

  static const Color tertiary = Color(0xFF06B6D4); // Cyan

  // ─── Preview Brand Colors (Snooker Palette) ───
  static const Color previewPrimary = Color(0xFF134B3B); // Felt
  static const Color previewPrimaryLight = Color(0xFF1C6350); // Felt Light
  static const Color previewPrimaryDark = Color(0xFF0E3B2E); // Felt Dark

  static const Color previewSecondary = Color(0xFFC89B3C); // Brass
  static const Color previewSecondaryLight = Color(0xFFE0BD6A); // Brass Light
  static const Color previewSecondaryDark = Color(0xFF98732A); // Darker Brass

  static const Color previewError = Color(0xFFC0432B); // Snooker Red
  static const Color previewLine = Color(
    0x29F6F1E4,
  ); // 16% Cream (for dark backgrounds)

  // ─── Preview Theme Colors ───
  static const Color previewLightBackground = Color(0xFFF6F1E4); // Cream
  static const Color previewLightSurface = Color(0xFFE7DFC8); // Cream Dim
  static const Color previewLightOnBackground = Color(0xFF241710); // Walnut
  static const Color previewLightOnSurface = Color(0xFF241710); // Walnut
  static const Color previewLightOutline = Color(0x26241710); // 15% Walnut
  static const Color previewLightOutlineVariant = Color(
    0x1A241710,
  ); // 10% Walnut

  // ─── Light Theme Colors ───
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnBackground = Color(0xFF0F172A);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);

  // ─── Dark Theme Colors ───
  static const Color darkBackground = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF131620);
  static const Color darkSurfaceVariant = Color(0xFF1C2030);
  static const Color darkOnBackground = Color(0xFFE2E8F0);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF334155);
  static const Color darkOutlineVariant = Color(0xFF1E293B);

  // ─── Status Colors ───
  static const Color available = Color(0xFF10B981); // Green
  static const Color running = Color(0xFF3B82F6); // Blue
  static const Color paused = Color(0xFFF59E0B); // Amber
  static const Color completed = Color(0xFF6B7280); // Gray
  static const Color billing = Color(0xFF8B5CF6); // Purple
  static const Color creditStatus = Color(0xFFEF4444); // Red

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Glass Effect Colors ───
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Get status color based on status string.
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return available;
      case 'running':
        return running;
      case 'paused':
        return paused;
      case 'completed':
        return completed;
      case 'billing':
        return billing;
      case 'credit':
        return creditStatus;
      default:
        return completed;
    }
  }
}
