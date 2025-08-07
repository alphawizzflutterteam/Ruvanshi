import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/cropped_container.dart';
import '../Provider/SettingProvider.dart';
import '../Provider/UserProvider.dart';
import 'Set_Password.dart';
import 'SignUp.dart';

class VerifyOtp extends StatefulWidget {
  final String? mobileNumber, countryCode, title;
  final otp;
  VerifyOtp(
      {Key? key,
      required String this.mobileNumber,
      this.countryCode,
      this.title,
      this.otp})
      : assert(mobileNumber != null),
        super(key: key);

  @override
  _MobileOTPState createState() => _MobileOTPState();
}

class _MobileOTPState extends State<VerifyOtp> with TickerProviderStateMixin {
  final dataKey = GlobalKey();
  String? password;
  String? otp;
  bool isCodeSent = false;
  late String _verificationId;
  String signature = "";
  bool _isClickable = false;
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Animation? labelLargeSqueezeanimation;
  AnimationController? labelLargeController;

  @override
  void initState() {
    print("==logintitle============${widget.title}===========");
    otppp = widget.otp.toString();
    super.initState();
    getUserDetails();
    getSingature();
    // _onVerifyCode();
    Future.delayed(Duration(seconds: 60)).then((_) {
      _isClickable = true;
    });
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
  }

