import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:TGSawadesiMartUser/Model/city_model.dart';
import 'package:TGSawadesiMartUser/Screen/MyOrder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/cropped_container.dart';
import '../Model/User.dart';
import '../Provider/SettingProvider.dart';
import '../Provider/UserProvider.dart';
import 'Cart.dart';
import 'Login.dart';
import 'package:http/http.dart' as http;

class SignUp extends StatefulWidget {
  late final bool? update;
  late final int? index;
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUp> with TickerProviderStateMixin {
  bool? _showPassword = false;
  bool visible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final ccodeController = TextEditingController();
  final passwordController = TextEditingController();
  final referController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  int count = 1;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<CityListModel> cityList = [];
  List<CityListModel> citySearchLIst = [];
  bool cityLoading = true;
  StateSetter? cityState;
  int? selCityPos = -1;
  DateTime selectedDate = DateTime.now();
  String? name,
      email,
      password,
      mobile,
      id,
      countrycode,
      city,
      cityId,
      area,
      pincode,
      address,
      latitude,
      longitude,
      referCode,
      friendCode;
  FocusNode? nameFocus,
      emailFocus,
      passFocus = FocusNode(),
      referFocus = FocusNode();
  bool _isNetworkAvail = true;
  Animation? labelLargeSqueezeanimation;

  AnimationController? labelLargeController;

  String? _selectedCity; // Stores the selected city
  List<CityListModel> _cities = []; // Stores the list of cities
  bool _isLoading = true; // Loading indicator

  var genderSelect;
  var bankImg = null;
  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  getUserDetails() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    mobile = await settingsProvider.getPrefrence(MOBILE);
    countrycode = await settingsProvider.getPrefrence(COUNTRY_CODE);
    if (mounted) setState(() {});
  }

