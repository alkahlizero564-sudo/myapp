import 'package:flutter/material.dart';

const kBg = Color(0xFF0F1720);
const kCard = Color(0xFF17212C);
const kLine = Color(0xFF263341);
const kField = Color(0xFF2F3F50);
const kAccent = Color(0xFF22B8A6);
const kMuted = Color(0xFF8FA1B3);
const kWarn = Color(0xFFF2B84B);
const kBad = Color(0xFFE5645A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.dark,
  ).copyWith(
    surface: kBg,
    primary: kAccent,
    onPrimary: const Color(0xFF06201C),
  );

  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBg,
      border: border(kField),
      enabledBorder: border(kField),
      focusedBorder: border(kAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: kField),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: kCard,
    ),
  );
}

/// Rounded dark panel used instead of Card, so the look does not depend on
/// the Flutter version's CardTheme API.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, color: kMuted)),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: const TextStyle(fontSize: 13, color: kMuted)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
      ],
    );
  }
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
