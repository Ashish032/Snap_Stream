import 'package:flutter/material.dart';
import 'package:capture_and_upload/video_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VideoScreen(),
    );
  }
}
