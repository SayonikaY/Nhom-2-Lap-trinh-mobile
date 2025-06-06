import 'package:flutter/material.dart';
import 'services/restaurant_api_service.dart';
import 'screens/splash_screen.dart';

void main() {
  RestaurantApiService.initialize();

  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Restaurant Management',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      useMaterial3: true,
    ),
    home: const SplashScreen(),
  );
}
