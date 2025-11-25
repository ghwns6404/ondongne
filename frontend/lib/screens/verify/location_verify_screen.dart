import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/verification_service.dart';


class LocationVerifyScreen extends StatefulWidget {
  const LocationVerifyScreen({super.key});

  @override
  State<LocationVerifyScreen> createState() => _LocationVerifyScreenState();
}

class _LocationVerifyScreenState extends State<LocationVerifyScreen> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final dong = await VerificationService.verifyCurrentDong();
      if (!mounted) return;
      setState(() {
        _result = dong;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('지역 인증 완료: $dong')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('우리 동 인증')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final verifiedDong = data?['verifiedDong'] as String?;
                  final verifiedAt = data?['verifiedAt'] as Timestamp?;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('현재 인증된 동: ${verifiedDong ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('인증일: ${verifiedAt != null ? verifiedAt.toDate().toLocal().toString() : '-'}'),
                      const Divider(height: 24),
                    ],
                  );
                },
              ),
            if (_result != null) Text('감지된 동: $_result'),
            if (_error != null) Text('에러: $_error', style: const TextStyle(color: Colors.red)),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _verify,
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                label: const Text('현재 위치로 동 인증하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


