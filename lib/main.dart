import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/introduction/introduction.dart' show Introduction;
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/service/notification_service.dart';

final GlobalKey<NavigatorState> dialogKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initNotifications();
  runApp(const MyApp());
}

Future<void> initNotifications() async {
  NotificationService notificationService = NotificationService();
  await notificationService.init();
  if (Platform.isIOS) {
    await notificationService.requestIOSPermissions();
  } else if (Platform.isAndroid) {
    await notificationService.requestAndroidPermission();
  }
  await notificationService.scheduleNotification(
    1, 
    "Daily Remainder", 
    "Set daily goals and track behaviors on ProudMe App.", 
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), 
    const TimeOfDay(hour: 8, minute: 00), 
    "", 
    "daily", 
    1);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: dialogKey,
      title: projectTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          secondary: const Color(0xfff5b342)
        ),
        useMaterial3: true,
        fontFamily: fontFamily
      ),
      home: Scaffold(
        body: Introduction()
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
