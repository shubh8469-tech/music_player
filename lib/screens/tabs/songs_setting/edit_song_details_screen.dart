import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/font.dart';
import '../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../commonWidgets/gradientCard.dart';
import '../../../commonWidgets/text_field_widget.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';

class EditSongDetailsScreen extends StatefulWidget {
  const EditSongDetailsScreen({super.key});

  @override
  State<EditSongDetailsScreen> createState() => _EditSongDetailsScreenState();
}

class _EditSongDetailsScreenState extends State<EditSongDetailsScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController albumController = TextEditingController();
  TextEditingController artistController = TextEditingController();
  TextEditingController genreController = TextEditingController();
  TextEditingController trackController = TextEditingController();
  FocusNode titleFocusNode = FocusNode();
  FocusNode albumFocusNode = FocusNode();
  FocusNode artistFocusNode = FocusNode();
  FocusNode genreFocusNode = FocusNode();
  FocusNode trackFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithIconTitle(title: S.of(context).editDetails),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 25, horizontal: 15),
          child: Column(
            children: [
              GradientCard(
                height: 100.h,
                width: 100.w,
                colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
                borderRadius: 8.r,
                iconAsset: Assets.svgIcTunes,
                iconSize: 80.r,
                title: "",
                onTap: () {},
                margin: 10.w,
              ),
              SizedBox(height: 20.h),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(80.r),
                  border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1.w),
                ),
                height: 50.h,
                width: 150.w,
                child: Texts(S.of(context).changeCover, align: TextAlign.center),
              ),
              SizedBox(height: 50.h),
              titleWidget(),
              albumWidget(),
              artistWidget(),
              genreWidget(),
              trackNUmberWidget(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 25.0),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(80.r),
                border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
              ),
              height: 50.w,
              width: 160.w,
              child: Texts(
                S.of(context).cancel,
                fontSize: 14.sp,
                align: TextAlign.center,
                fontWeight: FontWeight.w500,
                color: AppColors.textColor,
                fontFamily: AppFonts.medium,
              ),
            ),
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(80),
                border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
              ),
              height: 50.w,
              width: 160.w,
              child: Texts(
                S.of(context).save,
                fontSize: 14.sp,
                align: TextAlign.center,
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget titleWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(S.of(context).title, fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: titleController,
            fillColor: AppColors.bgGrey.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: titleFocusNode,
            hasFocus: titleFocusNode.hasFocus,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(albumFocusNode);
            },
          ),
        ),
      ],
    );
  }

  Widget albumWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(S.of(context).album, fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: albumController,
            fillColor: AppColors.bgGrey.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: albumFocusNode,
            hasFocus: albumFocusNode.hasFocus,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(artistFocusNode);
            },
          ),
        ),
      ],
    );
  }

  Widget artistWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(S.of(context).artist, fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: artistController,
            fillColor: AppColors.bgGrey.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: artistFocusNode,
            hasFocus: artistFocusNode.hasFocus,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(genreFocusNode);
            },
          ),
        ),
      ],
    );
  }

  Widget genreWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(S.of(context).genre, fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: genreController,
            fillColor: AppColors.bgGrey.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: genreFocusNode,
            hasFocus: genreFocusNode.hasFocus,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(trackFocusNode);
            },
          ),
        ),
      ],
    );
  }

  Widget trackNUmberWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(S.of(context).trackNumber, fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: trackController,
            fillColor: AppColors.bgGrey.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.done,
            focusNode: trackFocusNode,
            hasFocus: trackFocusNode.hasFocus,
            onFieldSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ],
    );
  }
}
