import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../commonWidgets/textWidget.dart';
import '../commonWidgets/text_field_widget.dart';
import '../l10n/l10n.dart';
import '../themes/color.dart';
import '../themes/font.dart';

class EditTagBottomSheet extends StatefulWidget {
  final String initialValue;
  final String title;
  final Function(String) onSave;
  final String? label;

  const EditTagBottomSheet({
    super.key,
    required this.initialValue,
    required this.title,
    required this.onSave,
    this.label,
  });

  @override
  State<EditTagBottomSheet> createState() => _EditTagBottomSheetState();
}

class _EditTagBottomSheetState extends State<EditTagBottomSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // Auto-focus the text field when the bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Move cursor to end
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleOk() {
    final trimmedValue = _controller.text.trim();
    if (trimmedValue.isEmpty) {
      return;
    }
    widget.onSave(trimmedValue);
    Navigator.pop(context);
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Texts(
            widget.title,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 20.h),
          // Text input field
          TextFieldWidget(
            controller: _controller,
            fillColor: AppColors.textColor.withValues(alpha: .14),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.done,
            focusNode: _focusNode,
            hasFocus: _focusNode.hasFocus,
            onFieldSubmitted: (_) => _handleOk(),
            onTextChanged: (_) {},
          ),
          SizedBox(height: 24.h),
          // Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: InkWell(
                  onTap: _handleCancel,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    alignment: Alignment.center,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Texts(
                      S.of(context).cancel.toUpperCase(),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.medium,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // OK button
              Expanded(
                child: InkWell(
                  onTap: _handleOk,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    alignment: Alignment.center,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.mildOrange,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Texts(
                      'OK',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.medium,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

