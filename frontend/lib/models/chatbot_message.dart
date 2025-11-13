enum MessageType {
  text,      // 일반 텍스트 메시지
  searchResult,  // 검색 결과 (클릭 가능한 카드)
}

enum MessageSender {
  user,      // 사용자
  bot,       // 챗봇
}

class ChatbotMessage {
  final String id;
  final MessageSender sender;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final List<SearchResultItem>? searchResults;

  ChatbotMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.content,
    required this.timestamp,
    this.searchResults,
  });
}

/// 검색 결과 아이템 (중고거래 또는 소식)
class SearchResultItem {
  final String id;
  final String type; // 'product' 또는 'news'
  final String title;
  final String? description;
  final String? imageUrl;
  final int? price; // 상품인 경우
  final DateTime createdAt;

  SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    this.price,
    required this.createdAt,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

