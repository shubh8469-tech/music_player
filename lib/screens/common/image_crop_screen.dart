import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../themes/color.dart';
import '../../themes/font.dart';
import '../../commonWidgets/textWidget.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
  });

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
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.r,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Texts(
                    'Edit image',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: AppFonts.inter,
                  ),
                ),
                TextButton(
                  onPressed: _isCropping
                      ? null
                      : () {
                          setState(() {
                            _isCropping = true;
                          });
                          _cropController.crop();
                        },
                  child: Texts(
                    'SAVE',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                    fontFamily: AppFonts.inter,
                  ),
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
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(size / 2),
                  ),
                );
              },
              onCropped: (croppedBytes) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isCropping = false;
                });
                Navigator.pop(context, croppedBytes);
              },
            ),
          ),
          if (_isCropping)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

