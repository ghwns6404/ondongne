import 'package:flutter/material.dart';
import '../../models/admin_news.dart';
import '../../services/admin_news_service.dart';

class AdminNewsFormScreen extends StatefulWidget {
  final AdminNews? adminNewsToEdit;
  
  const AdminNewsFormScreen({super.key, this.adminNewsToEdit});

  @override
  State<AdminNewsFormScreen> createState() => _AdminNewsFormScreenState();
}

class _AdminNewsFormScreenState extends State<AdminNewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedRegion = '대전 전체';
  bool _isLoading = false;

  final List<String> _regions = [
    '대전 전체',
    '대전 동구',
    '대전 중구',
    '대전 서구',
    '대전 대덕구',
    '대전 유성구',
  ];

  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 기존 데이터 로드
    if (widget.adminNewsToEdit != null) {
      _titleController.text = widget.adminNewsToEdit!.title;
      _contentController.text = widget.adminNewsToEdit!.content;
      _selectedRegion = widget.adminNewsToEdit!.region;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitAdminNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool isEditMode = widget.adminNewsToEdit != null;
      
      if (isEditMode) {
        // 수정 모드
        await AdminNewsService.updateAdminNews(
          widget.adminNewsToEdit!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          region: _selectedRegion,
          imageUrls: [],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('뉴스&이벤트가 수정되었습니다!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // 생성 모드
        await AdminNewsService.createAdminNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          region: _selectedRegion,
          imageUrls: [],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('뉴스&이벤트가 등록되었습니다!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.adminNewsToEdit != null ? '뉴스&이벤트 수정' : '뉴스&이벤트 작성'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 입력
              const Text(
                '제목',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '뉴스&이벤트 제목을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 지역 선택
              const Text(
                '지역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 내용 입력
              const Text(
                '내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '뉴스&이벤트 내용을 입력하세요',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 등록 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAdminNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.adminNewsToEdit != null ? '수정 완료' : '뉴스&이벤트 등록',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
