import 'dart:developer';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;

import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/utils/snack_bar.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            height: 56.h,
            color: Colors.black,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 24.r),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Texts('Edit image', fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: AppFonts.inter),
                ),
                TextButton(
                  onPressed: _isCropping
                      ? null
                      : () {
                          try {
                            setState(() {
                              _isCropping = true;
                            });
                            Future.delayed(Duration(seconds: 1)).then((_){
                              _cropController.crop();
                            });
                          } catch (e) {
                            setState(() {
                              _isCropping = false;
                            });
                            showSnackBar(context, () {}, message: 'Failed to update cover: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
                          }
                        },
                  child: Texts('SAVE', fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.primaryOrange, fontFamily: AppFonts.inter),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Crop(
              controller: _cropController,
              image: widget.imageBytes,
              aspectRatio: 1,
              baseColor: Colors.black,
              maskColor: Colors.black.withOpacity(0.6),
              cornerDotBuilder: (size, edgeAlignment) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(size / 2)),
                );
              },
              onCropped: (result) async {
                if (!mounted) {
                  return;
                }
                // Handle CropResult from crop_your_image 2.0.0+
                // The result is a CropResult sealed class that can be CropSuccess or CropFailure
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    try {
                      // Compress the image before returning
                      final compressedImage = await _optimizeImage(croppedImage);
                      if (!mounted) return;
                      final navigatorContext = context;
                      Navigator.pop(navigatorContext, compressedImage);
                    } catch (e) {
                      if (!mounted) return;
                      log('Error compressing image: $e');
                      // Return original if compression fails
                      final navigatorContext = context;
                      Navigator.pop(navigatorContext, croppedImage);
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isCropping = false;
                        });
                      }
                    }
                  case CropFailure(:final cause):
                    if (!mounted) return;
                    setState(() {
                      _isCropping = false;
                    });
                    log('Crop failed: $cause');
                    final snackBarContext = context;
                    showSnackBar(
                      snackBarContext,
                      () {},
                      message: 'Failed to crop image: $cause',
                      backgroundColor: Colors.red,
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                }
              },
            ),
          ),
          if (_isCropping)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  /// Optimizes and compresses the image to reduce file size
  /// - Resizes to max 720px (maintaining aspect ratio)
  /// - Converts to JPEG with 85% quality
  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    const maxDimension = 720;
    img.Image processed = decoded;
    final largestSide = decoded.width > decoded.height ? decoded.width : decoded.height;

    // Resize if image is larger than max dimension
    if (largestSide > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(
          decoded,
          width: maxDimension,
          height: (decoded.height * maxDimension / decoded.width).round(),
        );
      } else {
        processed = img.copyResize(
          decoded,
          height: maxDimension,
          width: (decoded.width * maxDimension / decoded.height).round(),
        );
      }
    }

    // Encode as JPEG with 85% quality for good balance between size and quality
    final optimizedBytes = img.encodeJpg(processed, quality: 85);

    return Uint8List.fromList(optimizedBytes);
  }
}