  Future<Null> _playAnimation() async {
    try {
      await labelLargeController!.forward();
    } on TickerCanceled {}
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      // if (referCode != null) getRegisterUser();
      getRegisterUser();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
        await labelLargeController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    labelLargeController!.dispose();
    super.dispose();
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      elevation: 1.0,
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
    ));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(top: kToolbarHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: labelLargeSqueezeanimation,
            btnCntrl: labelLargeController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await labelLargeController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<void> getRegisterUser() async {
    try {
      DateTime date = selectedDate;
      var request = MultipartRequest("POST", (getUserSignUpApi));
      request.headers.addAll(headers);
      request.fields[MOBILE] = mobile!;
      request.fields[COUNTRY_CODE] = countrycode!;
      request.fields[NAME] = name!;
      request.fields[EMAIL] = email!;
      request.fields[PASSWORD] = password!;
      request.fields[CITY] = cityId.toString()!;
      request.fields["gender"] = genderSelect ?? "male";
      // request.fields["dob"] = "${date.day}-${date.month}-${date.year}";
      request.fields[FRNDCODE] = referController.text.toString();

      if (selCityPos != null) {
        request.fields['city'] = cityList[selCityPos ?? 0].id ?? '';
      }

      request.fields["gender"] = genderSelect ?? "male";
      // var pic = await MultipartFile.fromPath("bank_pass", bankImg.path);
      // request.files.add(pic);
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      print("sdfsdfsdfassdfsd=============");
      print(request);
      print(request.fields);
      print(responseString);
      var getdata = json.decode(responseString);
      print("${getdata}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
      bool error = getdata["error"];
      String? msg = getdata["message"];
      await labelLargeController!.reverse();
      if (!error) {
        // setSnackbar(getTranslated(context, 'REGISTER_SUCCESS_MSG')!);
        Fluttertoast.showToast(
            msg: getTranslated(context, 'REGISTER_SUCCESS_MSG')!,
            backgroundColor: colors.primary);
        var i = getdata["data"][0];

        id = i[ID];
        name = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        //countrycode=i[COUNTRY_CODE];
        CUR_USERID = id;

        // CUR_USERNAME = name;

        UserProvider userProvider = context.read<UserProvider>();
        userProvider.setName(name ?? "");
        userProvider.setBankPic(i["bank_pass"] ?? "");

        SettingProvider settingProvider = context.read<SettingProvider>();
        settingProvider.saveUserDetail(
            id!,
            name,
            email,
            mobile,
            cityList[selCityPos ?? 0].id ?? '',
            area,
            address,
            pincode,
            latitude,
            longitude,
            "",
            "",
            cityList[selCityPos ?? 0].id ?? '',
            context);

        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      } else {
        setSnackbar(msg!);
      }
      if (mounted) setState(() {});
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await labelLargeController!.reverse();
    }
  }

  Future<void> getCities() async {
    try {
      var headers = {
        'Cookie': 'ci_session=cc08d4381b4fdf4681fe5697fbda2886d2fda585',
      };
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://developmentalphawizz.com/ruvanshi/app/v1/api/city'),
      );
      request.headers.addAll(headers);
      print("Sending request to: ${request.url}");
      print("Headers: ${request.headers}");
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();
      print("Response Status: ${response.statusCode}");
      print("Response Body: $responseBody");
      if (response.statusCode == 200) {
        var getdata = json.decode(responseBody);
        print("Decoded Data: $getdata");
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          if (data != null && data is List) {
            cityList = data.map((e) => CityListModel.fromJson(e)).toList();
            print("City List: $cityList");
            citySearchLIst.addAll(cityList);
          } else {
            print("Error: Data is null or not a list");
            setSnackbar("Invalid city data received");
          }
        } else {
          print("Error from API: $msg");
          setSnackbar(msg ?? "Unknown error occurred");
        }
      } else {
        print("HTTP Error: ${response.reasonPhrase}");
        setSnackbar("Failed to fetch cities: ${response.reasonPhrase}");
      }
      cityLoading = false;
      if (mounted) {
        if (cityState != null) cityState!(() {});
        setState(() {});
      }
      // if (widget.update == true) {
      //   if (widget.index != null && cityList.isNotEmpty) {
      //     selCityPos = citySearchLIst
      //         .indexWhere((f) => f.id == cityList[widget.index!].city);
      //     print("Selected City Position: $selCityPos");

      //     if (selCityPos == -1) selCityPos = null;
      //   }
      // }
    } on TimeoutException {
      setSnackbar(
          getTranslated(context, 'timeoutError') ?? 'Request timed out');
    } catch (e) {
      setSnackbar(
          getTranslated(context, 'somethingMsg') ?? 'Something went wrong');
      print("Error: $e");
    }
  }

  Widget registerTxt() {
    return Padding(
      padding: EdgeInsets.only(top: 30, left: 10),
      child: Align(
        alignment: Alignment.center,
        child: Text(getTranslated(context, 'USER_REGISTER_DETAILS')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 25)),
      ),
    );
  }

  setUserName() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 15.0,
        end: 15.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: nameController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        validator: (val) => validateUserName(
            val!,
            getTranslated(context, 'USER_REQUIRED'),
            getTranslated(context, 'USER_LENGTH')),
        onSaved: (String? value) {
          name = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIcon: Icon(
            Icons.account_circle_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 17,
          ),
          hintText: getTranslated(context, 'NAMEHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          // filled: true,
          // fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 25),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
          //   borderRadius: BorderRadius.circular(10.0),
          // ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setEmail() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: 10.0,
        start: 15.0,
        end: 15.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        controller: emailController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        validator: (val) => validateEmail(
            val!,
            getTranslated(context, 'EMAIL_REQUIRED'),
            getTranslated(context, 'VALID_EMAIL')),
        onSaved: (String? value) {
          email = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, passFocus);
        },
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIcon: Icon(
            Icons.alternate_email_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 17,
          ),
          hintText: getTranslated(context, 'EMAILHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          // filled: true,
          // fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 25),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
          //   borderRadius: BorderRadius.circular(10.0),
          // ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setRefer() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: 10.0,
        start: 15.0,
        end: 15.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.text,
        focusNode: referFocus,
        controller: referController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        onSaved: (String? value) {
          friendCode = value;
        },
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIcon: Icon(
            Icons.card_giftcard_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 17,
          ),
          hintText: getTranslated(context, 'REFER'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          // filled: true,
          // fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 25),
          // focusedBorder: OutlineInputBorder(
          //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
          //   borderRadius: BorderRadius.circular(10.0),
          // ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  // setPass() {
  //   return Padding(
  //       padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0, top: 10.0),
  //       child: TextFormField(
  //         keyboardType: TextInputType.text,
  //         obscureText: !_showPassword!,
  //         focusNode: passFocus,
  //         onFieldSubmitted: (v) {
  //           _fieldFocusChange(context, passFocus!, referFocus);
  //         },
  //         textInputAction: TextInputAction.next,
  //         style: TextStyle(
  //             color: Theme.of(context).colorScheme.fontColor,
  //             fontWeight: FontWeight.normal),
  //         controller: passwordController,
  //         validator: (val) => validatePass(
  //             val!,
  //             getTranslated(context, 'PWD_REQUIRED'),
  //             getTranslated(context, 'PWD_LENGTH')),
  //         onSaved: (String? value) {
  //           password = value;
  //         },
  //         decoration: InputDecoration(
  //           focusedBorder: UnderlineInputBorder(
  //             borderSide: BorderSide(color: colors.primary),
  //             borderRadius: BorderRadius.circular(7.0),
  //           ),
  //           prefixIcon: SvgPicture.asset(
  //             "assets/images/password.svg",
  //             height: 17,
  //             width: 17,
  //             color: Theme.of(context).colorScheme.fontColor,
  //           ),
  //           // Icon(
  //           //   Icons.lock_outline,
  //           //   color: Theme.of(context).colorScheme.lightBlack2,
  //           //   size: 17,
  //           // ),
  //           hintText: getTranslated(context, 'PASSHINT_LBL'),
  //           hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
  //               color: Theme.of(context).colorScheme.fontColor,
  //               fontWeight: FontWeight.normal),
  //           // filled: true,
  //           // fillColor: Theme.of(context).colorScheme.lightWhite,
  //           contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //           prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 25),
  //           // focusedBorder: OutlineInputBorder(
  //           //   borderSide: BorderSide(color: Theme.of(context).colorScheme.fontColor),
  //           //   borderRadius: BorderRadius.circular(10.0),
  //           // ),
  //           enabledBorder: UnderlineInputBorder(
  //             borderSide:
  //                 BorderSide(color: Theme.of(context).colorScheme.fontColor),
  //             borderRadius: BorderRadius.circular(10.0),
  //           ),
  //         ),
  //       ));
  // }
  setPass() {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0, top: 10.0),
      child: TextFormField(
        keyboardType: TextInputType.text,
        obscureText: !_showPassword!,
        focusNode: passFocus,
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, passFocus!, referFocus);
        },
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        controller: passwordController,
        validator: (val) => validatePass(
          val!,
          getTranslated(context, 'PWD_REQUIRED'),
          getTranslated(context, 'PWD_LENGTH'),
        ),
        onSaved: (String? value) {
          password = value;
        },
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: SvgPicture.asset(
              "assets/images/password.svg",
              height: 24,
              width: 24,
              color: Theme.of(context).colorScheme.fontColor,
            ),
          ),
          hintText: getTranslated(context, 'PASSHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 25),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),

          // 👇 Eye Icon Added Here
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword! ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).colorScheme.fontColor,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword!;
              });
            },
          ),
        ),
      ),
    );
  }

  setCities() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: GestureDetector(
            child: InputDecorator(
              decoration: InputDecoration(
                fillColor: Theme.of(context).colorScheme.surface,
                isDense: true,
                border: InputBorder.none,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslated(context, 'CITYSELECT_LBL') ??
                              'Select City',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          selCityPos != null && selCityPos != -1
                              ? cityList[selCityPos!].name ?? ""
                              : "Select a city",
                          style: TextStyle(
                            color: selCityPos != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
            onTap: () {
              cityDialog();
            },
          ),
        ),
      ),
    );
  }

  // cityDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setStater) {
  //           cityState = setStater;
  //           return AlertDialog(
  //             contentPadding: const EdgeInsets.all(0.0),
  //             // shape: RoundedRectangleBorder(
  //             //   borderRadius: BorderRadius.all(
  //             //     Radius.circular(5.0),
  //             //   ),
  //             // ),
  //             content: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Padding(
  //                   padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
  //                   child: Text(
  //                     getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
  //                     style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurface),
  //                   ),
  //                 ),
  //                 Divider(color: Theme.of(context).colorScheme.onSurface),
  //                 Flexible(
  //                   child: SingleChildScrollView(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: cityList.map((city) {
  //                         return InkWell(
  //                           onTap: () {
  //                             selCityPos = cityList.indexOf(city);
  //                             Navigator.pop(context);
  //                             setState(() {});
  //                           },
  //                           child: Container(
  //                             margin: EdgeInsets.symmetric(
  //                                 vertical: 5, horizontal: 10),
  //                             padding: EdgeInsets.all(10),
  //                             // decoration: BoxDecoration(
  //                             //   color: Colors.grey[200],
  //                             //   borderRadius: BorderRadius.circular(8),
  //                             //   boxShadow: [
  //                             //     BoxShadow(
  //                             //       color: Colors.grey.withOpacity(0.5),
  //                             //       spreadRadius: 1,
  //                             //       blurRadius: 3,
  //                             //       offset: Offset(0, 2),
  //                             //     ),
  //                             //   ],
  //                             // ),
  //                             child: Text(
  //                               city.name ?? '',
  //                               style: TextStyle(
  //                                   fontSize: 16, fontWeight: FontWeight.w500),
  //                             ),
  //                           ),
  //                         );
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  cityDialog() {
    // Start with full city list
    List filteredCities = List.from(cityList);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            cityState = setStater;

            void filterCities(String query) {
              query = query.trim().toLowerCase();
              filteredCities = cityList.where((city) {
                return (city.name ?? '').toLowerCase().contains(query);
              }).toList();
              setStater(() {});
            }

            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                    child: Text(
                      getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface),
                  // 🔍 Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: getTranslated(context, 'SEARCH_CITY') ??
                            'Search city',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: filterCities,
                    ),
                  ),
                  Flexible(
                    child: filteredCities.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                getTranslated(context, 'NO_CITY_FOUND') ??
                                    'No city found',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filteredCities.map((city) {
                                return InkWell(
                                  onTap: () {
                                    selCityPos = cityList.indexOf(city);
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      city.name ?? '',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  showPass() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          start: 30.0,
          end: 30.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Checkbox(
              value: _showPassword,
              checkColor: Theme.of(context).colorScheme.fontColor,
              activeColor: Theme.of(context).colorScheme.lightWhite,
              onChanged: (bool? value) {
                if (mounted)
                  setState(() {
                    _showPassword = value;
                  });
              },
            ),
            Text(getTranslated(context, 'SHOW_PASSWORD')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.normal))
          ],
        ));
  }

  verifyBtn() {
    return AppBtn(
      title: getTranslated(context, 'SAVE_LBL'),
      btnAnim: labelLargeSqueezeanimation,
      btnCntrl: labelLargeController,
      onBtnSelected: () async {
        validateAndSubmit();
      },
    );
  }

  loginTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 25.0,
        end: 25.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'ALREADY_A_CUSTOMER')!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
          InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => Login(),
                ));
              },
              child: Text(
                getTranslated(context, 'LOG_IN_LBL')!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  backBtn() {
    return Platform.isIOS
        ? Container(
            padding: EdgeInsetsDirectional.only(top: 20.0, start: 10.0),
            alignment: AlignmentDirectional.topStart,
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4.0),
                child: InkWell(
                  child: Icon(Icons.keyboard_arrow_left, color: colors.primary),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ))
        : Container();
  }

  Future<void> _fetchCities() async {
    const url =
        'https://developmentalphawizz.com/ruvanshi/app/v1/api/city'; // Replace with your API URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("Decoded Data: $data");

        bool error = data["error"];
        String? msg = data["message"];

        if (!error) {
          _cities = data.map((e) => CityListModel.fromJson(e)).toList();
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to load cities');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching cities: $error');
    }
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.initState();
    getCities();
    getUserDetails();
    labelLargeController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);

    labelLargeSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: labelLargeController!,
      curve: Interval(
        0.0,
        0.150,
      ),
    ));

    generateReferral();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: _isNetworkAvail
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/otp.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildLogo(),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              registerTxt(),
                              SizedBox(
                                height: 10,
                              ),
                              setUserName(),
                              setEmail(),
                              setPass(),
                              gender(),
                              setCities(),
                              verifyBtn(),
                              loginTxt(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            )
          : noInternet(context),
    );
  }

  Future<void> generateReferral() async {
    String refer = getRandomString(8);

    try {
      var data = {
        REFERCODE: refer,
      };

      Response response =
          await post(validateReferalApi, body: data, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];

      if (!error) {
        referCode = refer;
        REFER_CODE = refer;
        if (mounted) setState(() {});
      } else {
        if (count < 5) generateReferral();
        count++;
      }
    } on TimeoutException catch (_) {}
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Widget buildLogo() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/splashlogo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  gender() {
    return Column(
      children: [
        Row(
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
            ),
            Text("Male"),
            Radio(
                value: "male",
                groupValue: genderSelect,
                onChanged: (val) {
                  setState(() {
                    print(genderSelect);
                    genderSelect = val;
                  });
                }),
            Text("Female"),
            Radio(
                value: "female",
                groupValue: genderSelect,
                onChanged: (val) {
                  setState(() {
                    print(genderSelect);
                    genderSelect = val;
                  });
                })
          ],
        ),
      ],
    );
  }

  getDob() {
    DateTime date = selectedDate;
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined),
          Container(
            height: MediaQuery.of(context).size.height * 0.09,
            width: MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(color: Colors.white),
            child: ListTile(
              onTap: () {
                _selectDate(context);
              },
              title: Text("Select Date Of Birth"),
              subtitle: Text("${date.day}-${date.month}-${date.year}"),
            ),
          ),
        ],
      ),
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1970),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xffFF00FF), // header background color
                onPrimary: Colors.black, // header text color
                onSurface: Colors.black, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // labelLarge text color
                ),
              ),
            ),
            child: child!,
          );
        });
    if (selected != null && selected != selectedDate)
      setState(() {
        selectedDate = selected;
      });
  }

  final picker = ImagePicker();
  File? file;
  Future getImage() async {
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxHeight: 500,
        maxWidth: 500);
    setState(() {
      if (pickedFile != null) {
        file = File(pickedFile.path);
      } else {
        if (kDebugMode) {
          print('No image selected.');
        }
      }
    });
    setState(() {
      bankImg = file;
    });
    //  Navigator.pop(context);
  }
}
