import 'package:flutter/material.dart';

void main() {
  runApp(const PyNexaScheduleApp());
}

class PyNexaScheduleApp extends StatelessWidget {
  const PyNexaScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyNexa Schedule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const ScheduleHomePage(),
    );
  }
}

class ScheduleHomePage extends StatelessWidget {
  const ScheduleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 76,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PyNexa Schedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Plan smarter. Stay consistent. Get things done.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Your time. Your priorities. Your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFC4B5FD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
