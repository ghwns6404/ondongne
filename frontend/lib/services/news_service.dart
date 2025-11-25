import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news.dart';
import 'notification_service.dart';
import 'user_service.dart';

class NewsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('news');

  // 생성
  static Future<String> createNews({
    required String title,
    required String content,
    required String region,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final doc = await _col.add({
      'authorId': user.uid,
      'title': title,
      'content': content,
      'region': region,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'favoriteUserIds': <String>[],
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
    });
    return doc.id;
  }

  // 업데이트
  static Future<void> updateNews(
    String newsId, {
    String? title,
    String? content,
    String? region,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
  }) async {
    final update = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (region != null) 'region': region,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(newsId).update(update);
  }

  // 삭제
  static Future<void> deleteNews(String newsId) async {
    await _col.doc(newsId).delete();
  }

  // ID로 단일 뉴스 조회
  static Future<News?> getNews(String newsId) async {
    final doc = await _col.doc(newsId).get();
    if (!doc.exists) return null;
    return News.fromDoc(doc);
  }

  // 즐겨찾기 토글
  static Future<void> toggleFavorite(String newsId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _col.doc(newsId);
    
    bool isAdding = false;
    String? authorId;
    String? title;
    
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      authorId = data['authorId'] as String?;
      title = data['title'] as String?;
      
      final List<dynamic> favorites = (data['favoriteUserIds'] as List<dynamic>?) ?? [];
      final Set<String> set = favorites.map((e) => e.toString()).toSet();
      if (set.contains(user.uid)) {
        set.remove(user.uid);
        isAdding = false;
      } else {
        set.add(user.uid);
        isAdding = true;
      }
      txn.update(ref, {'favoriteUserIds': set.toList()});
    });
    
    // 좋아요 추가할 때만 알림 발송 + 매너점수 증가
    if (isAdding && authorId != null && title != null) {
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final userName = userDoc.data()?['name'] ?? '익명';
        
        await NotificationService.notifyLike(
          postOwnerId: authorId!,
          likerName: userName,
          postTitle: title!,
          postId: newsId,
          postType: 'news',
        );
        
        // 매너점수 증가
        await UserService.increaseMannerScoreForLike(authorId!);
      } catch (e) {
        print('좋아요 알림 발송 실패: $e');
      }
    }
  }

  // 쿼리: 지역/즐겨찾기 필터
  static Query<Map<String, dynamic>> queryNews({
    String? region,
    bool? onlyFavorites,
  }) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true);
    
    // 즐겨찾기만 먼저 처리
    if (onlyFavorites == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        q = q.where('favoriteUserIds', arrayContains: uid);
      }
    }
    
    // 지역 필터
    if (region != null && region.isNotEmpty && region != '대전 전체') {
      q = q.where('region', isEqualTo: region);
    }
    
    return q;
  }

  static Stream<List<News>> watchNews({
    String? region,
    bool? onlyFavorites,
  }) {
    return queryNews(
      region: region,
      onlyFavorites: onlyFavorites,
    ).snapshots().map((snapshot) =>
        snapshot.docs.map((d) => News.fromDoc(d)).toList());
  }
}
