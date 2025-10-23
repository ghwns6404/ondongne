import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class ProductService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  // 생성
  static Future<String> createProduct({
    required String title,
    required String description,
    required int price,
    required List<String> imageUrls,
    required String region,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final doc = await _col.add({
      'sellerId': user.uid,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'region': region,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'favoriteUserIds': <String>[],
    });
    return doc.id;
  }

  // 업데이트
  static Future<void> updateProduct(
    String productId, {
    String? title,
    String? description,
    int? price,
    List<String>? imageUrls,
    String? region,
  }) async {
    final update = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (region != null) 'region': region,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(productId).update(update);
  }

  // 삭제
  static Future<void> deleteProduct(String productId) async {
    await _col.doc(productId).delete();
  }

  // 즐겨찾기 토글
  static Future<void> toggleFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _col.doc(productId);
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

  // 쿼리: 지역 필터만 (인덱스 문제 방지)
  static Query<Map<String, dynamic>> queryProducts({
    String? region,
  }) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true);
    
    // 지역 필터만 서버에서 처리
    if (region != null && region.isNotEmpty && region != '대전 전체') {
      q = q.where('region', isEqualTo: region);
    }
    
    return q;
  }

  // 클라이언트에서 필터링 (가격, 즐겨찾기)
  static List<Product> filterProducts(List<Product> products, {
    int? minPrice,
    int? maxPrice,
    bool? onlyFavorites,
  }) {
    return products.where((product) {
      // 가격 필터
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      
      // 즐겨찾기 필터
      if (onlyFavorites == true) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || !product.favoriteUserIds.contains(uid)) return false;
      }
      
      return true;
    }).toList();
  }

  static Stream<List<Product>> watchProducts({
    String? region,
    int? minPrice,
    int? maxPrice,
    bool? onlyFavorites,
  }) {
    return queryProducts(region: region).snapshots().map((snapshot) {
      var products = snapshot.docs.map((d) => Product.fromDoc(d)).toList();
      // 모든 필터는 클라이언트에서 처리
      return filterProducts(products, 
        minPrice: minPrice, 
        maxPrice: maxPrice, 
        onlyFavorites: onlyFavorites
      );
    });
  }
}
