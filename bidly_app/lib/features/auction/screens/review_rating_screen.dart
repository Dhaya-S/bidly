import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/bidly_loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class ReviewRatingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReviewRatingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<ReviewRatingScreen> createState() => _ReviewRatingScreenState();
}

class _ReviewRatingScreenState extends ConsumerState<ReviewRatingScreen> {
  int _sellerRating = 0;
  final _commentController = TextEditingController();
  bool _reviewSubmitted = false;

  // Real review photos management
  final List<XFile> _selectedPhotos = [];
  List<String> _submittedPhotoUrls = [];
  bool _isUploading = false;
  String _uploadProgressText = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(orderProvider.notifier).fetchOrder(widget.orderId);
      if (ref.read(orderProvider).order == null) {
        await ref.read(orderProvider.notifier).fetchOrderByListing(widget.orderId);
      }
      final effectiveOrderId = ref.read(orderProvider).order?.id ?? widget.orderId;
      final existingReview = await ref.read(orderProvider.notifier).fetchOrderReview(effectiveOrderId);
      if (mounted && existingReview != null) {
        setState(() {
          _reviewSubmitted = true;
          _sellerRating = (existingReview['rating'] as num?)?.toInt() ?? 5;
          _commentController.text = existingReview['comment']?.toString() ?? '';
          final photos = existingReview['photoUrls'];
          if (photos is List) {
            _submittedPhotoUrls = photos.map((p) => p.toString()).toList();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final remaining = 5 - _selectedPhotos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (picked.isNotEmpty && mounted) {
        setState(() {
          _selectedPhotos.addAll(picked.take(remaining));
        });
      }
    } catch (e) {
      debugPrint('[REVIEW] Error picking photos: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_selectedPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (photo != null && mounted) {
        setState(() {
          _selectedPhotos.add(photo);
        });
      }
    } catch (e) {
      debugPrint('[REVIEW] Error taking photo: $e');
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Review Photos',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Show the condition of the received product (up to 5 photos)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF004E54).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF004E54), size: 22),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Select photos from your device',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery();
              },
            ),
            const Divider(height: 8, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF004E54).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF004E54), size: 22),
              ),
              title: const Text(
                'Take a Photo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Snap a new picture with camera',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Photo Preview', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: FileImage(file),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
            ),
          ),
        ),
      ),
    );
  }

  void _openUrlPhotoViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Review Photo', style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(ApiClient.resolveMediaUrl(url)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_sellerRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating for the seller'),
          backgroundColor: Color(0xFF004E54),
        ),
      );
      return;
    }

    final currentUserId = ref.read(authProvider).user?.id ?? 'user';
    final apiClient = ref.read(apiClientProvider);
    final effectiveOrderId = ref.read(orderProvider).order?.id ?? widget.orderId;

    setState(() {
      _isUploading = true;
      _uploadProgressText = _selectedPhotos.isNotEmpty
          ? 'Uploading photos (1/${_selectedPhotos.length})...'
          : 'Submitting review...';
    });

    final List<String> uploadedKeys = [];

    try {
      // 1. Upload photos if selected; gracefully catch errors so text review is not blocked
      for (int i = 0; i < _selectedPhotos.length; i++) {
        if (mounted) {
          setState(() {
            _uploadProgressText = 'Uploading photo ${i + 1} of ${_selectedPhotos.length}...';
          });
        }

        try {
          final photo = _selectedPhotos[i];
          final fileName = photo.path.split(RegExp(r'[\\/]')).last;
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(photo.path, filename: fileName),
            'folder': 'reviews/$currentUserId',
          });

          final uploadRes = await apiClient.post('/media/upload', data: formData);
          if (uploadRes.data != null && uploadRes.data['success'] == true && uploadRes.data['data'] != null) {
            final urlKey = uploadRes.data['data']['url']?.toString();
            if (urlKey != null && urlKey.isNotEmpty) {
              uploadedKeys.add(urlKey);
            }
          }
        } catch (uploadErr) {
          debugPrint('[REVIEW] Photo upload error: $uploadErr');
        }
      }

      if (mounted) {
        setState(() {
          _uploadProgressText = 'Saving review...';
        });
      }

      // 2. Submit review to backend with resolved effective order ID
      final success = await ref.read(orderProvider.notifier).submitReview(
            orderId: effectiveOrderId,
            rating: _sellerRating,
            comment: _commentController.text.trim(),
            photoUrls: uploadedKeys,
          );

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (success) {
          setState(() {
            _submittedPhotoUrls = uploadedKeys;
            _reviewSubmitted = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully! Thank you for your feedback.'),
              backgroundColor: Color(0xFF004E54),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          final err = ref.read(orderProvider).errorMessage ?? 'Failed to submit review. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: const Color(0xFFE11D48),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    }
  }

  void _showReportProblemSheet() {
    String selectedReason = "Seller didn't show up";
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final reasons = [
            {
              'title': "Seller didn't show up",
              'desc': "The seller cancelled or never arrived at the meetup",
            },
            {
              'title': "Item not as described",
              'desc': "Product condition or details were misrepresented",
            },
            {
              'title': "Suspected fraud or scam",
              'desc': "Seller behaviour seemed suspicious or dishonest",
            },
            {
              'title': "Fake or counterfeit item",
              'desc': "The item appears to be inauthentic or replicated",
            },
            {
              'title': "Aggressive / rude behaviour",
              'desc': "Seller was intimidating or disrespectful",
            },
            {
              'title': "Other issue",
              'desc': "Something else went wrong — describe below",
            },
          ];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report a Problem',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'What went wrong with this transaction?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetCtx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...reasons.map((item) {
                  final title = item['title']!;
                  final desc = item['desc']!;
                  final isSelected = selectedReason == title;

                  return GestureDetector(
                    onTap: () => setModalState(() => selectedReason = title),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF004E54) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF004E54) : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF004E54) : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                              color: isSelected ? const Color(0xFF004E54) : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 13, color: Colors.white),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add more details (optional)...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF004E54)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            final ok = await ref.read(orderProvider.notifier).submitReport(
                                  orderId: widget.orderId,
                                  reason: selectedReason,
                                  details: detailsController.text.trim(),
                                );
                            if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                            if (mounted) {
                              if (ok) {
                                _showReportSubmittedConfirmation();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to submit report. Please try again.')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E54),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag_outlined, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Submit Report',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReportSubmittedConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.flag_rounded, color: Color(0xFFDC2626), size: 34),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for letting us know. Our team will review the report within 24 hours and take appropriate action.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E54),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSubmittedView(String sellerName) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF004E54),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004E54).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Review Submitted!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for your feedback. Your review helps the BIDLY community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Ratings',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seller',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              sellerName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < _sellerRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 22,
                          )),
                        ),
                      ],
                    ),
                    if (_commentController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '"${_commentController.text.trim()}"',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    if (_submittedPhotoUrls.isNotEmpty || _selectedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 14, color: Color(0xFF004E54)),
                          const SizedBox(width: 6),
                          Text(
                            'Photos Attached (${_submittedPhotoUrls.isNotEmpty ? _submittedPhotoUrls.length : _selectedPhotos.length})',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF004E54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 68,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _submittedPhotoUrls.isNotEmpty
                              ? _submittedPhotoUrls.length
                              : _selectedPhotos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            if (_submittedPhotoUrls.isNotEmpty) {
                              final url = _submittedPhotoUrls[idx];
                              return GestureDetector(
                                onTap: () => _openUrlPhotoViewer(url),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    ApiClient.resolveMediaUrl(url),
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 68,
                                      height: 68,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final photo = _selectedPhotos[idx];
                              return GestureDetector(
                                onTap: () => _openPhotoViewer(File(photo.path)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(photo.path),
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E54),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004E54),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'View Seller Profile',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final order = state.order;

    if (state.isLoading && order == null) {
      return const BidlyLoadingScreen(message: 'Loading order details...');
    }

    final sellerName = (order?.sellerName != null && order!.sellerName.trim().isNotEmpty)
        ? order.sellerName.trim()
        : '';

    final String sellerInitials;
    if (sellerName.isNotEmpty) {
      final parts = sellerName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        sellerInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        sellerInitials = sellerName.substring(0, sellerName.length >= 2 ? 2 : 1).toUpperCase();
      }
    } else {
      sellerInitials = 'S';
    }

    if (_reviewSubmitted) {
      return _buildReviewSubmittedView(sellerName.isNotEmpty ? sellerName : 'Seller');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go('/'),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.textPrimary),
              ),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Rate',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Help others with your honest feedback',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go('/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.skip_next_rounded, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Rate the Seller Card (Matching image exactly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF004E54),
                            child: Text(
                              sellerInitials,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rate the Seller',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sellerName.isNotEmpty ? sellerName : 'Seller',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Interactive 5-Star Row for Seller (Empty grey outlines when unselected, gold when selected)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1;
                          final isSelected = starVal <= _sellerRating;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _sellerRating = starVal;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 38,
                                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Experience Text Field
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Share your experience with this seller...\n(optional)',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Add Photos Card (Matching image 1:1)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Photos',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Optional · Help others see the product',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedPhotos.isEmpty)
                        GestureDetector(
                          onTap: _showPhotoSourceSheet,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFCCFBF1),
                                width: 1.2,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: Color(0xFF004E54), size: 26),
                                SizedBox(height: 5),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF004E54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedPhotos.length < 5
                                ? _selectedPhotos.length + 1
                                : _selectedPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              if (index == _selectedPhotos.length && _selectedPhotos.length < 5) {
                                return GestureDetector(
                                  onTap: _showPhotoSourceSheet,
                                  child: Container(
                                    width: 82,
                                    height: 82,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFCCFBF1),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_outlined, color: Color(0xFF004E54), size: 26),
                                        SizedBox(height: 5),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF004E54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final photo = _selectedPhotos[index];
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _openPhotoViewer(File(photo.path)),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        File(photo.path),
                                        width: 82,
                                        height: 82,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedPhotos.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Actions: [ Submit Review ] and [ Report Problem ]
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isUploading || state.isSubmittingReview) ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004E54),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: (_isUploading || state.isSubmittingReview)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _uploadProgressText.isNotEmpty ? _uploadProgressText : 'Submitting...',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Review',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _showReportProblemSheet,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F2),
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFECDD3), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE11D48)),
                            SizedBox(width: 8),
                            Text(
                              'Report Problem',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
