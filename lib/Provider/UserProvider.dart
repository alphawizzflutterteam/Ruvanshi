import 'package:TGSawadesiMartUser/Provider/SettingProvider.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '',
      _cartCount = '',
      _curBal = '',
      _mob = '',
      _profilePic = '',
      _bankFilePic = "",
      _email = '';
  String? _userId = '';

  String? _curPincode = '';
  String? _city_id = '';
  String? _city = '';

  late SettingProvider settingsProvider;

  String get curUserName => _userName;

  String get curPincode => _curPincode ?? '';
  String get city_id => _city_id ?? '';
  String get city => _city ?? '';
  String get curCartCount => _cartCount;

  String get curBalance => _curBal;

  String get mob => _mob;

  String get profilePic => _profilePic;
  String get bankFilePic => _bankFilePic;

  String? get userId => _userId;

  String get email => _email;

  void setPincode(String pin) {
    _curPincode = pin;
    notifyListeners();
  }

  void setCityID(String pin) {
    _city_id = pin;
    notifyListeners();
  }

  void setCity(String pin) {
    _city = pin;
    notifyListeners();
  }

  void setCartCount(String count) {
    _cartCount = count;
    notifyListeners();
  }

  void setBalance(String bal) {
    _curBal = bal;
    notifyListeners();
  }

  void setName(String count) {
    //settingsProvider.userName=count;
    _userName = count;
    notifyListeners();
  }

  void setMobile(String count) {
    _mob = count;
    notifyListeners();
  }

  void setProfilePic(String count) {
    _profilePic = count;
    notifyListeners();
  }

  void setBankPic(String count) {
    _bankFilePic = count;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setUserId(String? count) {
    _userId = count;
  }
}
