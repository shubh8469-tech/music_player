

import 'package:flutter/cupertino.dart';

class HoldTheTapFor extends ChangeNotifier{

  bool _isHoldingShuffle = false;
  bool _isHoldingPlay = false;
  bool _isHoldingSongPLay = false;

  bool get isHoldingShuffle => _isHoldingShuffle;
  bool get isHoldingPlay => _isHoldingPlay;
  bool get isHoldingSongPLay => _isHoldingSongPLay;

  Future<void> startHoldingShuffle() async{
    _isHoldingShuffle = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    _isHoldingShuffle = false;
    notifyListeners();
  }

  Future<void> startHoldingPlay() async{
    _isHoldingPlay = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    _isHoldingPlay = false;
    notifyListeners();
  }

  Future<void> startHoldingSongPlay() async{
    _isHoldingSongPLay = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _isHoldingSongPLay = false;
    notifyListeners();
  }

}