import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class RecommendationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 제목에서 키워드 추출
  /// 예: "맥북 프로 15인치 2019년형" → ["맥북", "프로", "15인치", "2019년형"]
  static List<String> _extractKeywords(String title) {
    // 공백, 특수문자로 분리
    final words = title
        .replaceAll(RegExp(r'[^\w\s가-힣]'), ' ') // 특수문자 제거
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1) // 1글자 제외
        .where((word) => !_isStopWord(word)) // 불용어 제거
        .map((word) => word.toLowerCase())
        .toList();
    
    return words;
  }

  /// 불용어 제거 (의미 없는 단어)
  static bool _isStopWord(String word) {
    final stopWords = [
      '팝니다', '판매', '중고', '급처', '가격', '문의', '연락',
      '입니다', '입니다', '합니다', '합니다',
      '의', '을', '를', '이', '가', '은', '는',
      '년', '월', '일',
    ];
    return stopWords.contains(word.toLowerCase());
  }

  /// 두 제목 간 키워드 유사도 계산 (0.0 ~ 1.0)
  static double _calculateKeywordSimilarity(String title1, String title2) {
    final keywords1 = _extractKeywords(title1).toSet();
    final keywords2 = _extractKeywords(title2).toSet();
    
    if (keywords1.isEmpty || keywords2.isEmpty) {
      return 0.0;
    }
    
    // 공통 키워드
    final commonKeywords = keywords1.intersection(keywords2);
    
    // Jaccard 유사도: 교집합 / 합집합
    final union = keywords1.union(keywords2);
    if (union.isEmpty) return 0.0;
    
    return commonKeywords.length / union.length;
  }

  /// 제목과 키워드 리스트 간 유사도 계산
  static double _calculateKeywordListSimilarity(String title, List<String> keywordList) {
    if (keywordList.isEmpty) return 0.0;
    
    final titleKeywords = _extractKeywords(title).toSet();
    if (titleKeywords.isEmpty) return 0.0;
    
    // 키워드 리스트 중 제목에 포함된 키워드 개수
    int matchCount = 0;
    for (final keyword in keywordList) {
      if (titleKeywords.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }
    
    // 매칭 비율 반환
    return matchCount / keywordList.length;
  }

  /// 가격 유사도 계산 (0.0 ~ 1.0)
  /// 가격 차이가 적을수록 높은 점수
  static double _calculatePriceSimilarity(int price1, int price2) {
    if (price1 == 0 || price2 == 0) return 0.5; // 가격이 0이면 중간 점수
    
    final maxPrice = price1 > price2 ? price1 : price2;
    final diff = (price1 - price2).abs();
    final diffRatio = diff / maxPrice;
    
    // 가격 차이 비율에 따라 점수 계산
    if (diffRatio <= 0.1) return 1.0;      // 10% 이내: 100점
    if (diffRatio <= 0.2) return 0.9;      // 20% 이내: 90점
    if (diffRatio <= 0.3) return 0.7;      // 30% 이내: 70점
    if (diffRatio <= 0.5) return 0.5;      // 50% 이내: 50점
    if (diffRatio <= 0.7) return 0.3;      // 70% 이내: 30점
    return 0.0;                             // 70% 이상: 0점
  }

  /// 인기도 점수를 0.0 ~ 1.0으로 정규화
  static double _normalizePopularityScore(int viewCount, int favoriteCount) {
    // 원본 점수 계산
    final rawScore = (viewCount * 2) + (favoriteCount * 5);
    
    // 최대값 기준으로 정규화 (최대값은 경험적으로 설정)
    // 조회수 1000, 좋아요 100 = 2500점을 최대값으로 가정
    const maxScore = 2500.0;
    
    // 0~1 사이로 정규화 (최대값 넘어가면 1.0으로 제한)
    final normalized = (rawScore / maxScore).clamp(0.0, 1.0);
    
    return normalized;
  }

  /// 사용자 맞춤 추천 상품 가져오기
  /// 1. 사용자가 좋아요/조회한 상품의 카테고리 분석
  /// 2. 같은 카테고리에서 비슷한 가격대 상품 추천
  /// 3. 인기도 (조회수 + 좋아요) 기준 정렬
  static Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 로그인하지 않은 경우: 전체 인기 상품
      //🔍는 로그확인용임
      print('🔍 추천기능 로그 확인 시작(확인용)');
      print('🔍 [추천] 로그인 안 함 → 인기 상품 반환');
      return await getPopularProducts(limit: limit);
    }

    try {
      // 1. 사용자가 좋아요/조회한 상품들의 카테고리와 가격대 분석
      print('🔍 [추천] 사용자 선호도 분석 시작: ${user.uid}');
      final userPreferences = await _analyzeUserPreferences(user.uid);
      print('🔍 [추천] 선호도 분석 결과: ${userPreferences.length}개 카테고리');

      if (userPreferences.isEmpty) {
        // 선호도 데이터가 없으면 추천 불가 (빈 배열 반환)
        print('🔍 [추천] 선호도 없음 → 추천 불가 (사용자 활동 필요)');
        return [];
      }

      // 2. 선호 카테고리에서 상품 가져오기 (충분히 많이 가져와서 정확한 필터링)
      final List<Product> candidateProducts = [];
      
      for (final pref in userPreferences.take(3)) { // 상위 3개 카테고리
        QuerySnapshot categoryProducts;
        try {
          categoryProducts = await _db
              .collection('products')
              .where('status', isEqualTo: 'available')
              .where('category', isEqualTo: pref['category'])
              .orderBy('viewCount', descending: true)
              .limit(30) // 더 많이 가져와서 정확한 필터링
              .get();
        } catch (e) {
          // 인덱스 에러면 기본 쿼리로
          print('카테고리 쿼리 인덱스 에러, 기본 쿼리 사용: $e');
          categoryProducts = await _db
              .collection('products')
              .where('status', isEqualTo: 'available')
              .where('category', isEqualTo: pref['category'])
              .orderBy('createdAt', descending: true)
              .limit(30)
              .get();
        }

        for (final doc in categoryProducts.docs) {
          final product = Product.fromDoc(doc);
          
          // 이미 좋아요/조회한 상품 제외
          if (product.favoriteUserIds.contains(user.uid)) continue;
          if (product.viewedUserIds.contains(user.uid)) continue;
          
          // 자신의 상품 제외
          if (product.sellerId == user.uid) continue;
          
          candidateProducts.add(product);
        }
      }
      
      print('🔍 [추천] 후보 상품 수집: ${candidateProducts.length}개');
      
      if (candidateProducts.isEmpty) {
        print('🔍 [추천] 후보 상품 없음 → 추천 불가');
        return [];
      }

      // 3. 종합 점수 계산 및 정렬
      final List<Map<String, dynamic>> scoredProducts = [];
      
      for (final product in candidateProducts) {
        // 가장 유사한 선호도 찾기
        double bestCategoryScore = 0.0;
        double bestPriceScore = 0.0;
        double bestKeywordScore = 0.0;
        
        for (final pref in userPreferences) {
          // 카테고리 점수
          final categoryScore = (product.category == pref['category']) ? 1.0 : 0.0;
          if (categoryScore > bestCategoryScore) {
            bestCategoryScore = categoryScore;
          }
          
          // 가격 점수
          if (pref['avgPrice'] != null) {
            final avgPrice = pref['avgPrice'] as double;
            final priceScore = _calculatePriceSimilarity(product.price, avgPrice.toInt());
            if (priceScore > bestPriceScore) {
              bestPriceScore = priceScore;
            }
          }
          
          // 키워드 점수 (카테고리별 키워드와 전체 상위 키워드 모두 고려)
          double keywordScore = 0.0;
          
          // 1. 카테고리별 키워드와 비교
          if (pref['keywords'] != null) {
            final categoryKeywords = List<String>.from(pref['keywords'] as List);
            final categoryKeywordScore = _calculateKeywordListSimilarity(
              product.title,
              categoryKeywords,
            );
            keywordScore = categoryKeywordScore;
          }
          
          // 2. 전체 상위 키워드와 비교 (더 높은 점수 사용)
          if (pref['topKeywords'] != null) {
            final topKeywords = List<String>.from(pref['topKeywords'] as List);
            final topKeywordScore = _calculateKeywordListSimilarity(
              product.title,
              topKeywords,
            );
            if (topKeywordScore > keywordScore) {
              keywordScore = topKeywordScore;
            }
          }
          
          if (keywordScore > bestKeywordScore) {
            bestKeywordScore = keywordScore;
          }
        }
        
        // 인기도 점수 (0~1 정규화)
        final popularityScore = _normalizePopularityScore(
          product.viewCount,
          product.favoriteUserIds.length,
        );
        
        // 종합 점수 계산 (가중치 적용)
        // 카테고리가 다르면 점수 대폭 감점
        double categoryWeight = 0.25;
        if (bestCategoryScore == 0.0) {
          // 카테고리가 다르면 가중치를 낮춤
          categoryWeight = 0.1;
        }
        
        // 키워드 점수가 0이면 점수 대폭 감점
        double keywordWeight = 0.35;
        if (bestKeywordScore == 0.0) {
          // 키워드가 전혀 없으면 가중치를 낮춤
          keywordWeight = 0.15;
        }
        
        final totalScore = 
            (bestCategoryScore * categoryWeight) +
            (bestPriceScore * 0.25) +
            (bestKeywordScore * keywordWeight) +
            (popularityScore * 0.15);
        
        // 카테고리와 키워드 둘 다 없으면 연관성 없는 상품으로 제외
        if (bestCategoryScore == 0.0 && bestKeywordScore == 0.0) {
          // 연관성 없는 상품은 제외
          continue;
        }
        
        scoredProducts.add({
          'product': product,
          'score': totalScore,
          'categoryScore': bestCategoryScore,
          'priceScore': bestPriceScore,
          'keywordScore': bestKeywordScore,
          'popularityScore': popularityScore,
        });
      }

      // 4. 최소 점수 기준 적용 (0.3 이상만 추천)
      const minScoreThreshold = 0.3;
      final qualifiedProducts = scoredProducts
          .where((item) => (item['score'] as double) >= minScoreThreshold)
          .toList();
      
      print('🔍 [추천] 점수 기준 적용: ${scoredProducts.length}개 후보 중 ${qualifiedProducts.length}개가 ${minScoreThreshold}점 이상');
      
      // 5. 점수 순으로 정렬
      qualifiedProducts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // 6. 상위 N개 선택 (점수 기준 통과한 것만)
      final result = qualifiedProducts
          .take(limit)
          .map((item) => item['product'] as Product)
          .toList();
      
      print('🔍 [추천] 최종 추천: ${result.length}개 (점수 기준: ${minScoreThreshold} 이상)');
      
      // 점수 기준을 통과한 상품만 반환 (부족해도 보충 안 함)
      return result;
    } catch (e) {
      print('추천 상품 가져오기 실패: $e');
      // 에러 발생 시 인기 상품 반환
      return await getPopularProducts(limit: limit);
    }
  }

  /// 사용자 선호도 분석
  /// 좋아요/조회한 상품들의 카테고리, 평균 가격, 키워드 분석
  static Future<List<Map<String, dynamic>>> _analyzeUserPreferences(String userId) async {
    try {
      // 좋아요한 상품 가져오기
      final favoriteQuery = await _db
          .collection('products')
          .where('favoriteUserIds', arrayContains: userId)
          .limit(50)
          .get();

      // 조회한 상품 가져오기
      final viewedQuery = await _db
          .collection('products')
          .where('viewedUserIds', arrayContains: userId)
          .limit(50)
          .get();

      print('🔍 [선호도] 좋아요한 상품: ${favoriteQuery.docs.length}개');
      print('🔍 [선호도] 조회한 상품: ${viewedQuery.docs.length}개');

      // 카테고리별로 그룹화
      final Map<String, List<int>> categoryPrices = {};
      final Map<String, List<String>> categoryKeywords = {}; // 카테고리별 키워드 수집
      final Map<String, int> keywordFrequency = {}; // 전체 키워드 빈도

      for (final doc in [...favoriteQuery.docs, ...viewedQuery.docs]) {
        final data = doc.data();
        final category = data['category'] as String? ?? '기타 중고물품';
        final price = (data['price'] as num).toInt();
        final title = data['title'] as String? ?? '';

        // 카테고리별 가격 수집
        if (!categoryPrices.containsKey(category)) {
          categoryPrices[category] = [];
        }
        categoryPrices[category]!.add(price);

        // 카테고리별 키워드 수집
        if (!categoryKeywords.containsKey(category)) {
          categoryKeywords[category] = [];
        }
        final keywords = _extractKeywords(title);
        categoryKeywords[category]!.addAll(keywords);

        // 전체 키워드 빈도 계산
        for (final keyword in keywords) {
          keywordFrequency[keyword] = (keywordFrequency[keyword] ?? 0) + 1;
        }
      }

      print('🔍 [선호도] 분석된 카테고리: ${categoryPrices.keys.toList()}');
      
      // 상위 키워드 추출 (빈도 높은 순)
      final topKeywords = keywordFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topKeywordsList = topKeywords.take(10).map((e) => e.key).toList();
      print('🔍 [선호도] 상위 키워드: $topKeywordsList');

      // 카테고리별 평균 가격 계산 및 빈도순 정렬
      final preferences = categoryPrices.entries.map((entry) {
        final category = entry.key;
        final avgPrice = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final keywords = categoryKeywords[category] ?? [];
        
        // 카테고리별 키워드 빈도 계산
        final Map<String, int> categoryKeywordFreq = {};
        for (final keyword in keywords) {
          categoryKeywordFreq[keyword] = (categoryKeywordFreq[keyword] ?? 0) + 1;
        }
        
        // 상위 키워드 추출
        final topCategoryKeywords = categoryKeywordFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topKeywords = topCategoryKeywords.take(5).map((e) => e.key).toList();
        
        return {
          'category': category,
          'count': entry.value.length,
          'avgPrice': avgPrice,
          'keywords': topKeywords, // 카테고리별 상위 키워드
        };
      }).toList();

      // 빈도가 높은 순으로 정렬
      preferences.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // 전체 상위 키워드도 추가
      return preferences.map((pref) {
        return {
          ...pref,
          'topKeywords': topKeywordsList, // 전체 상위 키워드
        };
      }).toList();
    } catch (e) {
      print('사용자 선호도 분석 실패: $e');
      return [];
    }
  }

  /// 전체 인기 상품 (조회수 + 좋아요 기준)
  static Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      print('🔍 [인기상품] 인기 상품 조회 시작');
      
      // 가장 간단한 쿼리부터 시도 (인덱스 불필요)
      QuerySnapshot snapshot;
      try {
        // 1순위: status 필터만 (인덱스 불필요)
        snapshot = await _db
            .collection('products')
            .where('status', isEqualTo: 'available')
            .limit(limit * 3) // 충분히 많이 가져와서 필터링
            .get();
        print('🔍 [인기상품] 기본 쿼리 성공: ${snapshot.docs.length}개');
      } catch (e) {
        print('🔍 [인기상품] 기본 쿼리 실패: $e');
        // 2순위: 아무 필터 없이 최신순
        try {
          snapshot = await _db
              .collection('products')
              .orderBy('createdAt', descending: true)
              .limit(limit * 3)
              .get();
          print('🔍 [인기상품] 최신순 쿼리 성공: ${snapshot.docs.length}개');
        } catch (e2) {
          print('🔍 [인기상품] 최신순 쿼리도 실패: $e2');
          // 3순위: 아무 조건 없이
          snapshot = await _db
              .collection('products')
              .limit(limit * 3)
              .get();
          print('🔍 [인기상품] 무조건 쿼리 성공: ${snapshot.docs.length}개');
        }
      }

      // status 필터링 (메모리에서)
      final products = snapshot.docs
          .map((doc) => Product.fromDoc(doc))
          .where((p) => p.status == 'available')
          .toList();

      print('🔍 [인기상품] 필터링 후: ${products.length}개');

      // 인기도 점수 계산 후 재정렬
      products.sort((a, b) {
        final scoreA = a.viewCount * 2 + a.favoriteUserIds.length * 5;
        final scoreB = b.viewCount * 2 + b.favoriteUserIds.length * 5;
        return scoreB.compareTo(scoreA);
      });

      final result = products.take(limit).toList();
      print('🔍 [인기상품] 최종 반환: ${result.length}개');
      return result;
    } catch (e) {
      print('🔍 [인기상품] 전체 실패: $e');
      return [];
    }
  }

  /// 특정 상품과 유사한 상품 추천
  static Future<List<Product>> getSimilarProducts(Product product, {int limit = 5}) async {
    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _db
            .collection('products')
            .where('status', isEqualTo: 'available')
            .where('category', isEqualTo: product.category)
            .orderBy('viewCount', descending: true)
            .limit(limit * 2)
            .get();
      } catch (e) {
        // 인덱스 에러면 기본 쿼리로
        snapshot = await _db
            .collection('products')
            .where('status', isEqualTo: 'available')
            .where('category', isEqualTo: product.category)
            .orderBy('createdAt', descending: true)
            .limit(limit * 2)
            .get();
      }

      final products = snapshot.docs
          .map((doc) => Product.fromDoc(doc))
          .where((p) => p.id != product.id) // 자기 자신 제외
          .where((p) => p.sellerId != product.sellerId) // 같은 판매자 제외
          .toList();

      // 가격이 비슷한 순으로 정렬
      products.sort((a, b) {
        final diffA = (a.price - product.price).abs();
        final diffB = (b.price - product.price).abs();
        return diffA.compareTo(diffB);
      });

      return products.take(limit).toList();
    } catch (e) {
      print('유사 상품 가져오기 실패: $e');
      return [];
    }
  }
}

