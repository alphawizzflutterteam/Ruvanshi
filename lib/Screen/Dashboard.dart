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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../Helper/notification_service.dart';
import 'All_Category.dart';
import 'Cart.dart';
import 'HomePage.dart';
import 'NotificationLIst.dart';
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

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.initState();
    initDynamicLinks();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    LocalNotificationService.initialize();

    // final pushNotificationService = PushNotificationService(
    //     context: context, tabController: _tabController);
    // pushNotificationService.initialise();

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

  void initDynamicLinks() async {
    /* FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.length > 0) {
          int index = int.parse(deepLink.queryParameters['index']!);

          int secPos = int.parse(deepLink.queryParameters['secPos']!);

          String? id = deepLink.queryParameters['id'];

          String? list = deepLink.queryParameters['list'];

          getProduct(id!, index, secPos, list == "true" ? true : false);
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.queryParameters.length > 0) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        // String list = deepLink.queryParameters['list'];

        getProduct(id!, index, secPos, true);
      }
    }*/
  }

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
    return WillPopScope(
      onWillPop: () async {
        if (_tabController.index == 0) {
          final now = DateTime.now();
          if (lastPressed == null ||
              now.difference(lastPressed!) > Duration(seconds: 2)) {
            lastPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Press back again to exit"),
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
          // backgroundColor: Theme.of(context).colorScheme.lightWhite,
          appBar: _getAppBar(),
          body: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              HomePage(),
              AllCategory(),
              Cart(fromBottom: true),
              // MyProfile(),
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
    else if (_selBottom == 2) title = getTranslated(context, 'MYBAG');
    // else if (_selBottom == 3) title = getTranslated(context, 'PROFILE');

    return AppBar(
      elevation: 0.0,
      backgroundColor: colors.white70,
      leadingWidth: 200,
      centerTitle: false,
      title: _selBottom == 0
          ? Image.asset(
              'assets/images/applogo.png',
              height: 40,
            )
          : Text(
              title ?? "",
              style: const TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.normal,
              ),
            ),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            imagePath + "search.svg",
            height: 22,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Search()),
            );
          },
        ),
        // IconButton(
        //   icon: SvgPicture.asset(
        //     imagePath + "desel_fav.svg",
        //     height: 22,
        //     color: Colors.red,
        //   ),
        //   onPressed: () {
        //     CUR_USERID != null
        //         ? Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => Favorite()),
        //           )
        //         : Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => Login()),
        //           );
        //   },
        // ),
        IconButton(
          icon: SvgPicture.asset(
            imagePath + "desel_notification.svg",
            height: 22,
            color: Colors.black,
          ),
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
          icon: SvgPicture.asset(
            imagePath + "desel_fav.svg",
            height: 22,
            color: Colors.red,
          ),
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
        // IconButton(
        //   icon: SvgPicture.asset(
        //     imagePath + "search.svg",
        //     height: 22,
        //     color: Colors.black,
        //   ),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => Search()),
        //     );
        //   },
        // ),
        IconButton(
          icon: const Icon(
            Icons.account_circle,
            size: 28,
            color: Colors.black,
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
    );
  }

  // Widget _getBottomBar() {
  //   return Material(
  //     color: Theme.of(context).colorScheme.white,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.white,
  //         boxShadow: [
  //           BoxShadow(
  //             color: Theme.of(context).colorScheme.black26,
  //             blurRadius: 10,
  //           ),
  //         ],
  //       ),
  //       child: TabBar(
  //         onTap: (_) {
  //           if (_tabController.index == 3) {
  //             if (CUR_USERID == null) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => Login(),
  //                 ),
  //               );
  //               _tabController.animateTo(0);
  //             }
  //           }
  //         },
  //         controller: _tabController,
  //         tabs: [
  //           Tab(
  //             icon: SvgPicture.asset(
  //               _selBottom == 0
  //                   ? imagePath + "sel_home.svg"
  //                   : imagePath + "desel_home.svg",
  //               color: _selBottom == 0 ? colors.secondary : Colors.black,
  //             ),
  //             text: getTranslated(context, 'HOME_LBL'),
  //           ),
  //           Tab(
  //             icon: SvgPicture.asset(
  //               _selBottom == 1
  //                   ? imagePath + "category01.svg"
  //                   : imagePath + "category.svg",
  //               color: _selBottom == 1 ? colors.secondary : Colors.black,
  //             ),
  //             text: getTranslated(context, 'category'),
  //           ),
  //           // Tab(
  //           //   icon: SvgPicture.asset(
  //           //     _selBottom == 2
  //           //         ? imagePath + "sale02.svg"
  //           //         : imagePath + "sale.svg",
  //           //     color: _selBottom == 2 ? colors.secondary : Colors.black,
  //           //   ),
  //           //   text: getTranslated(context, 'SALE'),
  //           // ),
  //           // Tab(
  //           //   icon: Selector<UserProvider, String>(
  //           //     builder: (context, data, child) {
  //           //       print('bjhgjghjkg:_____${data}______');
  //           //       return Stack(
  //           //         children: [
  //           //           Center(
  //           //             child: SvgPicture.asset(
  //           //               _selBottom == 2
  //           //                   ? imagePath + "cart01.svg"
  //           //                   : imagePath + "cart.svg",
  //           //               color:
  //           //                   _selBottom == 2 ? colors.secondary : Colors.black,
  //           //             ),
  //           //           ),
  //           //           if (data != null && data.isNotEmpty && data != "0")
  //           //             Positioned.directional(
  //           //               // bottom: _selBottom == 2 ? 6 : 20,
  //           //               textDirection: Directionality.of(context),
  //           //               end: 0,
  //           //               child: Container(
  //           //                 decoration: BoxDecoration(
  //           //                   shape: BoxShape.circle,
  //           //                   color: colors.primary,
  //           //                 ),
  //           //                 child: Center(
  //           //                   child: Padding(
  //           //                     padding: EdgeInsets.all(3),
  //           //                     child: Text(
  //           //                       data,
  //           //                       style: TextStyle(
  //           //                         fontSize: 7,
  //           //                         fontWeight: FontWeight.bold,
  //           //                         color: Theme.of(context).colorScheme.white,
  //           //                       ),
  //           //                     ),
  //           //                   ),
  //           //                 ),
  //           //               ),
  //           //             ),
  //           //         ],
  //           //       );
  //           //     },
  //           //     selector: (_, homeProvider) => homeProvider.curCartCount,
  //           //   ),
  //           //   text: getTranslated(context, 'CART'),
  //           // ),
  //           Tab(
  //             icon: Selector<UserProvider, String>(
  //               builder: (context, data, child) {
  //                 print('bjhgjghjkg:_____${data}______');
  //                 return Stack(
  //                   children: [
  //                     Center(
  //                       child: SvgPicture.asset(
  //                         _selBottom == 2
  //                             ? imagePath + "cart01.svg"
  //                             : imagePath + "cart.svg",
  //                         color:
  //                             _selBottom == 2 ? colors.secondary : Colors.black,
  //                         width: 24, // Fixed width for consistent positioning
  //                         height: 24, // Fixed height for consistent positioning
  //                       ),
  //                     ),
  //                     if (data != null && data.isNotEmpty && data != "0")
  //                       Positioned(
  //                         top: -2, // Position from top
  //                         right: -2, // Position from right
  //                         child: Container(
  //                           constraints: BoxConstraints(
  //                             minWidth: 18, // Minimum width for the badge
  //                             minHeight: 18, // Minimum height for the badge
  //                           ),
  //                           decoration: BoxDecoration(
  //                             shape: BoxShape.circle,
  //                             color: colors.primary,
  //                             border: Border.all(
  //                               color: Theme.of(context).colorScheme.white,
  //                               width: 1,
  //                             ),
  //                           ),
  //                           child: Center(
  //                             child: Padding(
  //                               padding: EdgeInsets.symmetric(
  //                                   horizontal: 4, vertical: 2),
  //                               child: Text(
  //                                 data,
  //                                 style: TextStyle(
  //                                   fontSize: 11, // Increased from 7 to 11
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Theme.of(context).colorScheme.white,
  //                                 ),
  //                                 textAlign: TextAlign.center,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                   ],
  //                 );
  //               },
  //               selector: (_, homeProvider) => homeProvider.curCartCount,
  //             ),
  //             text: getTranslated(context, 'CART'),
  //           ), // Tab(
  //           //   icon: SvgPicture.asset(
  //           //     _selBottom == 3
  //           //         ? imagePath + "profile01.svg"
  //           //         : imagePath + "profile.svg",
  //           //     color: _selBottom == 3 ? colors.secondary : Colors.black,
  //           //   ),
  //           //   text: getTranslated(context, 'ACCOUNT'),
  //           // ),
  //         ],
  //         indicator: UnderlineTabIndicator(
  //           // borderSide: BorderSide(color: colors.lightWhite2, width: 5.0),
  //           insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 70.0),
  //         ),
  //         labelColor: colors.secondary,
  //         unselectedLabelColor: Colors.black,
  //         labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
  //         unselectedLabelStyle:
  //             TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //   );
  // }
  Widget _getBottomBar() {
    return Material(
      color: colors.white70,
      // color: Theme.of(context).colorScheme.white,
      child: Container(
        decoration: BoxDecoration(
          color: colors.white70,
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
                color: _selBottom == 0 ? colors.secondary : Colors.black,
                width: 24,
                height: 24,
              ),
              text: getTranslated(context, 'HOME_LBL'),
            ),
            Tab(
              icon: SvgPicture.asset(
                _selBottom == 1
                    ? imagePath + "category01.svg"
                    : imagePath + "category.svg",
                color: _selBottom == 1 ? colors.secondary : Colors.black,
                width: 20,
                height: 20,
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
                          color:
                              _selBottom == 2 ? colors.secondary : Colors.black,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      if (data != null && data.isNotEmpty && data != "0")
                        Align(
                          alignment: Alignment.topRight,
                          child: Transform.translate(
                            offset: Offset(25, -7),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
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
          ],
          indicator: UnderlineTabIndicator(
            insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 70.0),
          ),
          labelColor: colors.secondary,
          unselectedLabelColor: Colors.black,
          labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
