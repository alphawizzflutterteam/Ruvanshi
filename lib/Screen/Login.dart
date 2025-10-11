import 'dart:async';
import 'dart:convert';
import 'package:TGSawadesiMartUser/Helper/String.dart';
import 'package:TGSawadesiMartUser/Helper/cropped_container.dart';
import 'package:TGSawadesiMartUser/Provider/SettingProvider.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:TGSawadesiMartUser/Screen/SendOtp.dart';
import 'package:TGSawadesiMartUser/Screen/SignUp.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Public Api/api.dart';
import '../Helper/Session.dart';
import 'HomePage.dart';
import 'Verify_Otp.dart';

class Login extends StatefulWidget {
  final String? countryCode;

  Login({
    Key? key,
    this.countryCode,
  }) : super(key: key);

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? countrycode;

  String? countryName;
  FocusNode? passFocus, monoFocus = FocusNode(), emailFocus = FocusNode();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool visible = false;
  bool _showPassword = false;
  bool isnumberLogin = true;

  String? password,
      mobile,
      username,
      email,
      id,
      mobileno,
      city,
      area,
      pincode,
      address,
      latitude,
      longitude,
      image;
  bool _isNetworkAvail = true;
  String? fcmToken;
  Animation? labelLargeSqueezeanimation;
  AnimationController? labelLargeController;

