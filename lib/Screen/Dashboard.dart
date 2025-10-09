import 'dart:async';
import 'dart:convert';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Helper/Constant.dart';
import 'package:TGSawadesiMartUser/Helper/Session.dart';
import 'package:TGSawadesiMartUser/Helper/String.dart';
import 'package:TGSawadesiMartUser/Model/Section_Model.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:TGSawadesiMartUser/Screen/Favorite.dart';
import 'package:TGSawadesiMartUser/Screen/Login.dart';
import 'package:TGSawadesiMartUser/Screen/MyProfile.dart';
import 'package:TGSawadesiMartUser/Screen/Product_Detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';

import 'package:provider/provider.dart';
import '../Helper/notification_service.dart';
import '../Provider/SettingProvider.dart';
import 'All_Category.dart';
import 'Cart.dart';
import 'HomePage.dart';
import 'NotificationLIst.dart';
import 'Offer.dart';
import 'Sale.dart';
import 'Search.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Dashboard> with TickerProviderStateMixin {
  int _selBottom = 0;
  late TabController _tabController;
  bool _isNetworkAvail = true;
  List<String> offerImgs = [];
  int currentIndex = 0;
  Timer? timer;

  @override
  void initState() {
    _setStatusBarColor();
    _getAppBar();
    dynamicGradient();
    getOfferGif();
    super.initState();
    getSetting();
    initDynamicLinks();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    LocalNotificationService.initialize();
    _tabController.addListener(
      () {
        Future.delayed(Duration(seconds: 0)).then(
          (value) {
            if (_tabController.index == 2) {
              if (CUR_USERID == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
                _tabController.animateTo(0);
              }
            }
          },
        );
        setState(
          () {
            _selBottom = _tabController.index;
          },
        );
      },
    );
  }

  void _setStatusBarColor() async {
    try {
      // Using flutter_statusbarcolor_ns for iPhone 14/15 compatibility
      await FlutterStatusbarcolor.setStatusBarColor(Colors.white);
      await FlutterStatusbarcolor.setStatusBarWhiteForeground(
          false); // Dark icons on white
      await FlutterStatusbarcolor.setNavigationBarColor(Colors.white);
      await FlutterStatusbarcolor.setNavigationBarWhiteForeground(false);

      // Also set SystemChrome as backup
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (e) {
      print("Error setting status bar color in HomePage: $e");
    }
  }

  void initDynamicLinks() async {}

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: id,
        };

        // if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;
        Response response =
            await post(getProductApi, headers: headers, body: parameter)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          List<Product> items = [];

          items =
              (data as List).map((data) => new Product.fromJson(data)).toList();

          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProductDetail(
                    index: list ? int.parse(id) : index,
                    model: list
                        ? items[0]
                        : sectionList[secPos].productList![index],
                    secPos: secPos,
                    list: list,
                  )));
        } else {
          if (msg != "Products Not Found !") setSnackbar(msg, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      }
    }
  }

  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
    _setStatusBarColor();
    return WillPopScope(
      onWillPop: () async {
        if (_tabController.index == 0) {
          final now = DateTime.now();
          if (lastPressed == null ||
              now.difference(lastPressed!) > Duration(seconds: 2)) {
            lastPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Press back again to exit",
                  style: TextStyle(fontFamily: dynamicFontFamily.fontFamily),
                ),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
          await SystemNavigator.pop();
          return true;
        } else {
          _tabController.animateTo(0);
          return false;
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: colors.grad1Color1,
          appBar: _getAppBar(),
          body: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              HomePage(
                callback: () {
                  getSetting();
                  getOfferGif();
                },
              ),
              AllCategory(),
              Cart(fromBottom: true),
              // Offer(
              //   fromSeller: false,
              //   tag: false,
              //   name: "Offer Section",
              // ),
            ],
          ),
          bottomNavigationBar: _getBottomBar(),
        ),
      ),
    );
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1)
      title = getTranslated(context, 'CATEGORY');
    else if (_selBottom == 2) title = getTranslated(context, 'CART');
    // else if (_selBottom == 3) title = getTranslated(context, 'PROFILE');

    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      leadingWidth: 200,
      centerTitle: false,
      title: _selBottom == 0
          ? (appLogo != null && appLogo!.isNotEmpty
              ? Image.network(
                  appLogo!,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/images/applogo.png', height: 40),
                )
              : Image.asset(
                  'assets/images/applogo.png',
                  height: 40,
                ))
          : Text(
              title ?? "",
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.normal,
              ),
            ),

      // title: _selBottom == 0
      //     ? Image.asset(
      //         'assets/images/applogo.png',
      //         height: 40,
      //       )
      //     : Text(
      //         title ?? "",
      //         style: TextStyle(
      //           color: secondaryColor,
      //           fontWeight: FontWeight.normal,
      //         ),
      //       ),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            imagePath + "search.svg",
            height: 22,
            color: secondaryColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Search()),
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(imagePath + "desel_notification.svg",
              height: 22, color: secondaryColor),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationList()),
                  )
                : Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(imagePath + "desel_fav.svg",
              height: 22, color: secondaryColor),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Favorite()),
                  )
                : Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.account_circle,
            size: 28,
            color: secondaryColor,
          ),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfile()),
                  )
                : Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: dynamicGradient(),
      ),
    );
  }

  Widget _getBottomBar() {
    return Material(
      color: colors.whiteTemp,
      child: Container(
        decoration: BoxDecoration(
          color: colors.whiteTemp,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.black26,
              blurRadius: 10,
            ),
          ],
        ),
        child: TabBar(
          onTap: (_) {
            if (_tabController.index == 3) {
              if (CUR_USERID == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
                _tabController.animateTo(0);
              }
            }
          },
          controller: _tabController,
          tabs: [
            Tab(
              icon: SvgPicture.asset(
                _selBottom == 0
                    ? imagePath + "sel_home.svg"
                    : imagePath + "desel_home.svg",
                color: _selBottom == 0 ? secondaryColor : colors.blackTemp,
                width: 28,
                height: 28,
              ),
              text: getTranslated(context, 'HOME_LBL'),
            ),
            Tab(
              icon: SvgPicture.asset(
                _selBottom == 1
                    ? imagePath + "category01.svg"
                    : imagePath + "category.svg",
                color: _selBottom == 1 ? secondaryColor : colors.blackTemp,
                width: 26,
                height: 26,
              ),
              text: getTranslated(context, 'category'),
            ),
            Tab(
              icon: Selector<UserProvider, String>(
                builder: (context, data, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          _selBottom == 2
                              ? imagePath + "cart01.svg"
                              : imagePath + "cart.svg",
                          color: _selBottom == 2
                              ? secondaryColor
                              : colors.blackTemp,
                          width: 26,
                          height: 26,
                        ),
                      ),
                      if (data != null && data.isNotEmpty && data != "0")
                        Align(
                          alignment: Alignment.topRight,
                          child: Transform.translate(
                            offset: Offset(20, -7),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selBottom == 2
                                    ? secondaryColor
                                    : colors.blackTemp,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.white,
                                  width: 1,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  data,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                selector: (_, homeProvider) => homeProvider.curCartCount,
              ),
              text: getTranslated(context, 'CART'),
            ),
            // Tab(
            //   icon: SizedBox(
            //     width: 100,
            //     height: 100,
            //     child: offerImgs.isNotEmpty
            //         ? ClipRRect(
            //             borderRadius: BorderRadius.circular(100),
            //             child: Container(
            //               width: 120,
            //               height: 120,
            //               child: AnimatedSwitcher(
            //                 duration: const Duration(milliseconds: 800),
            //                 transitionBuilder: (child, animation) =>
            //                     FadeTransition(
            //                   opacity: animation,
            //                   child: child,
            //                 ),
            //                 child: CachedNetworkImage(
            //                   key: ValueKey<String>(offerImgs[currentIndex]),
            //                   imageUrl: offerImgs[currentIndex],
            //                   fit: BoxFit.cover,
            //                   placeholder: (context, url) => Center(
            //                     child: CircularProgressIndicator(
            //                       strokeWidth: 2,
            //                       valueColor: AlwaysStoppedAnimation<Color>(
            //                         Colors.green,
            //                       ),
            //                     ),
            //                   ),
            //                   errorWidget: (context, url, error) => Container(
            //                     color: Colors.grey[200],
            //                     child: Icon(
            //                       Icons.image_not_supported,
            //                       color: Colors.grey[400],
            //                       size: 30,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           )
            //         : Image.asset(
            //             "assets/images/offer.gif",
            //             fit: BoxFit.cover,
            //           ),
            //   ),
            // ),
          ],
          indicator: UnderlineTabIndicator(
            insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 70.0),
          ),
          labelColor: secondaryColor,
          unselectedLabelColor: colors.blackTemp,
          labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
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

        dynamicColor.buttonColor = secondaryColor;
        dynamicColor.buttonTxtColor = textColor;
        dynamicColor.appBarBgColor = primaryColor;
        dynamicFontFamily.fontFamily = "Poppins";

        print("Primary: $primaryColor");
        print("Secondary: $secondaryColor");
        print("Background: $backgroundColor");
        print("Text: $textColor");
        print("App Logo: $appLogo");

        if (mounted) setState(() {});
      }
    }, onError: (error) {
      print("API Error: $error");
    });
  }

  void startImageLoop() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      if (offerImgs.isNotEmpty) {
        setState(() {
          currentIndex = (currentIndex + 1) % offerImgs.length;
        });
      }
    });
  }

  void getOfferGif() {
    CUR_USERID = context.read<SettingProvider>().userId;
    Map<String, dynamic> parameter = {};
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

    apiBaseHelper.postAPICall(getOfferApi, parameter).then((getdata) async {
      bool error = getdata["error"];
      if (!error) {
        var data = getdata["gif_urls"];
        print("jhgjkfbss $data");

        if (data != null) {
          if (data.length > 0) {
            setState(() {
              offerImgs = List<String>.from(data);
              currentIndex = 0;
            });
            startImageLoop();
          }
        }
        // if (mounted) setState(() {});
      }
    }, onError: (error) {
      print("API Error: $error");
    });
  }

  //
  // String? PRIMARY = '';
  // String? SECONDARY = '';
  // String PRIMARY_COLOR = 'primary';
  // String SECONDARY_COLOR = 'secondary';
  //
  // void getSetting() {
  //   CUR_USERID = context.read<SettingProvider>().userId;
  //   Map<String, dynamic> parameter = {};
  //   if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};
  //
  //   apiBaseHelper.postAPICall(getThemeApi, parameter).then((getdata) async {
  //     bool error = getdata["error"];
  //     if (!error) {
  //       var colors = getdata["data"]["colors"];
  //
  //       String? primaryHex = colors[PRIMARY_COLOR]?.toString();
  //       String? secondaryHex = colors[SECONDARY_COLOR]?.toString();
  //
  //       if (primaryHex != null && primaryHex.isNotEmpty) {
  //         primaryColor = Color(int.parse("0xFF$primaryHex"));
  //       }
  //       if (secondaryHex != null && secondaryHex.isNotEmpty) {
  //         secondaryColor = Color(int.parse("0xFF$secondaryHex"));
  //       }
  //       print("Primary: $primaryColor, Secondary: $secondaryColor");
  //       // updateAppColors(primaryColor, secondaryColor);
  //       if (mounted) setState(() {});
  //     }
  //   }, onError: (error) {
  //     print("API Error: $error");
  //   });
  // }

  @override
  void dispose() {
    _tabController.dispose();
    timer?.cancel();
    super.dispose();
  }
}
