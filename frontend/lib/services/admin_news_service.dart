import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news.dart';
import '../models/admin_news.dart';

class AdminNewsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('adminNews');

  // 생성 (Admin만 가능)
  static Future<String> createAdminNews({
    required String title,
    required String content,
    required String region,
    required List<String> imageUrls,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final doc = await _col.add({
      'title': title,
      'content': content,
      'region': region,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'favoriteUserIds': <String>[],
    });
    return doc.id;
  }

  // 업데이트 (Admin만 가능)
  static Future<void> updateAdminNews(
    String newsId, {
    String? title,
    String? content,
    String? region,
    List<String>? imageUrls,
  }) async {
    final update = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (region != null) 'region': region,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(newsId).update(update);
  }

  // 삭제 (Admin만 가능)
  static Future<void> deleteAdminNews(String newsId) async {
    await _col.doc(newsId).delete();
  }

  // ID로 단일 관리자 뉴스 조회
  static Future<News?> getAdminNews(String newsId) async {
    final doc = await _col.doc(newsId).get();
    if (!doc.exists) return null;
    return News.fromDoc(doc);
  }

  // 즐겨찾기 토글
  static Future<void> toggleFavorite(String newsId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _col.doc(newsId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> favorites = (data['favoriteUserIds'] as List<dynamic>?) ?? [];
      final Set<String> set = favorites.map((e) => e.toString()).toSet();
      if (set.contains(user.uid)) {
        set.remove(user.uid);
      } else {
        set.add(user.uid);
      }
      txn.update(ref, {'favoriteUserIds': set.toList()});
    });
  }

  // 쿼리: 지역 필터만
  static Query<Map<String, dynamic>> queryAdminNews({
    String? region,
  }) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true);
    
    if (region != null && region.isNotEmpty && region != '대전 전체') {
      q = q.where('region', isEqualTo: region);
    }
    
    return q;
  }

  static Stream<List<AdminNews>> watchAdminNews({
    String? region,
  }) {
    return queryAdminNews(region: region).snapshots().map((snapshot) =>
        snapshot.docs.map((d) => AdminNews.fromDoc(d)).toList());
  }
}