  getToken() {
    FirebaseMessaging.instance.getToken().then((value) {
      fcmToken = value!;
    });
    print("fcm is ${fcmToken}");
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
    getToken();
    getSetting();
    labelLargeController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    labelLargeSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: labelLargeController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  void getSetting() {
    CUR_USERID = context.read<SettingProvider>().userId;
    Map<String, dynamic> parameter = {};
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

    apiBaseHelper.postAPICall(getThemeApi, parameter).then((getdata) async {
      bool error = getdata["error"];
      if (!error) {
        var data = getdata["data"];
        print("jhgjkfb $data");

        var colorValue = data["colors"];
        String? primaryHex = colorValue[PRIMARY_COLOR]?.toString();
        String? secondaryHex = colorValue[SECONDARY_COLOR]?.toString();
        String? backgroundHex = colorValue[BACKGROUND_COLOR]?.toString();
        String? textHex = colorValue[TEXT_COLOR]?.toString();

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

        String? authLoginPath = data["login_page_image"]?.toString();
        if (authLoginPath != null && authLoginPath.isNotEmpty) {
          dynamicAuthImages.loginBg = BASE_URL + authLoginPath;
        }

        String? authRegisterPath = data["signup_page_image"]?.toString();
        if (authRegisterPath != null && authRegisterPath.isNotEmpty) {
          dynamicAuthImages.registerBg = BASE_URL + authRegisterPath;
        }

        dynamicColor.buttonColor = secondaryColor;
        dynamicColor.buttonTxtColor = textColor;
        dynamicColor.appBarBgColor = primaryColor;
        dynamicFontFamily.fontFamily = "Poppins";

        dynamicAppLogo.appLogo = appLogo!;

        print("App Logo: $appLogo");

        if (mounted) setState(() {});
      }
    }, onError: (error) {
      print("API Error: $error");
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    labelLargeController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await labelLargeController!.forward();
    } on TickerCanceled {}
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getLoginUser();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        await labelLargeController!.reverse();
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
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

  void setSnackbar(String msg) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Positioned(
          top: 100,
          left: 24,
          right: 24,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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

  Future<void> getLoginUser() async {
    Map<String, dynamic> data;
    if (isnumberLogin) {
      data = {
        MOBILE: mobile,
        "fcm_id": fcmToken,
      };
    } else {
      data = {
        EMAIL: email,
        PASSWORD: password ?? "",
        "fcm_id": fcmToken,
      };
    }
    print('loginjfjlbls:_____${data}______');
    try {
      Response response = await post(
        getUserLoginApi,
        body: data,
        headers: headers,
      ).timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      bool error = getdata["error"];
      String? msg = getdata["message"];

      await labelLargeController!.reverse();

      if (!error) {
        setSnackbar(msg ?? "");

        var i = getdata["data"][0];
        id = i[ID];
        username = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        city = i[CITY];
        area = i[AREA];
        address = i[ADDRESS];
        pincode = i[PINCODE];
        latitude = i[LATITUDE];
        longitude = i[LONGITUDE];
        image = i[IMAGE];
        CUR_USERID = id;
        int? otp = getdata["otp"];
        UserProvider userProvider =
            Provider.of<UserProvider>(context, listen: false);
        userProvider.setName(username ?? "");
        userProvider.setEmail(email ?? "");
        userProvider.setProfilePic(image ?? "");

        SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);
        // settingsProvider.setPrefrence(COUNTRY_CODE, countrycode!);

        settingProvider.saveUserDetail(
          id!,
          username,
          email,
          mobile,
          city,
          area,
          address,
          pincode,
          latitude,
          longitude,
          image,
          city,
          '',
          context,
        );

        if (isnumberLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtp(
                otp: otp,
                mobileNumber: mobileController.text,
                countryCode: widget.countryCode,
                title: 'login',
              ),
            ),
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      } else {
        setSnackbar(msg ?? "Something went wrong!");
      }
    } catch (e) {
      print("Login error: $e");
      setSnackbar("Login failed. Please try again.");
    }
  }

  Widget buildLogo() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          dynamicAppLogo.appLogo.isNotEmpty
              ? Container(
                  width: 200,
                  height: 120,
                  child: CachedNetworkImage(
                    imageUrl: dynamicAppLogo.appLogo,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    ),
                  ),
                )
              : Container(
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

  Widget buildLoginToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isnumberLogin = true;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: isnumberLogin,
                  onChanged: (value) {
                    setState(() {
                      isnumberLogin = value!;
                    });
                  },
                  activeColor: dynamicColor.appBarBgColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                isnumberLogin = false;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: isnumberLogin,
                  onChanged: (value) {
                    setState(() {
                      isnumberLogin = value!;
                    });
                  },
                  activeColor: dynamicColor.appBarBgColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmailField() {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: emailController,
        focusNode: emailFocus,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Email is required';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
            return 'Please enter a valid email';
          }
          return null;
        },
        onSaved: (String? value) {
          email = value;
        },
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Email ID',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.grey[600],
            size: 22,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildMobileField() {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        maxLength: 10,
        controller: mobileController,
        focusNode: monoFocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onSaved: (String? value) {
          mobile = value;
        },
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Mobile Number',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.phone_android,
            color: Colors.grey[600],
            size: 22,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: passwordController,
        focusNode: passFocus,
        obscureText: !_showPassword,
        textInputAction: TextInputAction.done,
        validator: (val) => validatePass(
          val!,
          getTranslated(context, 'PWD_REQUIRED'),
          getTranslated(context, 'PWD_LENGTH'),
        ),
        onSaved: (String? value) {
          password = value;
        },
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey[600],
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildForgotPassword() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(this.context, listen: false);

          settingsProvider.setPrefrence(ID, id ?? '');
          settingsProvider.setPrefrence(MOBILE,
              isnumberLogin ? mobileController.text : emailController.text);

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SendOtp(
                        checkForgot: 'true',
                        title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                      )));
        },
        child: Text(
          'Forget Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildSignInButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          validateAndSubmit();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: dynamicColor.buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          'Sign In',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: dynamicColor.buttonTxtColor),
        ),
      ),
    );
  }

  Widget buildSignUpLink() {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => SendOtp(
                  checkForgot: "false",
                  title: getTranslated(context, 'SEND_OTP_TITLE'),
                ),
              ));
            },
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: dynamicColor.appBarBgColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
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
                  image: dynamicAuthImages.loginBg.isNotEmpty
                      ? CachedNetworkImageProvider(dynamicAuthImages.loginBg)
                          as ImageProvider
                      : const AssetImage('assets/images/backgroundimage.png')
                          as ImageProvider,
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
                              Padding(
                                padding: EdgeInsets.only(top: 30, left: 20),
                                child: Center(
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ),
                              buildLoginToggle(),
                              isnumberLogin
                                  ? Column(
                                      children: [
                                        buildMobileField(),
                                        // buildOtpButton(),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        buildEmailField(),
                                        buildPasswordField(),
                                      ],
                                    ),
                              buildForgotPassword(),
                              buildSignInButton(),
                              buildSignUpLink(),
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
}
