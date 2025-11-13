import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../services/profanity_filter_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedRegion = '대전 동구';
  bool _isLoading = false;
  String? _uploadProgress;
  List<XFile> _selectedImages = [];

  final List<String> _regions = [
    '대전 동구',
    '대전 중구',
    '대전 서구',
    '대전 대덕구',
    '대전 유성구',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('사진은 최대 3장까지 선택할 수 있습니다.'),
        backgroundColor: Colors.redAccent,
      ));
      setState(() { _selectedImages = images.take(3).toList(); });
    } else {
      setState(() { _selectedImages = images; });
    }
  }

  Future<List<String>> _uploadImagesAndGetUrls() async {
    if (_selectedImages.isEmpty) return [];
    
    try {
      setState(() {
        _uploadProgress = '이미지 업로드 중... (0/${_selectedImages.length})';
      });
      
      final urls = await StorageService.uploadMultipleImages(
        files: _selectedImages,
        folder: 'products',
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = '이미지 업로드 중... ($current/$total)';
            });
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _uploadProgress = null;
        });
      }
      
      if (urls.isEmpty) {
        throw Exception('이미지 업로드에 실패했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.');
      }
      
      return urls;
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
        });
      }
      
      // 더 구체적인 에러 메시지 제공
      String errorMessage = '이미지 업로드 중 오류가 발생했습니다.';
      if (e.toString().contains('permission') || e.toString().contains('권한')) {
        errorMessage = 'Firebase Storage 권한이 없습니다. Firebase 콘솔에서 Storage 규칙을 확인해주세요.';
      } else if (e.toString().contains('network') || e.toString().contains('네트워크')) {
        errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else if (e.toString().contains('size') || e.toString().contains('크기')) {
        errorMessage = '이미지 파일 크기가 너무 큽니다. 더 작은 이미지를 선택해주세요.';
      }
      
      throw Exception('$errorMessage\n\n상세: ${e.toString()}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // 욕설 필터링 검사 (제목과 설명 모두)
      await ProfanityFilterService.validateMultipleTexts([title, description]);
      
      final price = int.parse(_priceController.text);
      final imageUrls = await _uploadImagesAndGetUrls();
      
      await ProductService.createProduct(
        title: title,
        description: description,
        price: price,
        imageUrls: imageUrls,
        region: _selectedRegion,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('상품이 등록되었습니다!'), 
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: Text('상품 등록', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품명
              Text(
                '상품명',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '상품명을 입력해주세요',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 가격
              Text(
                '가격',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '가격을 입력해주세요 (원)',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '가격을 입력해주세요';
                  }
                  final price = int.tryParse(value);
                  if (price == null || price <= 0) {
                    return '올바른 가격을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 지역
              Text(
                '지역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    items: _regions.map((String region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRegion = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 상품 사진 (최대 3장)
              Text(
                '상품 사진 (최대 3장)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('사진 선택'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('선택: ${_selectedImages.length}/3'),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, idx) {
                    final img = _selectedImages[idx];
                    return FutureBuilder<Uint8List>(
                      future: img.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 90, height: 90,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                width: 90, height: 90, fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2, right: 2,
                              child: InkWell(
                                onTap: _isLoading ? null : () => setState(() { _selectedImages.removeAt(idx); }),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 상품 설명
              Text(
                '상품 설명',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '상품에 대한 자세한 설명을 입력해주세요',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품 설명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            if (_uploadProgress != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _uploadProgress!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          '상품 등록',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
