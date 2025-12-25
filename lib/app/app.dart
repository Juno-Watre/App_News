import 'package:flutter/material.dart';
import 'package:personal_news_brief/features/home/presentation/pages/home_page.dart';

class PersonalNewsBriefApp extends StatelessWidget {
  const PersonalNewsBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal News Brief',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // 跟随系统主题
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}