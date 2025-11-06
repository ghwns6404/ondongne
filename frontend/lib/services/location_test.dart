import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  String result = "위치 확인 중...";

  @override
  void initState() {
    super.initState();
    _test();
  }

  Future<void> _test() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever) {
        setState(() => result = "권한 완전 거부됨 (설정에서 허용 필요)");
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() => result = "lat=${pos.latitude}, lng=${pos.longitude}");
    } catch (e) {
      setState(() => result = "오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(result)),
    );
  }
}
