import 'package:flutter/material.dart';

/// All In 1 Home — Brand Palette
/// Inspired by the logo: deep ocean blue, warm golden sun, sky teal, clean white.
class AppColors {
  AppColors._();

  // ── Primary: Deep Ocean Blue (logo text + roof) ──────────────────────────
  static const Color primary        = Color(0xFF0A3272); // Deep brand blue
  static const Color primaryLight   = Color(0xFF1B5DB5); // Hover / lighter blue
  static const Color primaryDark    = Color(0xFF071E4A); // Pressed / darkest blue

  // ── Accent: Golden Amber (sun rays) ──────────────────────────────────────
  static const Color amber          = Color(0xFFF5A623); // Warm sun gold
  static const Color amberLight     = Color(0xFFFFD166); // Soft golden highlight

  // ── Secondary: Sky Teal (sky / ocean backdrop) ───────────────────────────
  static const Color teal           = Color(0xFF0EA5CF); // Clean sky blue-teal
  static const Color tealLight      = Color(0xFFE0F5FB); // Teal tint background

  // ── Success / Nature Green (palm trees) ──────────────────────────────────
  static const Color green          = Color(0xFF22A45D); // Palm green
  static const Color greenLight     = Color(0xFFE8F7EF); // Green tint background

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error          = Color(0xFFE53E3E);
  static const Color errorLight     = Color(0xFFFFF5F5);
  static const Color warning        = Color(0xFFF97316);
  static const Color warningLight   = Color(0xFFFFF7ED);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color white          = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFF0F6FF); // Very light sky blue tint
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color border         = Color(0xFFDDE4EF);
  static const Color textPrimary    = Color(0xFF0D1F3C); // Near-black with blue hue
  static const Color textSecondary  = Color(0xFF5D7A9A); // Muted blue-grey
  static const Color textMuted      = Color(0xFF9BAFC4); // Light muted

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const Color sidebarBg      = Color(0xFF071E49); // Deep navy — darkest blue
  static const Color sidebarActive  = Color(0xFF0A3272); // Slightly lighter for selected
  static const Color sidebarText    = Color(0xFFCDD8EC); // Soft blue-white
  static const Color sidebarMuted   = Color(0xFF4E6A99); // Muted sidebar text
}
