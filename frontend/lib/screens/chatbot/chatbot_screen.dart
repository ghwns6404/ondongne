import 'package:flutter/material.dart';
import '../../models/chatbot_message.dart';
import '../../services/chatbot_service.dart';
import '../widgets/search_result_card.dart';
import '../marketplace/product_detail_screen.dart';
import '../news/news_detail_screen.dart';
import '../../services/product_service.dart';
import '../../services/news_service.dart';
import '../../services/admin_news_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatbotMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 초기 메시지
    _addBotMessage(
      '안녕하세요! 온동네 챗봇 서비스입니다. 😊\n\n어떤 기능을 원하시나요?\n예: "장난감 관련 글 찾아줘"',
      MessageType.text,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String content, MessageType type,
      {List<SearchResultItem>? searchResults}) {
    setState(() {
      _messages.add(ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.bot,
        type: type,
        content: content,
        timestamp: DateTime.now(),
        searchResults: searchResults,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add(ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.user,
        type: MessageType.text,
        content: content,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final query = _inputController.text.trim();
    if (query.isEmpty || _isLoading) return;

    // 사용자 메시지 추가
    _addUserMessage(query);
    _inputController.clear();

    // 로딩 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // 챗봇 서비스 호출
      final result = await ChatbotService.search(query);

      final message = result['message'] as String;
      final searchResults = result['results'] as List<SearchResultItem>;

      if (searchResults.isEmpty) {
        _addBotMessage(message, MessageType.text);
      } else {
        _addBotMessage(message, MessageType.searchResult,
            searchResults: searchResults);
      }
    } catch (e) {
      _addBotMessage(
        '죄송합니다. 오류가 발생했습니다.\n${e.toString().replaceAll('Exception: ', '')}',
        MessageType.text,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToDetail(SearchResultItem item) async {
    try {
      if (item.type == 'product') {
        // 상품 상세 정보 가져오기
        final product = await ProductService.getProduct(item.id);
        if (mounted && product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      } else {
        // 뉴스 상세 정보 가져오기
        var news = await NewsService.getNews(item.id);
        news ??= await AdminNewsService.getAdminNews(item.id);
        
        if (mounted && news != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(news: news!),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상세 정보를 불러올 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: 400, // 사이드 패널 너비
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '온동네 챗봇',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildLoadingMessage();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // 입력창
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue[600],
                  child: IconButton(
                    onPressed: _isLoading ? null : _handleSend,
                    icon: Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.smart_toy, color: Colors.blue[600], size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('검색 중...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.smart_toy, color: Colors.blue[600], size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[600] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                
                // 검색 결과 카드
                if (message.type == MessageType.searchResult &&
                    message.searchResults != null &&
                    message.searchResults!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...message.searchResults!.map(
                    (item) => SearchResultCard(
                      item: item,
                      onTap: () => _navigateToDetail(item),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

