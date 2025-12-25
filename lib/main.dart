import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_news_brief/app/app.dart';
import 'package:personal_news_brief/core/database/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.initialize();
  
  runApp(
    const ProviderScope(
      child: PersonalNewsBriefApp(),
    ),
  );
}