  Future<void> getVerifyUser() async {
    try {
      var data = {MOBILE: widget.mobileNumber, "forgot_otp": "false"};
      Response response =
          await post(getVerifyUserApi, body: data, headers: headers)
              .timeout(Duration(seconds: timeOut));
      print(getVerifyUserApi.toString());
      print(data.toString());
      print("Response Body: ${response.body}");

      var getdata = json.decode(response.body);
      print('PrintData:_____${getdata["data"]["otp"]}______');
      bool? error = getdata["error"];
      String? msg = getdata["message"];
      await labelLargeController!.reverse();

      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
        if (!error!) {
          int otp = getdata["data"]["otp"];

          Fluttertoast.showToast(
              msg: otp.toString(), backgroundColor: colors.primary);
          Future.delayed(Duration(seconds: 1)).then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtp(
                  otp: otp,
                  mobileNumber: widget.mobileNumber!,
                  countryCode: widget.countryCode,
                  title: getTranslated(context, 'SEND_OTP_TITLE'),
                ),
              ),
            );
          });
        } else {
          setSnackbar(msg!);
        }
      } else {
        if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
          if (!error!) {
            int otp = getdata["data"]["otp"];

            Fluttertoast.showToast(
                msg: otp.toString(), backgroundColor: colors.primary);
            Future.delayed(Duration(seconds: 1)).then((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifyOtp(
                    otp: otp,
                    mobileNumber: widget.mobileNumber!,
                    countryCode: widget.countryCode,
                    title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                  ),
                ),
              );
            });
          } else {
            setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!);
          }
        }
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await labelLargeController!.reverse();
    }
  }

  Future<void> getSingature() async {
    signature = await SmsAutoFill().getAppSignature;
    await SmsAutoFill().listenForCode;
  }

  getUserDetails() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    if (mounted) setState(() {});
  }

  Future<void> checkNetworkOtp() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      if (_isClickable) {
        // _onVerifyCode();

        if (widget.title == "isloging") {
          resendinLogin();
        } else {
          getVerifyUser();
        }

        // otpCheck();
      } else {
        setSnackbar(getTranslated(context, 'OTPWR')!);
      }
    } else {
      if (mounted) setState(() {});

      Future.delayed(Duration(seconds: 60)).then((_) async {
        bool avail = await isNetworkAvailable();
        if (avail) {
          if (_isClickable)
            // _onVerifyCode();
            //  otpCheck();
            getVerifyUser();
          else {
            setSnackbar(getTranslated(context, 'OTPWR')!);
          }
        } else {
          await labelLargeController!.reverse();
          setSnackbar(getTranslated(context, 'somethingMSg')!);
        }
      });
    }
  }

  Widget verifyBtn() {
    return AppBtn(
        title: getTranslated(context, 'VERIFY_AND_PROCEED'),
        btnAnim: labelLargeSqueezeanimation,
        btnCntrl: labelLargeController,
        onBtnSelected: () async {
          _onFormSubmitted();
          otpCheck();
        });
  }

  void setSnackbar(String msg) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Positioned(
          bottom: bottomInset + 400,
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

    // Auto hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  otpCheck() async {
    _playAnimation();

    if (otp.toString().isEmpty) {
      await labelLargeController!.reverse();
      setSnackbar('Please Fill OTP Field');
      return;
    }

    if (otppp.toString() == otp.toString()) {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      Fluttertoast.showToast(
          msg: getTranslated(context, 'OTPMSG')!,
          backgroundColor: colors.primary);
      settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
      settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
      await labelLargeController!.reverse();

      if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SignUp()));
        });
      } else if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SetPass(mobileNumber: widget.mobileNumber!)));
        });
      } else if (widget.title == "isloging") {
        Future.delayed(Duration(seconds: 2)).then((_) {
          verifyotpforLogin();
        });
      }
    } else {
      await labelLargeController!.reverse();
      setSnackbar('Wrong OTP');
    }
  }

  void _onVerifyCode() async {
    if (mounted)
      setState(() {
        isCodeSent = true;
      });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        if (value.user != null) {
          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);

          setSnackbar(getTranslated(context, 'OTPMSG')!);
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => SignUp()));
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SetPass(mobileNumber: widget.mobileNumber!)));
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!);
        }
      }).catchError((error) {
        setSnackbar("OTP is not correct");
        setSnackbar(error.toString());
      });
    };
    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      setSnackbar("OTP is not correct");

      if (mounted)
        setState(() {
          isCodeSent = false;
        });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      _verificationId = verificationId;
      if (mounted)
        setState(() {
          _verificationId = verificationId;
        });
    };
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      if (mounted)
        setState(() {
          _isClickable = true;
          _verificationId = verificationId;
        });
    };

    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+${widget.countryCode}${widget.mobileNumber}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void _onFormSubmitted() async {
    String code = otp!.trim();

    if (code.length == 6) {
      _playAnimation();
      AuthCredential _authCredential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: code);

      _firebaseAuth
          .signInWithCredential(_authCredential)
          .then((UserCredential value) async {
        if (value.user != null) {
          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);

          await labelLargeController!.reverse();
          setSnackbar(getTranslated(context, 'OTPMSG')!);
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => SignUp()));
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SetPass(mobileNumber: widget.mobileNumber!)));
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!);
          await labelLargeController!.reverse();
        }
      }).catchError((error) async {
        setSnackbar(getTranslated(context, 'WRONGOTP')!);

        await labelLargeController!.reverse();
      });
    } else {
      // setSnackbar(getTranslated(context, 'ENTEROTP')!);
    }
  }

  Future<Null> _playAnimation() async {
    try {
      await labelLargeController!.forward();
    } on TickerCanceled {}
  }

  getImage() {
    return Expanded(
      flex: 4,
      child: Center(
        child: Image.asset('assets/images/homelogo.png'),
      ),
    );
  }

  @override
  void dispose() {
    labelLargeController!.dispose();
    super.dispose();
  }

  monoVarifyText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 20.0,
        ),
        child: Center(
          child: Text(getTranslated(context, 'MOBILE_NUMBER_VARIFICATION')!,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 25)),
        ));
  }

  verifyText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 30.0, start: 20.0, end: 20.0),
        child: Center(
          child: Text(getTranslated(context, 'SENT_VERIFY_CODE_TO_NO_LBL')!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
        ));
  }

  mobText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 10.0, start: 20.0, end: 20.0, top: 10.0),
      child: Center(
        child: Text("+${widget.countryCode}-${widget.mobileNumber}",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal)),
      ),
    );
  }

  OTPText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 10.0, start: 20.0, end: 20.0, top: 10.0),
      child: Center(
        child: Text("OTP: ${otppp}",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal)),
      ),
    );
  }

  Widget otpLayout() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          start: 50.0,
          end: 50.0,
        ),
        child: Center(
            child: PinFieldAutoFill(
                decoration: UnderlineDecoration(
                  textStyle: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.fontColor),
                  colorBuilder: FixedColorBuilder(colors.primary),
                ),
                currentCode: otp,
                codeLength: 4,
                onCodeChanged: (String? code) {
                  otp = code;
                },
                onCodeSubmitted: (String code) {
                  otp = code;
                  otppp = otp;
                })));
  }

  Widget resendText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 30.0, start: 25.0, end: 25.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getTranslated(context, 'DIDNT_GET_THE_CODE')!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal),
          ),
          InkWell(
            onTap: () async {
              await labelLargeController!.reverse();
              checkNetworkOtp();
            },
            child: Text(
              getTranslated(context, 'RESEND_OTP')!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.gray,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.normal),
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
                              Padding(
                                padding: EdgeInsets.only(top: 30, left: 10),
                                child: Center(
                                  child: Text(
                                    'OTP',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              monoVarifyText(),
                              verifyText(),
                              mobText(),
                              OTPText(),
                              otpLayout(),
                              verifyBtn(),
                              resendText(),
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

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight),
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

  Future<void> resendinLogin() async {
    var headers = {
      'Cookie': 'ci_session=2b2689736ef1a69d40f8e9ac7a769ff71c28e529'
    };
    var request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}login_with_otp'));
    request.fields.addAll({'mobile': "${widget.mobileNumber.toString()}"});
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    print(request.url);
    print(request.fields);
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      print(result);
      var finalresult = jsonDecode(result);
      String msg = finalresult['message'];
      if (finalresult['error'] == false) {
        setSnackbar(msg);

        otppp = finalresult['otp'].toString();

        setState(() {});
      } else {}
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> verifyotpforLogin() async {
    await labelLargeController!.forward();
    var headers = {
      'Cookie': 'ci_session=c32369b36aac3982f15636a4d733087d06d9a11d'
    };
    var request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}otp_verify'));
    request.fields.addAll({
      'mobile': widget.mobileNumber.toString(),
      'otp': otp.toString(),
    });
    print('PrintData:_____${request.fields}______');

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    print(request.url);
    print(request.fields);
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      print(result);
      var finalresult = jsonDecode(result);
      String msg = finalresult['message'];
      if (finalresult['error'] == false) {
        id = finalresult['user'][0][ID];
        username = finalresult['user'][0][USERNAME];
        email = finalresult['user'][0][EMAIL];
        mobile = finalresult['user'][0][MOBILE];
        city = finalresult['user'][0][CITY];
        area = finalresult['user'][0][AREA];
        address = finalresult['user'][0][ADDRESS];
        pincode = finalresult['user'][0][PINCODE];
        latitude = finalresult['user'][0][LATITUDE];
        longitude = finalresult['user'][0][LONGITUDE];
        image = finalresult['user'][0][IMAGE];

        CUR_USERID = id;
        // CUR_USERNAME = username;

        UserProvider userProvider =
            Provider.of<UserProvider>(this.context, listen: false);
        userProvider.setName(username ?? "");
        userProvider.setEmail(email ?? "");
        userProvider.setProfilePic(image ?? "");

        SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);

        settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
            address, pincode, latitude, longitude, image, "", city, context);
        await labelLargeController!.reverse();
        setSnackbar(msg);
        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      } else {
        await labelLargeController!.reverse();

        setSnackbar(msg);
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  String? mobile,
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

  var otppp;
}
