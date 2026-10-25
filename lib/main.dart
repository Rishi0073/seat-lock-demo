import 'package:flutter/material.dart';

import 'controllers/booking_controller.dart';
import 'screens/home_screen.dart';

// Thin entry point: wire the layers together, nothing else.
void main() {
  runApp(SeatApp(controller: BookingController()));
}

class SeatApp extends StatelessWidget {
  const SeatApp({super.key, required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seat Lock Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
