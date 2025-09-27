import 'dart:convert';
import 'dart:ui';
import 'package:TGSawadesiMartUser/Helper/widgets.dart';
import 'package:TGSawadesiMartUser/Model/SingleSellerModal.dart';
import 'package:TGSawadesiMartUser/Model/UpdateUserModels.dart';
import 'package:TGSawadesiMartUser/Model/UserDetails.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../Provider/SettingProvider.dart';
import '../../Screen/HomePage.dart';
import '../Session.dart';
import '../String.dart';

Future<UserDetails?> userDetails() async {
  var header = headers;
  var request = http.MultipartRequest('POST', getUserDetailsApi);
  request.fields.addAll({'user_id': '$CUR_USERID'});

  request.headers.addAll(header);
  print(request);
  print(request.fields);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final str = await response.stream.bytesToString();
    print(str);
    return UserDetails.fromJson(json.decode(str));
  } else {
    return null;
  }
}

Future<UpdateUserModels?> uploadImage(param, image) async {
  var header = headers;
  var request = http.MultipartRequest('POST', updateUserApi);
  request.fields.addAll({'user_id': '$CUR_USERID'});
  request.files.add(await http.MultipartFile.fromPath('$param', '$image'));
  request.headers.addAll(header);

  http.StreamedResponse response = await request.send();
  print(request.fields);
  print(request.files[0].field);
  print(response.statusCode);
  if (response.statusCode == 200) {
    final str = await response.stream.bytesToString();
    return UpdateUserModels.fromJson(json.decode(str));
  } else {
    return null;
  }
}

Future<UpdateUserModels?> updateUserDetails(
    userName, email, dob, cityId) async {
  var header = headers;
  var request = http.MultipartRequest('POST', updateUserApi);
  request.fields.addAll({
    'user_id': '$CUR_USERID',
    'username': '$userName',
    'email': '$email',
    'dob': '$dob',
    'city': '$cityId'
  });
  print('PrintDaxcvxcta:_____${request.fields}______');
  request.headers.addAll(header);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final str = await response.stream.bytesToString();
    return UpdateUserModels.fromJson(json.decode(str));
  } else {
    return null;
  }
}

Future<SingleSellerModal?> singleSeller(sellerId) async {
  var header = headers;
  var request = http.MultipartRequest('POST', getSellerApi);
  request.fields.addAll({'seller_id': sellerId});

  request.headers.addAll(header);
  print("API Seller Id: $sellerId");
  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final data = await response.stream.bytesToString();
    return SingleSellerModal.fromJson(json.decode(data));
  } else {
    return null;
  }
}

checkOnOff(sellerId) async {
  SingleSellerModal? modal = await singleSeller(sellerId);
  if (modal!.error == false) {
    if (modal.data![0].openCloseStatus == '1') {
      print(
          "CHEK ON OFF STATUS ========================> ${modal.data![0].openCloseStatus}");
      return true;
    } else {
      return false;
    }
  } else {
    print("Error");
  }
}

Future<String> deleteAccount(userId) async {
  var header = headers;
  var request = http.MultipartRequest('POST', getDeleteAccountApi);
  request.fields.addAll({'user_id': userId});
  request.headers.addAll(header);
  http.StreamedResponse response = await request.send();
  print('response  $response');
  if (response.statusCode == 200) {
    final data = await response.stream.bytesToString();
    return json.decode(data)['message'];
  } else {
    return 'Unable to delete account';
  }
}

Color primaryColor = Colors.black;
Color secondaryColor = Colors.white;
Color backgroundColor = Colors.white;
Color textColor = Colors.black;
BoxDecoration dynamicGradient() {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryColor, primaryColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

String? appLogo;

String PRIMARY_COLOR = 'primary';
String SECONDARY_COLOR = 'secondary';
String BACKGROUND_COLOR = 'background';
String TEXT_COLOR = 'text';
String APP_LOGO = 'app_logo';
String BASE_URL = "https://developmentalphawizz.com/ruvanshi/";

Color hexToColor(String hex) {
  try {
    if (hex.length == 6) {
      return Color(int.parse("0xFF$hex"));
    }
    return Colors.black; // fallback
  } catch (e) {
    print("Hex parse error: $e");
    return Colors.black;
  }
}

void getSetting() {
  Map<String, dynamic> parameter = {};
  if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

  apiBaseHelper.postAPICall(getThemeApi, parameter).then((getdata) async {
    bool error = getdata["error"];
    if (!error) {
      var data = getdata["data"];
      var colors = data["colors"];
      String? primaryHex = colors[PRIMARY_COLOR]?.toString();
      String? secondaryHex = colors[SECONDARY_COLOR]?.toString();
      String? backgroundHex = colors[BACKGROUND_COLOR]?.toString();
      String? textHex = colors[TEXT_COLOR]?.toString();

      if (primaryHex != null && primaryHex.isNotEmpty) {
        primaryColor = hexToColor(primaryHex);
      }
      if (secondaryHex != null && secondaryHex.isNotEmpty) {
        secondaryColor = hexToColor(secondaryHex);
      }
      if (backgroundHex != null && backgroundHex.isNotEmpty) {
        backgroundColor = hexToColor(backgroundHex);
      }
      if (textHex != null && textHex.isNotEmpty) {
        textColor = hexToColor(textHex);
      }
      String? logoPath = data[APP_LOGO]?.toString();
      if (logoPath != null && logoPath.isNotEmpty) {
        appLogo = BASE_URL + logoPath;
      }
      print("Primary: $primaryColor");
      print("Secondary: $secondaryColor");
      print("Background: $backgroundColor");
      print("Text: $textColor");
      print("App Logo: $appLogo");
      // if (mounted) setState(() {});
    }
  }, onError: (error) {
    print("API Error: $error");
  });
}
