import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Coupon_Model.dart';
import '../Model/Model.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import '../Provider/CartProvider.dart';
import '../Provider/SettingProvider.dart';
import '../Provider/UserProvider.dart';
import 'Add_Address.dart';
import 'HomePage.dart';
import 'Manage_Address.dart';
import 'Order_Success.dart';
import 'Payment.dart';
import 'PaypalWebviewActivity.dart';
import 'Product_Detail.dart';
import 'Splash.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Cart extends StatefulWidget {
  final bool fromBottom;
  final Product? model;

  const Cart({
    Key? key,
    required this.fromBottom,
    this.model,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateCart();
}

List<User> addressList = [];
List<SectionModel> buyNowCartList = [];
int buyNowSelectedIndex = -1;
//List<SectionModel> cartList = [];
List<Promo> promoList = [];
List<Promo> productpromoList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0, taxAmount = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode;
List<dynamic> promoCodes = [];
bool? isTimeSlot,
    isPromoValid = false,
    isUseWallet = false,
    isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;
double promoAmt = 0;
double remWalBal = 0, usedBal = 0;
bool isAvailable = true;
bool _isSaveForLaterVisible = false;

String? razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId,
    paytmMerKey;
bool payTesting = true;

/*String gpayEnv = "TEST",
    gpayCcode = "US",
    gpaycur = "USD",
    gpayMerId = "01234567890123456789",
    gpayMerName = "Example Merchant Name";*/

class StateCart extends State<Cart> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();

  final GlobalKey<ScaffoldMessengerState> _checkscaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();
  List<Model> deliverableList = [];
  bool _isCartLoad = true, _placeOrder = true;

  //HomePage? home;
  Animation? labelLargeSqueezeanimation;
  AnimationController? labelLargeController;
  bool _isNetworkAvail = true;

  List<TextEditingController> _controller = [];
  List<dynamic> promoCodes = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<SectionModel> saveLaterList = [];
  String? msg;
  String? sellerId;
  bool _isLoading = true;
  Razorpay? _razorpay;
  TextEditingController promoC = new TextEditingController();
  TextEditingController noteC = new TextEditingController();
  StateSetter? checkoutState;
  // final paystackPlugin = PaystackPlugin();
  bool deliverable = false;
  bool saveLater = false, addCart = false;
  bool isOnOff = false;
  String? totalamount;

  //List<PaymentItem> _gpaytItems = [];
  //Pay _gpayClient;

  @override
  void initState() {
    super.initState();
    clearAll();
    _getAddress();
    _getCart("0");
    _getSaveLater("1");
    promoCodes.clear();

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

  Future<Null> _refresh() {
    if (mounted)
      setState(() {
        _isCartLoad = true;
      });
    clearAll();

    _getCart("0");
    promoCodes.clear();
    return _getSaveLater("1");
  }

  clearAll() {
    totalPrice = 0;
    oriPrice = 0;
    cgstAmount = 0.0;
    sgstAmount = 0.0;
    taxPer = 0;
    delCharge = 0;
    addressList.clear();
    // cartList.clear();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      context.read<CartProvider>().setCartlist([]);
      context.read<CartProvider>().setProgress(false);
    });

    promoAmt = 0;
    remWalBal = 0;
    usedBal = 0;
    payMethod = '';
    isPromoValid = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
  }

  @override
  void dispose() {
    labelLargeController!.dispose();
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();

    if (_razorpay != null) _razorpay!.clear();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await labelLargeController!.forward();
    } on TickerCanceled {}
  }

  CouponListModel? couponListModel;
  Future<void> getCouponList({String? productId}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}get_promo_codes'));

      request.fields.addAll({
        'user_id': CUR_USERID.toString(),
        PRODUCT_ID: widget.model!.id.toString(),
        'promo_code_type': 'product'
      });

      print('Promo API Request: ${request.fields}');

      http.StreamedResponse response = await request.send();
      var jsonString = await response.stream.bytesToString();
      var json = jsonDecode(jsonString);

      print('Promo API Response: $json');

      if (response.statusCode == 200) {
        couponListModel = CouponListModel.fromJson(json);
        if (mounted) setState(() {});
      } else {
        print('Error: ${response.reasonPhrase}');
        if (mounted) {
          setSnackbar('Failed to load coupons', _scaffoldKey);
        }
      }
    } catch (e) {
      print('Exception in getCouponList: $e');
      if (mounted) {
        setSnackbar('Error loading coupons', _scaffoldKey);
      }
    }
  }

  void getSetting() {
    CUR_USERID = context.read<SettingProvider>().userId;
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};
    apiBaseHelper.postAPICall(getSettingApi, parameter).then((getdata) async {
      bool error = getdata["error"];
      String? msg = getdata["message"];

      print("Get Setting Api${getSettingApi.toString()}");
      print(parameter.toString());

      if (!error) {
        var data = getdata["data"]["system_settings"][0];
        print(
            "====in api========min cart amount =========${data[MIN_CART_AMT]}");
        MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];
      } else {}
    }, onError: (error) {});
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
          backgroundColor: colors.grad1Color1,
          appBar: widget.fromBottom
              ? null
              : getSimpleAppBar(getTranslated(context, 'CART')!, context),
          body: _isNetworkAvail
              ? Stack(
                  children: <Widget>[
                    _showContent(context),
                    Selector<CartProvider, bool>(
                      builder: (context, data, child) {
                        return showCircularProgress(data, colors.primary);
                      },
                      selector: (_, provider) => provider.isProgress,
                    ),
                  ],
                )
              : noInternet(context)),
    );
  }

  Map<String, dynamic>? getPromoCodeForProduct(String productId) {
    final result =
        promoCodes.where((promo) => promo["product_id"] == productId);
    return result.isNotEmpty ? result.first : null;
  }

  void removePromoCodeByCode(String promoCodeToRemove) {
    promoCodes.removeWhere((item) => item["promo_code"] == promoCodeToRemove);
  }

  Widget listItem(int index, List<SectionModel> cartList) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }
    String? offPer;
    double price = double.parse(
        cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
    if (price == 0)
      price = double.parse(
          cartList[index].productList![0].prVarientList![selectedPos].price!);
    else {
      double off = (double.parse(cartList[index]
              .productList![0]
              .prVarientList![selectedPos]
              .price!)) -
          price;
      offPer = (off *
              100 /
              double.parse(cartList[index]
                  .productList![0]
                  .prVarientList![selectedPos]
                  .price!))
          .toStringAsFixed(2);
    }

    cartList[index].perItemPrice = price.toString();
    //print("qty************${cartList.contains("qty")}");
    print("cartList**avail****${cartList[index].productList![0].availability}");

    if (_controller.length < index + 1) {
      _controller.add(new TextEditingController());
    }
    if (cartList[index].productList![0].availability != "0") {
      cartList[index].perItemTotal =
          (price * double.parse(cartList[index].qty!)).toString();
      _controller[index].text = cartList[index].qty!;
    }
    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        null) {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }

    if (cartList[index].productList![0].availability == "0") {
      isAvailable = false;
    }

    int promoLength = cartList[index].productList?[0].promos?.length ?? 0;

    var promoData = getPromoCodeForProduct(cartList[index].id);

    print("promoData $promoData");

    return InkWell(
        onTap: () {
          print('object_____________');
          Product model = cartList[index].productList![0];
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      model: model,
                      index: index,
                      secPos: 0,
                      list: true,
                    )),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Card(
            elevation: 0.3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100,
                        height: 150,
                        child: FadeInImage(
                          image: CachedNetworkImageProvider(
                            cartList[index].productList![0].image!,
                          ),
                          placeholder: placeHolder(125),
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(125),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Product Name
                            Text(
                              cartList[index].productList![0].name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: dynamicFontFamily.fontFamily),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .attr_name !=
                                        null &&
                                    cartList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .attr_name!
                                        .isNotEmpty
                                ? ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: att.length,
                                    itemBuilder: (context, index) {
                                      return Row(children: [
                                        Flexible(
                                          child: Text(
                                            att[index].trim() + ":",
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                    fontFamily:
                                                        dynamicFontFamily
                                                            .fontFamily),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 5.0),
                                          child: Text(
                                            val[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily:
                                                        dynamicFontFamily
                                                            .fontFamily),
                                          ),
                                        )
                                      ]);
                                    })
                                : Container(),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  cartList[index].productList![0].rating!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                GestureDetector(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.remove,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (context
                                            .read<CartProvider>()
                                            .isProgress ==
                                        false) {
                                      removeFromCart(index, false, cartList,
                                          false, selectedPos);
                                    }
                                  },
                                ),
                                Container(
                                  width: 26,
                                  height: 20,
                                  child: Stack(
                                    children: [
                                      TextField(
                                        textAlign: TextAlign.center,
                                        readOnly: true,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor),
                                        controller: _controller[index],
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ), // ),

                                GestureDetector(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (context
                                            .read<CartProvider>()
                                            .isProgress ==
                                        false) {
                                      addToCart(
                                          index,
                                          (int.parse(cartList[index].qty!) +
                                                  int.parse(cartList[index]
                                                      .productList![0]
                                                      .qtyStepSize!))
                                              .toString(),
                                          cartList);
                                    }
                                  },
                                )
                              ],
                            ),

                            SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                  double.parse(cartList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .disPrice!) !=
                                          0
                                      ? CUR_CURRENCY! +
                                          "" +
                                          double.parse(cartList[index]
                                                      .productList![0]
                                                      .prVarientList![
                                                          selectedPos]
                                                      .price! ??
                                                  "0.0")
                                              .toStringAsFixed(2)
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          letterSpacing: 0.7,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                ),
                                Text(
                                  " " +
                                      CUR_CURRENCY! +
                                      " " +
                                      price.toStringAsFixed(2),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  thickness: 1,
                ),
                promoData != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  promoData["promo_code"] ?? "",
                                  style: TextStyle(
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 8,
                                  children: [
                                    InkWell(
                                        onTap: () {
                                          removePromoCodeByCode(
                                              promoData["promo_code"]);
                                          setState(() {});
                                        },
                                        child: Icon(Icons.remove_circle_outline,
                                            color: Colors.redAccent, size: 18)),
                                    Text(
                                      "- " +
                                          CUR_CURRENCY! +
                                          " ${promoData["amount"].toStringAsFixed(2)}",
                                      style: TextStyle(
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: TextStyle(
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                                Text(
                                  CUR_CURRENCY! +
                                      " " +
                                      (price - promoData["amount"])
                                          .toStringAsFixed(2),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 6,
                            ),
                          ],
                        ),
                      )
                    : promoLength > 0 && oriPrice > 0
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Column(
                              children: cartList[index]
                                  .productList![0]
                                  .promos!
                                  .map((promoItem) => Card(
                                        elevation: 0,
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 60,
                                              width: 60,
                                              child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                  child: Image.network(
                                                    promoItem.image ?? "",
                                                    height: 60,
                                                    width: 60,
                                                    fit: BoxFit.fill,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        erroWidget(
                                                      60,
                                                    ),
                                                  )),
                                            ),

                                            //errorWidget: (context, url, e) => placeHolder(width),

                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      promoItem.message ?? "",
                                                      style: TextStyle(
                                                          fontFamily:
                                                              dynamicFontFamily
                                                                  .fontFamily),
                                                    ),
                                                    Text(
                                                      promoItem.promoCode ?? '',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              dynamicFontFamily
                                                                  .fontFamily),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Text(promoList[0].day ?? '',
                                                style: TextStyle(
                                                    fontFamily:
                                                        dynamicFontFamily
                                                            .fontFamily)),
                                            SimBtn(
                                              size: 0.3,
                                              title: getTranslated(
                                                  context, "APPLY"),
                                              onBtnSelected: () {
                                                promoC.text =
                                                    promoItem.promoCode! ?? "";
                                                validatePromo(
                                                    false,
                                                    cartList[index]
                                                        .productList?[0]
                                                        .id!);
                                                // Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          )
                        : Container(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            removeFromCart(
                                index, true, cartList, false, selectedPos);
                          },
                          icon: Icon(Icons.delete_forever,
                              color: Colors.grey.shade800),
                          label: Text(
                            "Remove",
                            style: TextStyle(
                                color: Colors.grey.shade800,
                                fontFamily: dynamicFontFamily.fontFamily),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            saveForLater(
                              cartList[index].varientId,
                              "1",
                              cartList[index].qty,
                              double.parse(cartList[index].perItemTotal!),
                              cartList[index],
                              false,
                            );
                          },
                          icon:
                              Icon(Icons.archive, color: Colors.grey.shade800),
                          label: Text(
                            "Save for later",
                            style: TextStyle(
                                color: Colors.grey.shade800,
                                fontFamily: dynamicFontFamily.fontFamily),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            bool outOfStock = false;
                            if (cartList[index].productList![0].availability ==
                                "0") {
                              outOfStock = true;
                            }
                            if (outOfStock) {
                              setSnackbar(
                                'This product is out of stock!',
                                _checkscaffoldKey,
                              );
                            } else {
                              buyNowSelectedIndex = index;
                              buyNowCartList = [cartList[index]];
                              _getBuyCart(buyNowCartList, 0);
                              buycheckout(buyNowCartList);
                            }
                          },
                          icon: Icon(Icons.shopping_bag,
                              color: Colors.grey.shade800),
                          label: Text(
                            "Buy This Now",
                            style: TextStyle(
                                color: Colors.grey.shade800,
                                fontFamily: dynamicFontFamily.fontFamily),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget cartItem(int index, List<SectionModel> cartList) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }

    double price = double.tryParse(cartList[index]
                .productList?[0]
                .prVarientList?[selectedPos]
                .disPrice ??
            "0") ??
        0;
    if (price == 0) {
      price = double.tryParse(cartList[index]
                  .productList?[0]
                  .prVarientList?[selectedPos]
                  .price ??
              "0") ??
          0;
    }

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        (price * double.tryParse(cartList[index].qty ?? "0")!).toString();

    _controller[index].text = cartList[index].qty ?? "0";

    var promoData = getPromoCodeForProduct(cartList[index].id);

    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        null) {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }

    String? id, varId;
    bool? avail = false;
    if (deliverableList.length > 0) {
      id = cartList[index].id;
      varId = cartList[index].productList![0].prVarientList![selectedPos].id;

      for (int i = 0; i < deliverableList.length; i++) {
        if (id == deliverableList[i].prodId &&
            varId == deliverableList[i].varId) {
          avail = deliverableList[i].isDel;

          break;
        }
      }
    }

    var itemTotal = double.parse(cartList[index].perItemTotal!);

    if (promoData != null) {
      itemTotal = itemTotal - promoData?["amount"];
    }

    return InkWell(
      onTap: () {},
      child: Card(
        elevation: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Hero(
                      tag: "$index${cartList[index].productList![0].id}",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: FadeInImage(
                            image: CachedNetworkImageProvider(
                                cartList[index].productList![0].image!),
                            height: 80.0,
                            width: 80.0,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(80),

                            // errorWidget: (context, url, e) => placeHolder(60),
                            placeholder: placeHolder(80),
                          ))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    cartList[index].productList![0].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack,
                                            fontFamily:
                                                dynamicFontFamily.fontFamily),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          cartList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .attr_name !=
                                      null &&
                                  cartList[index]
                                      .productList![0]
                                      .prVarientList![selectedPos]
                                      .attr_name!
                                      .isNotEmpty
                              ? ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: att.length,
                                  itemBuilder: (context, index) {
                                    return Row(children: [
                                      Flexible(
                                        child: Text(
                                          att[index].trim() + ":",
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack,
                                                  fontFamily: dynamicFontFamily
                                                      .fontFamily),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 5.0),
                                        child: Text(
                                          val[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: dynamicFontFamily
                                                      .fontFamily),
                                        ),
                                      )
                                    ]);
                                  })
                              : Container(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        double.parse(cartList[index]
                                                    .productList![0]
                                                    .prVarientList![selectedPos]
                                                    .disPrice!) !=
                                                0
                                            ? CUR_CURRENCY! +
                                                "" +
                                                double.parse(cartList[index]
                                                            .productList![0]
                                                            .prVarientList![
                                                                selectedPos]
                                                            .price! ??
                                                        "0.0")
                                                    .toStringAsFixed(2)
                                            : "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                letterSpacing: 0.7,
                                                fontFamily: dynamicFontFamily
                                                    .fontFamily),
                                      ),
                                    ),
                                    Text(
                                      " " +
                                          CUR_CURRENCY! +
                                          " " +
                                          price.toStringAsFixed(2),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                    ),
                                  ],
                                ),
                              ),
                              cartList[index].productList![0].availability ==
                                          "1" ||
                                      cartList[index]
                                              .productList![0]
                                              .stockType ==
                                          "null"
                                  ? Row(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Container(
                                              width: 26,
                                              height: 20,
                                              child: Stack(
                                                children: [
                                                  TextField(
                                                    textAlign: TextAlign.center,
                                                    readOnly: true,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor),
                                                    controller:
                                                        _controller[index],
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  // Text(
                  //   CUR_CURRENCY! + " " + price.toStringAsFixed(2),
                  //   style: TextStyle(
                  //       color: Theme.of(context).colorScheme.lightBlack2,
                  //       fontFamily: dynamicFontFamily.fontFamily),
                  // ),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        double.parse(cartList[index].perItemTotal! ?? "0.0")
                            .toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'TAXPER')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    cartList[index].productList![0].tax! + "%",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                ],
              ),
              if (promoData != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Discount",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontFamily: dynamicFontFamily.fontFamily),
                    ),
                    Text(
                      CUR_CURRENCY! +
                          " ${promoData?["amount"].toStringAsFixed(2)}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontFamily: dynamicFontFamily.fontFamily),
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'TOTAL_LBL')!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  !avail! && deliverableList.length > 0
                      ? Text(
                          getTranslated(context, 'NOT_DEL')!,
                          style: TextStyle(
                              color: colors.red,
                              fontFamily: dynamicFontFamily.fontFamily),
                        )
                      : Container(),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        itemTotal.toStringAsFixed(2).toString(),
                    //+ " "+cartList[index].productList[0].taxrs,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.fontColor,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget saveLaterItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < saveLaterList[index].productList![0].prVarientList!.length;
        i++) {
      if (saveLaterList[index].varientId ==
          saveLaterList[index].productList![0].prVarientList![i].id)
        selectedPos = i;
    }

    double price = double.parse(saveLaterList[index]
        .productList![0]
        .prVarientList![selectedPos]
        .disPrice!);
    if (price == 0) {
      price = double.parse(saveLaterList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .price!);
    }

    double off = (double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .price!) -
            double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .disPrice!))
        .toDouble();
    off = off *
        100 /
        double.parse(saveLaterList[index]
            .productList![0]
            .prVarientList![selectedPos]
            .price!);

    saveLaterList[index].perItemPrice = price.toString();
    if (saveLaterList[index].productList![0].availability != "0") {
      saveLaterList[index].perItemTotal =
          (price * double.parse(saveLaterList[index].qty!)).toString();
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0.1,
              child: Row(
                children: <Widget>[
                  Hero(
                      tag: "$index${saveLaterList[index].productList![0].id}",
                      child: Stack(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: Stack(children: [
                                FadeInImage(
                                  image: CachedNetworkImageProvider(
                                      saveLaterList[index]
                                          .productList![0]
                                          .image!),
                                  height: 100.0,
                                  width: 100.0,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          erroWidget(100),
                                  placeholder: placeHolder(100),
                                ),
                                Positioned.fill(
                                    child: saveLaterList[index]
                                                .productList![0]
                                                .availability ==
                                            "0"
                                        ? Container(
                                            height: 55,
                                            color: Colors.white70,
                                            // width: double.maxFinite,
                                            padding: EdgeInsets.all(2),
                                            child: Center(
                                              child: Text(
                                                getTranslated(context,
                                                    'OUT_OF_STOCK_LBL')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily:
                                                            dynamicFontFamily
                                                                .fontFamily),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : Container()),
                              ])),
                          (off != 0 || off != 0.0 || off != 0.00) &&
                                  saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .disPrice! !=
                                      "0"
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      off.toStringAsFixed(2) + "%",
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                    ),
                                  ),
                                  margin: EdgeInsets.all(5),
                                )
                              : Container()
                        ],
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    saveLaterList[index].productList![0].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontFamily:
                                                dynamicFontFamily.fontFamily),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 8.0, end: 8, bottom: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                  ),
                                ),
                                onTap: () {
                                  if (context.read<CartProvider>().isProgress ==
                                      false)
                                    removeFromCart(index, true, saveLaterList,
                                        true, selectedPos);
                                },
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                double.parse(saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .disPrice!) !=
                                        0
                                    ? CUR_CURRENCY! +
                                        "" +
                                        double.parse(saveLaterList[index]
                                                    .productList![0]
                                                    .prVarientList![selectedPos]
                                                    .price! ??
                                                "0.0")
                                            .toStringAsFixed(2)
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0.7,
                                        fontFamily:
                                            dynamicFontFamily.fontFamily),
                              ),
                              Text(
                                " " +
                                    CUR_CURRENCY! +
                                    " " +
                                    price.toStringAsFixed(2),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: dynamicFontFamily.fontFamily),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            saveLaterList[index].productList![0].availability == "1" ||
                    saveLaterList[index].productList![0].stockType == "null"
                ? Positioned(
                    bottom: -15,
                    right: 0,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.shopping_cart,
                            size: 20,
                          ),
                        ),
                        onTap:
                            !addCart && !context.read<CartProvider>().isProgress
                                ? () {
                                    setState(() {
                                      addCart = true;
                                    });
                                    saveForLater(
                                        saveLaterList[index].varientId,
                                        "0",
                                        saveLaterList[index].qty,
                                        double.parse(
                                            saveLaterList[index].perItemTotal!),
                                        saveLaterList[index],
                                        true);
                                  }
                                : null,
                      ),
                    ))
                : Container()
          ],
        ));
  }

  Future<void> _getBuyCart(
    List<SectionModel> cartList,
    int index,
  ) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress ?? '',
          PRODUCT_VARIENT_IDs: cartList[index].varientId,
          'buy_now': 1,
        };

        print('buycart:_____${parameter}______');
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];

          setState(() {
            totalamount = getdata['overall_amount'];
            oriPrice = double.parse(getdata[SUB_TOTAL]);
            dCharge = double.parse(
                getdata['delivery_charge'].toString().replaceAll(",", ""));
            taxAmount = double.parse(
                getdata['tax_amount'].toString().replaceAll(",", ""));
            taxPer = double.parse(getdata[TAX_PER]);

            cgstAmount = getdata['cgst_amount'] != null
                ? double.parse(
                    getdata['cgst_amount'].toString().replaceAll(",", ""))
                : 0.0;
            sgstAmount = getdata['sgst_amount'] != null
                ? double.parse(
                    getdata['sgst_amount'].toString().replaceAll(",", ""))
                : 0.0;
          });

          print("Subtotal: $oriPrice");
          print("CGST Amount: $cgstAmount");
          print("SGST Amount: $sgstAmount");
          print("Tax Amount: $taxAmount");
          print("Total Amount: $totalamount");

          totalPrice = delCharge + oriPrice;
          List<SectionModel> responseCartList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();

          buyNowCartList = responseCartList;
          if (_controller.length <= 0) {
            _controller.add(new TextEditingController());
          }

          if (getdata.containsKey(PROMO_CODES)) {
            var promo = getdata[PROMO_CODES];
            promoList =
                (promo as List).map((e) => new Promo.fromJson(e)).toList();
          }
        } else {
          // if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
        }

        if (mounted) {
          setState(() {
            _isCartLoad = false;
          });
        }

        _getAddress();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  var dCharge;
  String? overallAmount;
  double cgstAmount = 0.0;
  double sgstAmount = 0.0;
  Future<void> _getCart(String save) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress ?? '',
          SAVE_LATER: save
        };
        print('cart:_____${parameter}______');
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];

          setState(() {
            totalamount = getdata['overall_amount'];
            oriPrice = double.parse(getdata[SUB_TOTAL]);
            dCharge = double.parse(
                getdata['delivery_charge'].toString().replaceAll(",", ""));
            taxAmount = double.parse(
                getdata['tax_amount'].toString().replaceAll(",", ""));
            taxPer = double.parse(getdata[TAX_PER]);

            cgstAmount = getdata['cgst_amount'] != null
                ? double.parse(
                    getdata['cgst_amount'].toString().replaceAll(",", ""))
                : 0.0;
            sgstAmount = getdata['sgst_amount'] != null
                ? double.parse(
                    getdata['sgst_amount'].toString().replaceAll(",", ""))
                : 0.0;
          });

          print("Subtotal: $oriPrice");
          print("CGST Amount: $cgstAmount");
          print("SGST Amount: $sgstAmount");
          print("Tax Amount: $taxAmount");
          print("Total Amount: $totalamount");

          totalPrice = delCharge + oriPrice;

          List<SectionModel> cartList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();
          context.read<CartProvider>().setCartlist(cartList);
          if (getdata.containsKey(PROMO_CODES)) {
            var promo = getdata[PROMO_CODES];

            if (promo != null && promo is List && promo.isNotEmpty) {
              promoList = promo.map((e) => Promo.fromJson(e)).toList();
            } else {
              promoList = [];
            }
          }

          // if (getdata.containsKey(PROMO_CODES)) {
          //   var promo = getdata[PROMO_CODES];
          //   promoList =
          //       (promo as List).map((e) => new Promo.fromJson(e)).toList()??;
          // }

          for (int i = 0; i < cartList.length; i++) {
            _controller.add(new TextEditingController());
          }
        } else {
          // if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
        }

        if (mounted) {
          setState(() {
            _isCartLoad = false;
          });
        }

        _getAddress();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  promoSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 50),
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9),
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                            margin: const EdgeInsetsDirectional.only(end: 20),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius:
                                    BorderRadiusDirectional.circular(10)),
                            child: TextField(
                              controller: promoC,
                              style: Theme.of(context).textTheme.titleMedium,
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                border: InputBorder.none,
                                //isDense: true,
                                hintText:
                                    getTranslated(context, 'PROMOCODE_LBL'),
                              ),
                            )),
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          end: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (promoAmt != 0 && isPromoValid!)
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        child: Icon(
                                          Icons.close,
                                          size: 15,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                        ),
                                        onTap: () {
                                          if (promoAmt != 0 && isPromoValid!) {
                                            if (mounted)
                                              setState(() {
                                                totalPrice =
                                                    totalPrice + promoAmt;
                                                promoC.text = '';
                                                isPromoValid = false;
                                                promoAmt = 0;
                                                promocode = '';
                                              });
                                          }
                                        },
                                      ),
                                    )
                                  : Container(),
                              InkWell(
                                child: Container(
                                    padding: EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dynamicColor.buttonColor,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: dynamicColor.buttonTxtColor,
                                    )),
                                onTap: () {
                                  if (promoC.text.trim().isEmpty)
                                    setSnackbar(
                                        getTranslated(context, 'ADD_PROMO')!,
                                        _checkscaffoldKey);
                                  else if (!isPromoValid!) {
                                    validatePromo(false, 0);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Text(
                        getTranslated(context, 'Choose_PROMO') ?? '',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontFamily: dynamicFontFamily.fontFamily),
                      ),
                    ),
                    ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: promoList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 0,
                            child: Row(
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7.0),
                                      child: Image.network(
                                        promoList[index].image!,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.fill,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                erroWidget(
                                          80,
                                        ),
                                      )),
                                ),

                                //errorWidget: (context, url, e) => placeHolder(width),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promoList[index].msg ?? "",
                                          style: TextStyle(
                                              fontFamily:
                                                  dynamicFontFamily.fontFamily),
                                        ),
                                        Text(
                                          promoList[index].promoCode ?? '',
                                          style: TextStyle(
                                              fontFamily:
                                                  dynamicFontFamily.fontFamily),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  promoList[index].day ?? '',
                                  style: TextStyle(
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                                SimBtn(
                                  size: 0.3,
                                  title: getTranslated(context, "APPLY"),
                                  onBtnSelected: () {
                                    promoC.text = promoList[index].promoCode!;
                                    if (!isPromoValid!) validatePromo(false, 0);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                  ])),
            );
            //});
          });
        });
  }

  Future<Null> _getSaveLater(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          SAVE_LATER: save,
        };
        print("this is ------->${parameter}");
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(getCartApi.toString());
        // print(getCartApi.toString());
        var getdata = json.decode(response.body);
        print(getCartApi.toString());
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          saveLaterList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();

          List<SectionModel> cartList = context.read<CartProvider>().cartList;
          for (int i = 0; i < cartList.length; i++)
            _controller.add(new TextEditingController());
        } else {
          // if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
        }
        if (mounted) setState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }

    return null;
  }

  Future<void> addToCart(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    // if (int.parse(qty) >= cartList[index].productList[0].minOrderQuntity) {
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar(
              "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
          'seller_id': cartList[index].productList?[0].seller_id ?? ''
        };
        print('addtoacrt:_____${parameter}______');
        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        print('addmessage_____${msg}______');
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          // CUR_CART_COUNT = data['cart_count'];

          context.read<UserProvider>().setCartCount(data['cart_count']);
          cartList[index].qty = qty;

          oriPrice = double.parse(data['sub_total']);
          delCharge = double.parse(getdata['delivery_charge'] ?? '0');
          print(" charge here New----- ${delCharge}");

          _controller[index].text = qty;
          totalPrice = 0;

          var cart = getdata["cart"];
          List<SectionModel> uptcartList = (cart as List)
              .map((cart) => new SectionModel.fromCart(cart))
              .toList();
          context.read<CartProvider>().setCartlist(uptcartList);

          if (!ISFLAT_DEL) {
            if (addressList.length == 0) {
              delCharge = 0;
            } else {
              if ((oriPrice) <
                  double.parse(addressList[selectedAddress!].freeAmt!))
                delCharge =
                    double.parse(addressList[selectedAddress!].deliveryCharge!);
              else
                delCharge = 0;
            }
          } else {
            if (oriPrice < double.parse(MIN_AMT!))
              delCharge = double.parse(CUR_DEL_CHR!);
            else
              delCharge = 0;
          }
          totalPrice = delCharge + oriPrice;

          if (isPromoValid!) {
            validatePromo(false, 0);
          } else if (isUseWallet!) {
            context.read<CartProvider>().setProgress(false);
            if (mounted)
              setState(() {
                remWalBal = 0;
                payMethod = null;
                usedBal = 0;
                isUseWallet = false;
                isPayLayShow = true;

                selectedMethod = null;
              });
          } else {
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        } else {
          setSnackbar(msg!, _scaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    // } else
    // setSnackbar(
    //     "Minimum allowed quantity is ${cartList[index].productList[0].minOrderQuntity} ",
    //     _scaffoldKey);
  }

  Future<void> addToCartCheckout(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar(
              "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
          'seller_id': cartList[index].productList?[0].seller_id ?? ''
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(manageCartApi.toString());
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            cartList[index].qty = qty;

            oriPrice = double.parse(data['sub_total']);
            _controller[index].text = qty;
            totalPrice = 0;

            if (!ISFLAT_DEL) {
              if ((oriPrice) <
                  double.parse(addressList[selectedAddress!].freeAmt!))
                delCharge =
                    double.parse(addressList[selectedAddress!].deliveryCharge!);
              else
                delCharge = 0;
            } else {
              if ((oriPrice) < double.parse(MIN_AMT!))
                delCharge = double.parse(CUR_DEL_CHR!);
              else
                delCharge = 0;
            }
            totalPrice = delCharge + oriPrice;

            if (isPromoValid!) {
              validatePromo(true, 0);
            } else if (isUseWallet!) {
              if (mounted)
                checkoutState!(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;
                  selectedMethod = null;
                });
              setState(() {});
            } else {
              context.read<CartProvider>().setProgress(false);
              setState(() {});
              checkoutState!(() {});
            }
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
      setState(() {});
    }
  }

  saveForLater(String? id, String save, String? qty, double price,
      SectionModel curItem, bool fromSave) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          PRODUCT_VARIENT_ID: id,
          USER_ID: CUR_USERID,
          QTY: qty,
          SAVE_LATER: save,
        };

        print("param****save***********$parameter");

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          // CUR_CART_COUNT = data['cart_count'];
          context.read<UserProvider>().setCartCount(data['cart_count']);
          if (save == "1") {
            setSnackbar("Saved For Later", _scaffoldKey);
            saveLaterList.add(curItem);
            //cartList.removeWhere((item) => item.varientId == id);
            context.read<CartProvider>().removeCartItem(id!);
            setState(() {
              saveLater = false;
            });
            oriPrice = oriPrice - price;
          } else {
            setSnackbar("Added To Cart", _scaffoldKey);
            // cartList.add(curItem);
            context.read<CartProvider>().addCartItem(curItem);
            saveLaterList.removeWhere((item) => item.varientId == id);
            setState(() {
              addCart = false;
            });
            oriPrice = oriPrice + price;
          }

          totalPrice = 0;

          if (!ISFLAT_DEL) {
            if (addressList.length > 0 &&
                (oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!)) {
              delCharge =
                  double.parse(addressList[selectedAddress!].deliveryCharge!);
            } else {
              delCharge = 0;
            }
          } else {
            if ((oriPrice) < double.parse(MIN_AMT!)) {
              delCharge = double.parse(CUR_DEL_CHR!);
            } else {
              delCharge = 0;
            }
          }
          totalPrice = delCharge + oriPrice;

          if (isPromoValid!) {
            validatePromo(false, 0);
          } else if (isUseWallet!) {
            context.read<CartProvider>().setProgress(false);
            if (mounted)
              setState(() {
                remWalBal = 0;
                payMethod = null;
                usedBal = 0;
                isUseWallet = false;
                isPayLayShow = true;
              });
          } else {
            context.read<CartProvider>().setProgress(false);
            setState(() {});
          }
        } else {
          setSnackbar(msg!, _scaffoldKey);
        }

        context.read<CartProvider>().setProgress(false);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCartCheckout(
      int index, bool remove, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          _checkscaffoldKey);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int? qty;
          if (remove)
            qty = 0;
          else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
                  _checkscaffoldKey);
            }
          }

          var parameter = {
            PRODUCT_VARIENT_ID: cartList[index].varientId,
            USER_ID: CUR_USERID,
            QTY: qty.toString(),
            'seller_id': cartList[index].productList?[0].seller_id ?? ''
          };
          print('remove:_____${parameter}______');

          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          if (response.statusCode == 200) {
            var getdata = json.decode(response.body);

            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];
              // CUR_CART_COUNT = data['cart_count'];

              context.read<UserProvider>().setCartCount(data['cart_count']);
              if (qty == "0") remove = true;

              if (remove) {
                // cartList.removeWhere((item) => item.varientId == cartList[index].varientId);

                context
                    .read<CartProvider>()
                    .removeCartItem(cartList[index].varientId!);
              } else {
                cartList[index].qty = qty.toString();
              }

              oriPrice = double.parse(data[SUB_TOTAL]);

              if (!ISFLAT_DEL) {
                if ((oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!))
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                else
                  delCharge = 0;
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!))
                  delCharge = double.parse(CUR_DEL_CHR!);
                else
                  delCharge = 0;
              }

              totalPrice = 0;

              totalPrice = delCharge + oriPrice;

              if (isPromoValid!) {
                validatePromo(true, 0);
              } else if (isUseWallet!) {
                if (mounted)
                  checkoutState!(() {
                    remWalBal = 0;
                    payMethod = null;
                    usedBal = 0;
                    isPayLayShow = true;
                    isUseWallet = false;
                  });
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              } else {
                context.read<CartProvider>().setProgress(false);

                checkoutState!(() {});
                setState(() {});
              }
            } else {
              setSnackbar(msg!, _checkscaffoldKey);
              context.read<CartProvider>().setProgress(false);
            }
          }
        } on TimeoutException catch (_) {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } else {
        if (mounted)
          checkoutState!(() {
            _isNetworkAvail = false;
          });
        setState(() {});
      }
    }
  }

  removeFromCart(int index, bool remove, List<SectionModel> cartList, bool move,
      int selPos) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          _scaffoldKey);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int? qty;
          if (remove)
            qty = 0;
          else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
                  _checkscaffoldKey);
            }
          }
          String varId;
          if (cartList[index].productList![0].availability == "0") {
            varId = cartList[index].productList![0].prVarientList![selPos].id!;
          } else {
            varId = cartList[index].varientId!;
          }
          print("carient**********${cartList[index].varientId}");
          var parameter = {
            PRODUCT_VARIENT_ID: varId,
            USER_ID: CUR_USERID,
            QTY: qty.toString(),
            'seller_id': cartList[index].productList?[0].seller_id ?? ''
          };
          print('removemain:_____${parameter}______');

          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          print(getdata);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            print("msg************$msg");
            var data = getdata["data"];
            // setSnackbar("Deleted", _scaffoldKey);
            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            if (move == false) {
              if (qty == "0") remove = true;

              if (remove) {
                cartList.removeWhere(
                    (item) => item.varientId == cartList[index].varientId);
              } else {
                cartList[index].qty = qty.toString();
              }

              oriPrice = double.parse(data[SUB_TOTAL]);
              if (!ISFLAT_DEL) {
                try {
                  if ((oriPrice) <
                      double.parse(addressList[selectedAddress!].freeAmt!))
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  else
                    delCharge = 0;
                } catch (e) {
                  print(e);
                }
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!))
                  delCharge = double.parse(CUR_DEL_CHR!);
                else
                  delCharge = 0;
              }

              totalPrice = 0;

              totalPrice = delCharge + oriPrice;
              if (isPromoValid!) {
                validatePromo(false, 0);
              } else if (isUseWallet!) {
                context.read<CartProvider>().setProgress(false);
                if (mounted)
                  setState(() {
                    remWalBal = 0;
                    payMethod = null;
                    usedBal = 0;
                    isPayLayShow = true;
                    isUseWallet = false;
                  });
              } else {
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              }
            } else {
              if (qty == "0") remove = true;

              if (remove) {
                cartList.removeWhere(
                    (item) => item.varientId == cartList[index].varientId);
              }
            }
          } else {
            print("msg111************$msg");
            setSnackbar(msg!, _scaffoldKey);
          }
          if (mounted) setState(() {});
          context.read<CartProvider>().setProgress(false);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } else {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      }
    }
  }

  setSnackbar(
      String msg, GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      duration: Duration(seconds: 1),
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Theme.of(context).colorScheme.black,
            fontFamily: dynamicFontFamily.fontFamily),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  _showContent(BuildContext context) {
    List<SectionModel> cartList = context.read<CartProvider>().cartList;
    print("cart list************${cartList.length}");

    var totalProductPromosAmount = calculateTotalPromoDiscount();

    var promoAmtTemp = 0.0;

    if (isPromoValid == true) {
      promoAmtTemp = promoAmt;
    }

    // Calculate final total
    double finalTotalTempTotal =
        oriPrice - promoAmtTemp - totalProductPromosAmount;

    print("oriPrice $oriPrice, $promoAmtTemp, $totalProductPromosAmount");

    return _isCartLoad
        ? shimmer(context)
        : cartList.length == 0 && saveLaterList.length == 0
            ? cartEmpty()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: RefreshIndicator(
                            color: colors.primary,
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: cartList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return listItem(index, cartList);
                                    },
                                  ),
                                  saveLaterList.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            getTranslated(
                                                context, 'SAVEFORLATER_BTN')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontFamily:
                                                        dynamicFontFamily
                                                            .fontFamily),
                                          ),
                                        )
                                      : Container(),
                                  VisibilityDetector(
                                    key: const Key("save_for_later_section"),
                                    onVisibilityChanged: (info) {
                                      setState(() {
                                        _isSaveForLaterVisible =
                                            info.visibleFraction > 0;
                                      });
                                    },
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: saveLaterList.length,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return saveLaterItem(index);
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ))),
                  ),
                  cartList.length <= 2
                      ? Container(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // promoList.length > 0 && oriPrice > 0
                                //     ? Padding(
                                //         padding: const EdgeInsets.symmetric(
                                //             horizontal: 10.0),
                                //         child: InkWell(
                                //           child: Stack(
                                //             alignment: Alignment.centerRight,
                                //             children: [
                                //               Container(
                                //                   margin:
                                //                       const EdgeInsetsDirectional
                                //                           .only(end: 20),
                                //                   decoration: BoxDecoration(
                                //                       color: Theme.of(context)
                                //                           .colorScheme
                                //                           .white,
                                //                       borderRadius:
                                //                           BorderRadiusDirectional
                                //                               .circular(10)),
                                //                   child: TextField(
                                //                     textDirection:
                                //                         Directionality.of(
                                //                             context),
                                //                     enabled: false,
                                //                     controller: promoC,
                                //                     readOnly: true,
                                //                     style: Theme.of(context)
                                //                         .textTheme
                                //                         .titleMedium,
                                //                     decoration: InputDecoration(
                                //                       contentPadding:
                                //                           EdgeInsets.symmetric(
                                //                               horizontal: 10),
                                //                       border: InputBorder.none,
                                //                       //isDense: true,
                                //                       hintText: getTranslated(
                                //                               context,
                                //                               'PROMOCODE_LBL') ??
                                //                           '',
                                //                     ),
                                //                   )),
                                //               Positioned.directional(
                                //                 textDirection:
                                //                     Directionality.of(context),
                                //                 end: 0,
                                //                 child: Container(
                                //                     padding: EdgeInsets.all(11),
                                //                     decoration: BoxDecoration(
                                //                       shape: BoxShape.circle,
                                //                       color: dynamicColor
                                //                           .buttonColor,
                                //                     ),
                                //                     child: Icon(
                                //                       Icons.arrow_forward,
                                //                       color: dynamicColor
                                //                           .buttonTxtColor,
                                //                     )),
                                //               ),
                                //             ],
                                //           ),
                                //           onTap: promoSheet,
                                //         ),
                                //       )
                                //     : Container(),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 5),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      getTranslated(context,
                                                          'TOTAL_PRICE')!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                              fontFamily:
                                                                  dynamicFontFamily
                                                                      .fontFamily),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          CUR_CURRENCY! +
                                                              " ${finalTotalTempTotal.toStringAsFixed(2)}",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .fontColor,
                                                                    fontFamily:
                                                                        dynamicFontFamily
                                                                            .fontFamily,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                            isPromoValid!
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        getTranslated(context,
                                                            'PROMO_CODE_DIS_LBL')!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall!
                                                            .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .lightBlack2,
                                                              fontFamily:
                                                                  dynamicFontFamily
                                                                      .fontFamily,
                                                            ),
                                                      ),
                                                      Text(
                                                        CUR_CURRENCY! +
                                                            " " +
                                                            promoAmt
                                                                .toStringAsFixed(
                                                                    2),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall!
                                                            .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .lightBlack2,
                                                              fontFamily:
                                                                  dynamicFontFamily
                                                                      .fontFamily,
                                                            ),
                                                      )
                                                    ],
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: SimBtn(
                                        size: 0.9,
                                        title: getTranslated(
                                            context, 'PROCEED_CHECKOUT'),
                                        onBtnSelected: () async {
                                          bool outOfStock = false;
                                          for (var item in cartList) {
                                            if (item.productList![0]
                                                    .availability ==
                                                "0") {
                                              outOfStock = true;
                                              break;
                                            }
                                          }
                                          if (outOfStock) {
                                            setSnackbar(
                                              'Some of products are out of stock. Add these product in save in later or remove from cart..!',
                                              _checkscaffoldKey,
                                            );
                                          } else {
                                            _getCart("");
                                            checkout(cartList);
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                )
                              ]),
                        )
                      : !_isSaveForLaterVisible && cartList.isNotEmpty
                          ? Container(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    // promoList.length > 0 && oriPrice > 0
                                    //     ? Padding(
                                    //         padding: const EdgeInsets.symmetric(
                                    //             horizontal: 10.0),
                                    //         child: InkWell(
                                    //           child: Stack(
                                    //             alignment:
                                    //                 Alignment.centerRight,
                                    //             children: [
                                    //               Container(
                                    //                   margin:
                                    //                       const EdgeInsetsDirectional
                                    //                           .only(end: 20),
                                    //                   decoration: BoxDecoration(
                                    //                       color:
                                    //                           Theme.of(context)
                                    //                               .colorScheme
                                    //                               .white,
                                    //                       borderRadius:
                                    //                           BorderRadiusDirectional
                                    //                               .circular(
                                    //                                   10)),
                                    //                   child: TextField(
                                    //                     textDirection:
                                    //                         Directionality.of(
                                    //                             context),
                                    //                     enabled: false,
                                    //                     controller: promoC,
                                    //                     readOnly: true,
                                    //                     style: Theme.of(context)
                                    //                         .textTheme
                                    //                         .titleMedium,
                                    //                     decoration:
                                    //                         InputDecoration(
                                    //                       contentPadding:
                                    //                           EdgeInsets
                                    //                               .symmetric(
                                    //                                   horizontal:
                                    //                                       10),
                                    //                       border:
                                    //                           InputBorder.none,
                                    //                       //isDense: true,
                                    //                       hintText: getTranslated(
                                    //                               context,
                                    //                               'PROMOCODE_LBL') ??
                                    //                           '',
                                    //                     ),
                                    //                   )),
                                    //               Positioned.directional(
                                    //                 textDirection:
                                    //                     Directionality.of(
                                    //                         context),
                                    //                 end: 0,
                                    //                 child: Container(
                                    //                     padding:
                                    //                         EdgeInsets.all(11),
                                    //                     decoration:
                                    //                         BoxDecoration(
                                    //                       shape:
                                    //                           BoxShape.circle,
                                    //                       color: dynamicColor
                                    //                           .buttonColor,
                                    //                     ),
                                    //                     child: Icon(
                                    //                       Icons.arrow_forward,
                                    //                       color: dynamicColor
                                    //                           .buttonTxtColor,
                                    //                     )),
                                    //               ),
                                    //             ],
                                    //           ),
                                    //           onTap: promoSheet,
                                    //         ),
                                    //       )
                                    //     : Container(),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                            ),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 5),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          getTranslated(context,
                                                              'TOTAL_PRICE')!,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                  fontFamily:
                                                                      dynamicFontFamily
                                                                          .fontFamily),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              CUR_CURRENCY! +
                                                                  " ${finalTotalTempTotal.toStringAsFixed(2)}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .fontColor,
                                                                    fontFamily:
                                                                        dynamicFontFamily
                                                                            .fontFamily,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                isPromoValid!
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            getTranslated(
                                                                context,
                                                                'PROMO_CODE_DIS_LBL')!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall!
                                                                .copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .lightBlack2,
                                                                  fontFamily:
                                                                      dynamicFontFamily
                                                                          .fontFamily,
                                                                ),
                                                          ),
                                                          Text(
                                                            CUR_CURRENCY! +
                                                                " " +
                                                                promoAmt
                                                                    .toStringAsFixed(
                                                                        2),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall!
                                                                .copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .lightBlack2,
                                                                  fontFamily:
                                                                      dynamicFontFamily
                                                                          .fontFamily,
                                                                ),
                                                          )
                                                        ],
                                                      )
                                                    : Container(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: SimBtn(
                                            size: 0.9,
                                            title: getTranslated(
                                                context, 'PROCEED_CHECKOUT'),
                                            onBtnSelected: () async {
                                              bool outOfStock = false;
                                              for (var item in cartList) {
                                                if (item.productList![0]
                                                        .availability ==
                                                    "0") {
                                                  outOfStock = true;
                                                  break;
                                                }
                                              }
                                              if (outOfStock) {
                                                setSnackbar(
                                                  'Some of products are out of stock. Add these product in save in later or remove from cart..!',
                                                  _checkscaffoldKey,
                                                );
                                              } else {
                                                _getCart("");
                                                checkout(cartList);
                                              }
                                            },
                                          ),
                                        )
                                      ],
                                    )
                                  ]),
                            )
                          : SizedBox.shrink()
                ],
              );
  }

  cartEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noCartImage(context),
          noCartText(context),
          noCartDec(context),
          shopNow()
        ]),
      ),
    );
  }

  getAllPromo() {}

  noCartImage(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/empty_cart.svg',
      fit: BoxFit.contain,
      color: colors.primary,
    );
  }

  noCartText(BuildContext context) {
    return Container(
        child: Text(getTranslated(context, 'NO_CART')!,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.normal,
                fontFamily: dynamicFontFamily.fontFamily)));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC')!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.lightBlack2,
              fontWeight: FontWeight.normal,
              fontFamily: dynamicFontFamily.fontFamily)),
    );
  }

  shopNow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28.0),
      child: CupertinoButton(
        child: Container(
            width: deviceWidth! * 0.7,
            height: 45,
            alignment: FractionalOffset.center,
            decoration: new BoxDecoration(
              color: colors.primary,
              // gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [colors.grad1Color, colors.grad2Color],
              //     stops: [0, 1]),
              borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
            ),
            child: Text(getTranslated(context, 'SHOP_NOW')!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white70,
                    fontFamily: dynamicFontFamily.fontFamily))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  double finalTotal = 0.0;

  double calculateTotalPromoDiscount() {
    if (promoCodes.isEmpty) return 0.0;

    return promoCodes.fold<double>(
        0.0, (sum, promo) => sum + (promo["amount"] as double));
  }

  buycheckout(List<SectionModel> cartList) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    SectionModel selectedProduct = buyNowCartList[0];
    var promoAmount = 0.0;
    var promoData = getPromoCodeForProduct(selectedProduct.id);

    if (promoData != null) {
      promoAmount = promoData?["amount"];
    }

    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 1,
              child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                checkoutState = setState;
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    key: _checkscaffoldKey,
                    body: _isNetworkAvail
                        ? buyNowCartList.length == 0
                            ? cartEmpty()
                            : _isLoading
                                ? shimmer(context)
                                : Column(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: <Widget>[
                                            SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: 20),
                                                    Image.asset(
                                                      "assets/images/ordersummarymain.png",
                                                      height: 150,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    SizedBox(height: 10),
                                                    address(),
                                                    buycartItems(
                                                        buyNowCartList),
                                                    buyorderSummary(
                                                        buyNowCartList),
                                                    SizedBox(height: 80),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Selector<CartProvider, bool>(
                                              builder: (context, data, child) {
                                                return showCircularProgress(
                                                    data, colors.primary);
                                              },
                                              selector: (_, provider) =>
                                                  provider.isProgress,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.only(
                                          left: 15.0,
                                          right: 15.0,
                                          top: 12.0,
                                          bottom: MediaQuery.of(context)
                                                  .viewPadding
                                                  .bottom +
                                              12.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    () {
                                                      double productTotal = 0.0;
                                                      double productTax = 0.0;
                                                      double deliveryCharge =
                                                          dCharge?.toDouble() ??
                                                              0.0;
                                                      double promoDiscount =
                                                          (isPromoValid == true)
                                                              ? promoAmt
                                                              : 0.0;
                                                      double walletDeduction =
                                                          (isUseWallet == true)
                                                              ? usedBal
                                                              : 0.0;

                                                      if (buyNowCartList
                                                          .isNotEmpty) {
                                                        int selectedPos = 0;
                                                        for (int i = 0;
                                                            i <
                                                                selectedProduct
                                                                    .productList![
                                                                        0]
                                                                    .prVarientList!
                                                                    .length;
                                                            i++) {
                                                          if (selectedProduct
                                                                  .varientId ==
                                                              selectedProduct
                                                                  .productList![
                                                                      0]
                                                                  .prVarientList![
                                                                      i]
                                                                  .id) {
                                                            selectedPos = i;
                                                            break;
                                                          }
                                                        }
                                                        double price = double
                                                            .parse(selectedProduct
                                                                .productList![0]
                                                                .prVarientList![
                                                                    selectedPos]
                                                                .disPrice!);
                                                        if (price == 0) {
                                                          price = double.parse(
                                                              selectedProduct
                                                                  .productList![
                                                                      0]
                                                                  .prVarientList![
                                                                      selectedPos]
                                                                  .price!);
                                                        }
                                                        int quantity =
                                                            int.parse(
                                                                selectedProduct
                                                                    .qty!);
                                                        productTotal =
                                                            price * quantity;
                                                        double taxRate = double
                                                            .parse(selectedProduct
                                                                    .productList![
                                                                        0]
                                                                    .tax ??
                                                                '0');
                                                        productTax =
                                                            (productTotal *
                                                                    taxRate) /
                                                                100;
                                                      }
                                                      finalTotal =
                                                          productTotal +
                                                              deliveryCharge -
                                                              promoDiscount -
                                                              walletDeduction -
                                                              promoAmount;
                                                      return CUR_CURRENCY! +
                                                          " " +
                                                          finalTotal
                                                              .toStringAsFixed(
                                                                  2);
                                                    }(),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily:
                                                          dynamicFontFamily
                                                              .fontFamily,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.0),
                                                  Text(
                                                    buyNowCartList.length
                                                            .toString() +
                                                        " Item",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor
                                                          .withOpacity(0.7),
                                                      fontSize: 13.0,
                                                      fontFamily:
                                                          dynamicFontFamily
                                                              .fontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12.0),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.35,
                                              height: 42.0,
                                              child: ElevatedButton(
                                                onPressed: _placeOrder
                                                    ? () {
                                                        getSetting();
                                                        msg = getTranslated(
                                                            context, 'Seller');

                                                        print(
                                                            "selAddress cart $selAddress");

                                                        if (selAddress ==
                                                                null ||
                                                            selAddress!
                                                                .isEmpty) {
                                                          msg = getTranslated(
                                                              context,
                                                              'addressWarning');
                                                          Navigator
                                                              .pushReplacement(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  ManageAddress(
                                                                      home:
                                                                          false),
                                                            ),
                                                          );
                                                          checkoutState!(() {
                                                            _placeOrder = true;
                                                          });
                                                        } else if (double.parse(
                                                                MIN_ALLOW_CART_AMT!) >
                                                            oriPrice) {
                                                          setSnackbar(
                                                            "${getTranslated(context, 'MIN_CART_AMT')!} \u{20B9}${MIN_ALLOW_CART_AMT}",
                                                            _checkscaffoldKey,
                                                          );
                                                        } else if (payMethod ==
                                                                null ||
                                                            payMethod!
                                                                .isEmpty) {
                                                          msg = getTranslated(
                                                              context,
                                                              'payWarning');
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  Payment(
                                                                      updateCheckout,
                                                                      msg),
                                                            ),
                                                          );
                                                          checkoutState!(() {
                                                            _placeOrder = true;
                                                          });
                                                        } else {
                                                          checkoutState!(() {
                                                            _placeOrder = false;
                                                          });
                                                          doPayment();
                                                        }
                                                      }
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      dynamicColor.buttonColor,
                                                  foregroundColor:
                                                      colors.whiteTemp,
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                                ),
                                                child: Text(
                                                  'Place Order',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13.0,
                                                      color: dynamicColor
                                                          .buttonTxtColor,
                                                      fontFamily:
                                                          dynamicFontFamily
                                                              .fontFamily),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                        : noInternet(context),
                  ),
                );
              }),
            ),
          );
        }).then((value) {
      // Clear buy now data when modal closes
      buyNowCartList.clear();
      buyNowSelectedIndex = -1;
      clearAll();
      _getCart('0');
    });
  }

  checkout(List<SectionModel> cartList) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    var totalProductPromosAmount = calculateTotalPromoDiscount();

    var promoAmtTemp = 0.0;

    if (isPromoValid == true) {
      promoAmtTemp = promoAmt;
    }

    // Calculate final total
    double finalTotalTemp =
        oriPrice - promoAmtTemp - totalProductPromosAmount + dCharge;

    totalamount = finalTotalTemp.toStringAsFixed(2);

    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 1,
              child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                checkoutState = setState;
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    key: _checkscaffoldKey,
                    body: _isNetworkAvail
                        ? cartList.length == 0
                            ? cartEmpty()
                            : _isLoading
                                ? shimmer(context)
                                : Column(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: <Widget>[
                                            SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: 20),
                                                    Image.asset(
                                                      "assets/images/ordersummarymain.png",
                                                      height: 150,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    SizedBox(height: 10),
                                                    address(),
                                                    // payment(),
                                                    cartItems(cartList),
                                                    orderSummary(cartList),
                                                    SizedBox(height: 80),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Selector<CartProvider, bool>(
                                              builder: (context, data, child) {
                                                return showCircularProgress(
                                                    data, colors.primary);
                                              },
                                              selector: (_, provider) =>
                                                  provider.isProgress,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.only(
                                          left: 15.0,
                                          right: 15.0,
                                          top: 12.0,
                                          bottom: MediaQuery.of(context)
                                                  .viewPadding
                                                  .bottom +
                                              12.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    CUR_CURRENCY! +
                                                        "${finalTotalTemp.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16.0,
                                                        fontFamily:
                                                            dynamicFontFamily
                                                                .fontFamily),
                                                  ),
                                                  SizedBox(height: 2.0),
                                                  Text(
                                                    cartList.length.toString() +
                                                        " Items",
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .fontColor
                                                            .withOpacity(0.7),
                                                        fontSize: 13.0,
                                                        fontFamily:
                                                            dynamicFontFamily
                                                                .fontFamily),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12.0),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.35,
                                              height: 42.0,
                                              child: ElevatedButton(
                                                onPressed: _placeOrder
                                                    ? () {
                                                        getSetting();
                                                        msg = getTranslated(
                                                            context, 'Seller');

                                                        print(
                                                            "=cart price======${oriPrice}============range price====${MIN_ALLOW_CART_AMT}");

                                                        if (selAddress ==
                                                                null ||
                                                            selAddress!
                                                                .isEmpty) {
                                                          msg = getTranslated(
                                                              context,
                                                              'addressWarning');
                                                          Navigator
                                                              .pushReplacement(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  ManageAddress(
                                                                      home:
                                                                          false),
                                                            ),
                                                          );
                                                          checkoutState!(() {
                                                            _placeOrder = true;
                                                          });
                                                        } else if (double.parse(
                                                                MIN_ALLOW_CART_AMT!) >
                                                            oriPrice) {
                                                          print(
                                                              "=cart price======${oriPrice}============range price====${MIN_ALLOW_CART_AMT}");
                                                          setSnackbar(
                                                            "${getTranslated(context, 'MIN_CART_AMT')!} \u{20B9}${MIN_ALLOW_CART_AMT}",
                                                            _checkscaffoldKey,
                                                          );
                                                        } else if (payMethod ==
                                                                null ||
                                                            payMethod!
                                                                .isEmpty) {
                                                          msg = getTranslated(
                                                              context,
                                                              'payWarning');
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  Payment(
                                                                      updateCheckout,
                                                                      msg),
                                                            ),
                                                          );
                                                          checkoutState!(() {
                                                            _placeOrder = true;
                                                          });
                                                        } else {
                                                          checkoutState!(() {
                                                            _placeOrder = false;
                                                          });
                                                          totalamount =
                                                              finalTotalTemp
                                                                  .toStringAsFixed(
                                                                      2);

                                                          doPayment();

                                                          // confirmDialog();
                                                        }
                                                      }
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      dynamicColor.buttonColor,
                                                  foregroundColor:
                                                      colors.whiteTemp,
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                                ),
                                                child: Text(
                                                  'Place Order',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13.0,
                                                      color: dynamicColor
                                                          .buttonTxtColor,
                                                      fontFamily:
                                                          dynamicFontFamily
                                                              .fontFamily),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                        : noInternet(context),
                  ),
                );
              }),
            ),
          );
        }).then((value) {
      clearAll();
      _getCart('0');
    });
  }

  doPayment() {
    if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
      placeOrder('');
    } else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
      razorpayPayment();
    else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
      flutterwavePayment();
    else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
      razorpayPayment();
    else if (payMethod == getTranslated(context, 'BANKTRAN'))
      bankTransfer();
    else
      placeOrder('');
  }

  Future<void> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(getAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          // String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            addressList = (data as List)
                .map((data) => new User.fromAddress(data))
                .toList();

            if (addressList.length == 1) {
              selectedAddress = 0;
              selAddress = addressList[0].id;
              // if (ISFLAT_DEL) {
              //   if (totalPrice < double.parse(addressList[0].freeAmt!))
              //     delCharge = double.parse(addressList[0].deliveryCharge!);
              //   else
              //     delCharge = 0;
              // }
            } else {
              for (int i = 0; i < addressList.length; i++) {
                if (addressList[i].isDefault == "1") {
                  selectedAddress = i;
                  selAddress = addressList[i].id;

                  // if (!ISFLAT_DEL) {
                  //   // if (totalPrice < double.parse(addressList[i].freeAmt!))
                  //     delCharge = double.parse(addressList[i].deliveryCharge!);
                  //   else
                  //     delCharge = 0;
                  // }
                }
              }
            }

            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!))
                delCharge = double.parse(CUR_DEL_CHR!);
              else
                delCharge = 0;
            }
            totalPrice = totalPrice + delCharge;
          } else {
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!))
                delCharge = double.parse(CUR_DEL_CHR!);
              else
                delCharge = 0;
            }
            totalPrice = totalPrice + delCharge;
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          if (checkoutState != null) checkoutState!(() {});
        } else {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          if (mounted)
            setState(() {
              _isLoading = false;
            });
        }
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    placeOrder(response.paymentId);

    /// {aySucess
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    var getdata = json.decode(response.message!);
    String errorMsg = getdata["error"]["description"];
    setSnackbar(errorMsg, _checkscaffoldKey);

    if (mounted)
      checkoutState!(() {
        _placeOrder = true;
      });
    context.read<CartProvider>().setProgress(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  updateCheckout() {
    if (mounted) checkoutState!(() {});
  }

  razorpayPayment() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(this.context, listen: false);
    print("Payment Email ${settingsProvider.email}");
    print("Payment Email ${settingsProvider.mobile}");
    print("Payment Email ${settingsProvider.mobile}");
    String? contact = settingsProvider.mobile;
    // String? email = settingsProvider.email;

    String amt =
        ((double.parse(totalamount!.toString().replaceAll(",", ""))) * 100)
            .toStringAsFixed(2);

    if (contact != '') {
      context.read<CartProvider>().setProgress(true);

      checkoutState!(() {});
      var options = {
        // 'key': razorpayId, //rzp_test_1DP5mmOlF5G5ag
        'key': 'rzp_test_1DP5mmOlF5G5ag',
        'amount': "$amt",
        'name': 'Place Order',
        'prefill': {CONTACT: contact},
      };

      print("options $options");

      try {
        _razorpay!.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      // if (email == '')
      //   setSnackbar(getTranslated(context, 'emailWarning')!, _checkscaffoldKey);
      if (contact == '')
        setSnackbar(getTranslated(context, 'phoneWarning')!, _checkscaffoldKey);
    }
  }

  // Future<void> placeOrder(String? tranId) async {
  //   _isNetworkAvail = await isNetworkAvailable();
  //   if (_isNetworkAvail) {
  //     context.read<CartProvider>().setProgress(true);
  //     SettingProvider settingsProvider =
  //         Provider.of<SettingProvider>(this.context, listen: false);
  //
  //     String? mob = settingsProvider.mobile;
  //     String? varientId, quantity;
  //
  //     List<SectionModel> cartList = context.read<CartProvider>().cartList;
  //     for (SectionModel sec in cartList) {
  //       varientId = varientId != null
  //           ? varientId + "," + sec.varientId!
  //           : sec.varientId;
  //       quantity = quantity != null ? quantity + "," + sec.qty! : sec.qty;
  //     }
  //     String? payVia;
  //     if (payMethod == getTranslated(context, 'COD_LBL'))
  //       payVia = "COD";
  //     else if (payMethod == getTranslated(context, 'PAYPAL_LBL'))
  //       payVia = "PayPal";
  //     else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL'))
  //       payVia = "PayUMoney";
  //     else if (payMethod == getTranslated(context, 'RAZORPAY_LBL') ||
  //         "Phonepe" == getTranslated(context, 'RAZORPAY_LBL'))
  //       payVia = "Phonepe";
  //     else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
  //       payVia = "Paystack";
  //     else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
  //       payVia = "Flutterwave";
  //     else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
  //       payVia = "Stripe";
  //     else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
  //       payVia = "Paytm";
  //     else if (payMethod == "Wallet")
  //       payVia = "Wallet";
  //     else if (payMethod == getTranslated(context, 'BANKTRAN'))
  //       payVia = "bank_transfer";
  //     try {
  //       var parameter = {
  //         USER_ID: CUR_USERID,
  //         MOBILE: mob,
  //         PRODUCT_VARIENT_ID: varientId,
  //         QUANTITY: quantity,
  //         TOTAL: oriPrice.toString(),
  //         FINAL_TOTAL: totalPrice.toString(),
  //         DEL_CHARGE: dCharge.toString(),
  //         // TAX_AMT: taxAmt.toString(),
  //         TAX_PER: taxAmount.toString(),
  //         PAYMENT_METHOD: payVia,
  //         ADD_ID: selAddress,
  //         ISWALLETBALUSED: isUseWallet! ? "1" : "0",
  //         WALLET_BAL_USED: usedBal.toString(),
  //         ORDER_NOTE: noteC.text
  //       };
  //
  //       if (isTimeSlot!) {
  //         parameter[DELIVERY_TIME] = selTime ?? 'Anytime';
  //         parameter[DELIVERY_DATE] = selDate ?? '';
  //       }
  //       if (isPromoValid!) {
  //         parameter[PROMOCODE] = promocode;
  //         parameter[PROMO_DIS] = promoAmt.toString();
  //       }
  //
  //       if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
  //         parameter[ACTIVE_STATUS] = WAITING;
  //       } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
  //         if (tranId == "succeeded")
  //           parameter[ACTIVE_STATUS] = PLACED;
  //         else
  //           parameter[ACTIVE_STATUS] = WAITING;
  //       } else if (payMethod == getTranslated(context, 'BANKTRAN')) {
  //         parameter[ACTIVE_STATUS] = WAITING;
  //       }
  //       print(parameter.toString());
  //       // print("PLACE ORDER PARAMETER====${parameter}");
  //       // print("PLACE ORDER PARAMETER==== ${headers}");
  //       // print("PLACE ORDER PARAMETER==== ${placeOrderApi}");
  //
  //       Response response =
  //           await post(placeOrderApi, body: parameter, headers: headers)
  //               .timeout(Duration(seconds: timeOut));
  //       // print(placeOrderApi.toString());
  //       // print(parameter.toString());
  //       _placeOrder = true;
  //       if (response.statusCode == 200) {
  //         var getdata = json.decode(response.body);
  //         bool error = getdata["error"];
  //         String? msg = getdata["message"];
  //         if (!error) {
  //           String orderId = getdata["order_id"].toString();
  //           if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
  //             addTransaction(tranId, orderId, SUCCESS, msg, true);
  //           } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
  //             paypalPayment(orderId);
  //           } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
  //             addTransaction(stripePayId, orderId,
  //                 tranId == "succeeded" ? PLACED : WAITING, msg, true);
  //           } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
  //             addTransaction(tranId, orderId, SUCCESS, msg, true);
  //           } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
  //             addTransaction(tranId, orderId, SUCCESS, msg, true);
  //           } else {
  //             context.read<UserProvider>().setCartCount("0");
  //
  //             clearAll();
  //
  //             Navigator.pushAndRemoveUntil(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (BuildContext context) => OrderSuccess()),
  //                 ModalRoute.withName('/home'));
  //           }
  //         } else {
  //           setSnackbar(msg!, _checkscaffoldKey);
  //           context.read<CartProvider>().setProgress(false);
  //         }
  //       }
  //     } on TimeoutException catch (_) {
  //       if (mounted)
  //         checkoutState!(() {
  //           _placeOrder = true;
  //         });
  //       context.read<CartProvider>().setProgress(false);
  //     }
  //   } else {
  //     if (mounted)
  //       checkoutState!(() {
  //         _isNetworkAvail = false;
  //       });
  //   }
  // }
  Future<void> placeOrder(String? tranId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      context.read<CartProvider>().setProgress(true);
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(this.context, listen: false);

      String? mob = settingsProvider.mobile;
      String? varientId, quantity;
      List<SectionModel> cartList;
      bool isBuyNow = buyNowCartList.isNotEmpty && buyNowSelectedIndex != -1;

      if (isBuyNow) {
        cartList = buyNowCartList;
        print("BUY NOW ORDER - Products: ${cartList.length}");
      } else {
        // Regular Cart - use all cart products
        cartList = context.read<CartProvider>().cartList;
        print("REGULAR CART ORDER - Products: ${cartList.length}");
      }
      for (SectionModel sec in cartList) {
        varientId = varientId != null
            ? varientId + "," + sec.varientId!
            : sec.varientId;
        quantity = quantity != null ? quantity + "," + sec.qty! : sec.qty;
      }

      String? payVia;
      if (payMethod == getTranslated(context, 'COD_LBL'))
        payVia = "COD";
      else if (payMethod == getTranslated(context, 'PAYPAL_LBL'))
        payVia = "PayPal";
      else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL'))
        payVia = "PayUMoney";
      else if (payMethod == getTranslated(context, 'RAZORPAY_LBL') ||
          "Phonepe" == getTranslated(context, 'RAZORPAY_LBL'))
        payVia = "Phonepe";
      else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
        payVia = "Paystack";
      else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
        payVia = "Flutterwave";
      else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
        payVia = "Stripe";
      else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
        payVia = "Paytm";
      else if (payMethod == "Wallet")
        payVia = "Wallet";
      else if (payMethod == getTranslated(context, 'BANKTRAN'))
        payVia = "bank_transfer";

      try {
        double calculatedFinalTotal;
        if (isBuyNow) {
          calculatedFinalTotal = finalTotal;
        } else {
          calculatedFinalTotal = totalPrice;
        }

        var parameter = {
          USER_ID: CUR_USERID,
          MOBILE: mob,
          PRODUCT_VARIENT_ID: varientId,
          QUANTITY: quantity,
          TOTAL: oriPrice.toString(),
          FINAL_TOTAL: calculatedFinalTotal.toString(),
          DEL_CHARGE: dCharge.toString(),
          TAX_PER: taxAmount.toString(),
          PAYMENT_METHOD: payVia,
          ADD_ID: selAddress,
          ISWALLETBALUSED: isUseWallet! ? "1" : "0",
          WALLET_BAL_USED: usedBal.toString(),
          ORDER_NOTE: noteC.text,
          // "promo_codes": promoCodes,
          "promo_codes":
              promoCodes is List ? jsonEncode(promoCodes) : promoCodes ?? "",
        };

        print("ppppspsps $parameter");

        if (isTimeSlot!) {
          parameter[DELIVERY_TIME] = selTime ?? 'Anytime';
          parameter[DELIVERY_DATE] = selDate ?? '';
        }
        if (isPromoValid!) {
          parameter[PROMOCODE] = promocode;
          parameter[PROMO_DIS] = promoAmt.toString();
        }

        if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
          parameter[ACTIVE_STATUS] = WAITING;
        } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
          if (tranId == "succeeded")
            parameter[ACTIVE_STATUS] = PLACED;
          else
            parameter[ACTIVE_STATUS] = WAITING;
        } else if (payMethod == getTranslated(context, 'BANKTRAN')) {
          parameter[ACTIVE_STATUS] = WAITING;
        }

        print("ppppspsps $parameter");

        print("ORDER TYPE: ${isBuyNow ? 'BUY NOW' : 'REGULAR CART'}");
        print("PLACE ORDER PARAMETER: ${parameter}");
        print("Product Variant IDs: $varientId");
        print("Quantities: $quantity");

        Response response =
            await post(placeOrderApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        _placeOrder = true;
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            String orderId = getdata["order_id"].toString();
            if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
              paypalPayment(orderId);
            } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
              addTransaction(stripePayId, orderId,
                  tranId == "succeeded" ? PLACED : WAITING, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else {
              context.read<UserProvider>().setCartCount("0");
              clearAll();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => OrderSuccess()),
                  ModalRoute.withName('/home'));
            }
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        if (mounted)
          checkoutState!(() {
            _placeOrder = true;
          });
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderId,
        AMOUNT: totalPrice.toString()
      };
      Response response =
          await post(paypalTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        String? data = getdata["data"];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => PaypalWebview(
                      url: data,
                      from: "order",
                      orderId: orderId,
                    )));
      } else {
        setSnackbar(msg!, _checkscaffoldKey);
      }
      context.read<CartProvider>().setProgress(false);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
    }
  }

  Future<void> addTransaction(String? tranId, String orderID, String? status,
      String? msg, bool redirect) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderID,
        TYPE: payMethod,
        TXNID: tranId,
        AMOUNT: totalPrice.toString(),
        STATUS: status,
        MSG: msg
      };
      Response response =
          await post(addTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg1 = getdata["message"];
      if (!error) {
        if (redirect) {
          // CUR_CART_COUNT = "0";

          context.read<UserProvider>().setCartCount("0");
          clearAll();

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => OrderSuccess()),
              ModalRoute.withName('/home'));
        }
      } else {
        setSnackbar(msg1!, _checkscaffoldKey);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
    }
  }

  address() {
    return Card(
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.location_on),
                Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      getTranslated(context, 'SHIPPING_DETAIL') ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontFamily: dynamicFontFamily.fontFamily),
                    )),
              ],
            ),
            Divider(),
            addressList.length > 0
                ? InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => ManageAddress(
                            home: false,
                          ),
                        ),
                      ).then((value) {
                        Navigator.pop(context);
                      });
                      checkoutState!(() {
                        deliverable = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                addressList[selectedAddress!].name!,
                                style: TextStyle(
                                    fontFamily: dynamicFontFamily.fontFamily),
                              )),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  getTranslated(context, 'CHANGE')!,
                                  style: TextStyle(
                                      color: colors.primary,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              [
                                addressList[selectedAddress!]?.address ?? "",
                                addressList[selectedAddress!]?.area ?? "",
                                addressList[selectedAddress!]?.city ?? "",
                                addressList[selectedAddress!]?.state ?? "",
                                addressList[selectedAddress!]?.country ?? "",
                                addressList[selectedAddress!]?.pincode ?? "",
                                addressList[selectedAddress!]?.landmark ?? "",
                                addressList[selectedAddress!]?.altMob ?? "",
                              ]
                                  .where((element) => element.isNotEmpty)
                                  .join(", "),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontFamily: dynamicFontFamily.fontFamily,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              children: [
                                Text(
                                  addressList[selectedAddress!].mobile!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: InkWell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          getTranslated(context, 'ADDADDRESS')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontFamily: dynamicFontFamily.fontFamily),
                        ),
                      ),
                      onTap: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddAddress(
                                    update: false,
                                    index: addressList.length,
                                  )),
                        ).then((value) {
                          print("object");
                          Navigator.pop(context);
                        });
                        if (mounted) setState(() {});
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  payment() {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          msg = '';
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      Payment(updateCheckout, msg)));
          if (mounted) checkoutState!(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.payment),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      getTranslated(context, 'SELECT_PAYMENT')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: dynamicFontFamily.fontFamily),
                    ),
                  )
                ],
              ),
              payMethod != null && payMethod != ''
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text(
                            payMethod!,
                            style: TextStyle(
                                fontFamily: dynamicFontFamily.fontFamily),
                          )
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buycartItems(List<SectionModel> cartList) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartList.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return buycartItem(index, cartList);
      },
    );
  }

  cartItems(List<SectionModel> cartList) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartList.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return cartItem(index, cartList);
      },
    );
  }

  Widget buyorderSummary(List<SectionModel> cartList) {
    // Calculate values specifically for the selected product
    double singleProductTotal = 0.0;
    double singleProductTax = 0.0;
    double singleProductCGST = 0.0;
    double singleProductSGST = 0.0;
    double deliveryCharge = dCharge?.toDouble() ?? 0.0;
    double promoDiscount = (isPromoValid == true) ? promoAmt : 0.0;
    double walletDeduction = (isUseWallet == true) ? usedBal : 0.0;

    var promoAmount = 0.0;

    if (cartList.isNotEmpty) {
      // Get the selected product details
      SectionModel selectedProduct = cartList[0]; // Single product in buy now
      int selectedPos = 0;

      var promoData = getPromoCodeForProduct(selectedProduct.id);

      if (promoData != null) {
        promoAmount = promoData?["amount"];
      }

      // Find correct variant position
      for (int i = 0;
          i < selectedProduct.productList![0].prVarientList!.length;
          i++) {
        if (selectedProduct.varientId ==
            selectedProduct.productList![0].prVarientList![i].id) {
          selectedPos = i;
          break;
        }
      }

      // Calculate product price
      double price = double.parse(selectedProduct
          .productList![0].prVarientList![selectedPos].disPrice!);
      if (price == 0) {
        price = double.parse(
            selectedProduct.productList![0].prVarientList![selectedPos].price!);
      }

      // Calculate totals for single product
      int quantity = int.parse(selectedProduct.qty!);
      singleProductTotal = price * quantity;

      // Calculate tax for single product
      double taxRate = double.parse(selectedProduct.productList![0].tax ?? '0');
      singleProductTax = (singleProductTotal * taxRate) / 100;

      // Calculate CGST and SGST (usually half of total tax each)
      singleProductCGST = singleProductTax / 2;
      singleProductSGST = singleProductTax / 2;
    }

    // Calculate final total
    double finalTotal =
        singleProductTotal + deliveryCharge - walletDeduction - promoAmount;

    totalPrice = finalTotal + delCharge;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslated(context, 'ORDER_SUMMARY')! +
                  " (" +
                  cartList.length.toString() +
                  " item)", // Changed to singular
              style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: dynamicFontFamily.fontFamily),
            ),
            Divider(),

            // Product Details
            if (cartList.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(8),
                        //   child: CachedNetworkImage(
                        //     imageUrl: cartList[0].productList![0].image!,
                        //     width: 60,
                        //     height: 60,
                        //     fit: BoxFit.cover,
                        //     placeholder: (context, url) => Container(
                        //       width: 60,
                        //       height: 60,
                        //       color: Colors.grey[300],
                        //       child: Icon(Icons.image, color: Colors.grey[600]),
                        //     ),
                        //     errorWidget: (context, url, error) => Container(
                        //       width: 60,
                        //       height: 60,
                        //       color: Colors.grey[300],
                        //       child: Icon(Icons.error, color: Colors.grey[600]),
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   cartList[0].productList![0].name!,
                              //   style: TextStyle(
                              //     fontWeight: FontWeight.w500,
                              //     fontSize: 14,
                              //   ),
                              //   maxLines: 2,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                              // SizedBox(height: 4),
                              // Text(
                              //   "Quantity: ${cartList[0].qty}",
                              //   style: TextStyle(
                              //     color: Theme.of(context)
                              //         .colorScheme
                              //         .onSurface
                              //         .withOpacity(0.7),
                              //     fontSize: 12,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20),
                  ],
                ),
              ),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'SUBTOTAL')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2,
                      fontFamily: dynamicFontFamily.fontFamily),
                ),
                Text(
                  CUR_CURRENCY! +
                      " " +
                      (singleProductTotal - promoAmount).toStringAsFixed(2),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: dynamicFontFamily.fontFamily),
                )
              ],
            ),

            // CGST
            if (singleProductCGST > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CGST',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + singleProductCGST.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),

            // SGST
            if (singleProductSGST > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SGST',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + singleProductSGST.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),

            // Delivery Charge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'DELIVERY_CHARGE')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2,
                      fontFamily: dynamicFontFamily.fontFamily),
                ),
                Text(
                  CUR_CURRENCY! + " " + deliveryCharge.toStringAsFixed(2),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: dynamicFontFamily.fontFamily),
                )
              ],
            ),

            // Promo Discount (if applicable)
            if (isPromoValid == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    "- " +
                        CUR_CURRENCY! +
                        " " +
                        promoDiscount.toStringAsFixed(2),
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),

            // Wallet Balance (if used)
            if (isUseWallet == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'WALLET_BAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    "- " +
                        CUR_CURRENCY! +
                        " " +
                        walletDeduction.toStringAsFixed(2),
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),

            Divider(height: 20),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'TOTAL_PRICE') ?? 'Total Amount',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: dynamicFontFamily.fontFamily),
                ),
                Text(
                  CUR_CURRENCY! + " " + totalPrice.toStringAsFixed(2),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: dynamicFontFamily.fontFamily),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buycartItem(int index, List<SectionModel> cartList) {
    if (cartList.isEmpty || index >= cartList.length) {
      return Container();
    }

    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) {
        selectedPos = i;
      }
    }

    double price = double.tryParse(cartList[index]
                .productList?[0]
                .prVarientList?[selectedPos]
                .disPrice ??
            "0") ??
        0;
    if (price == 0) {
      price = double.tryParse(cartList[index]
                  .productList?[0]
                  .prVarientList?[selectedPos]
                  .price ??
              "0") ??
          0;
    }

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        (price * double.tryParse(cartList[index].qty ?? "0")!).toString();

    while (_controller.length <= index) {
      _controller.add(TextEditingController());
    }
    _controller[index].text = cartList[index].qty ?? "0";

    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        null) {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }

    var promoData = getPromoCodeForProduct(cartList[index].id);

    var itemTotal = double.parse(cartList[index].perItemTotal!);

    if (promoData != null) {
      itemTotal = itemTotal - promoData?["amount"];
    }

    return InkWell(
      onTap: () {},
      child: Card(
        elevation: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Hero(
                    tag:
                        "buynow_${index}_${cartList[index].productList![0].id}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: CachedNetworkImage(
                        imageUrl: cartList[index].productList![0].image!,
                        height: 80.0,
                        width: 80.0,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 80.0,
                          width: 80.0,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 80.0,
                          width: 80.0,
                          color: Colors.grey[300],
                          child: Icon(Icons.error, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    cartList[index].productList![0].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack,
                                            fontFamily:
                                                dynamicFontFamily.fontFamily),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (cartList[index]
                                      .productList![0]
                                      .prVarientList![selectedPos]
                                      .attr_name !=
                                  null &&
                              cartList[index]
                                  .productList![0]
                                  .prVarientList![selectedPos]
                                  .attr_name!
                                  .isNotEmpty)
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: att.length,
                              itemBuilder: (context, attrIndex) {
                                return Row(children: [
                                  Flexible(
                                    child: Text(
                                      att[attrIndex].trim() + ":",
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack,
                                              fontFamily:
                                                  dynamicFontFamily.fontFamily),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(start: 5.0),
                                    child: Text(
                                      val[attrIndex],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack,
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  dynamicFontFamily.fontFamily),
                                    ),
                                  )
                                ]);
                              },
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (double.parse(cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .disPrice!) !=
                                        0)
                                      Flexible(
                                        child: Text(
                                          CUR_CURRENCY! +
                                              " " +
                                              double.parse(cartList[index]
                                                          .productList![0]
                                                          .prVarientList![
                                                              selectedPos]
                                                          .price! ??
                                                      "0.0")
                                                  .toStringAsFixed(2),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  fontFamily: dynamicFontFamily
                                                      .fontFamily,
                                                  letterSpacing: 0.7),
                                        ),
                                      ),
                                    Text(
                                      " " +
                                          CUR_CURRENCY! +
                                          " " +
                                          price.toStringAsFixed(2),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                    ),
                                  ],
                                ),
                              ),
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //       horizontal: 8, vertical: 4),
                              //   decoration: BoxDecoration(
                              //     border:
                              //         Border.all(color: Colors.grey.shade300),
                              //     borderRadius: BorderRadius.circular(4),
                              //   ),
                              //   child: Text(
                              //     "Qty: ${cartList[index].qty}",
                              //     style: TextStyle(
                              //         fontSize: 12,
                              //         color: Theme.of(context)
                              //             .colorScheme
                              //             .fontColor),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Divider(),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'SUBTOTAL')!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                            fontFamily: dynamicFontFamily.fontFamily),
                      ),
                      Text(
                        CUR_CURRENCY! +
                            " " +
                            double.parse(cartList[index].perItemTotal! ?? "0.0")
                                .toStringAsFixed(2),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                            fontFamily: dynamicFontFamily.fontFamily),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'TAXPER')!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                            fontFamily: dynamicFontFamily.fontFamily),
                      ),
                      Text(
                        cartList[index].productList![0].tax! + "%",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                            fontFamily: dynamicFontFamily.fontFamily),
                      ),
                    ],
                  ),
                  if (promoData != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Discount",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                              fontFamily: dynamicFontFamily.fontFamily),
                        ),
                        Text(
                          CUR_CURRENCY! +
                              " ${promoData?["amount"].toStringAsFixed(2)}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                              fontFamily: dynamicFontFamily.fontFamily),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'TOTAL_PRICE') ?? 'Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.lightBlack2,
                            fontFamily: dynamicFontFamily.fontFamily),
                      ),
                      Text(
                        CUR_CURRENCY! +
                            " " +
                            itemTotal.toStringAsFixed(2).toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.fontColor,
                            fontFamily: dynamicFontFamily.fontFamily),
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  orderSummary(List<SectionModel> cartList) {
    var totalProductPromosAmount = calculateTotalPromoDiscount();

    var promoAmtTemp = 0.0;

    if (isPromoValid == true) {
      promoAmtTemp = promoAmt;
    }

    // Calculate final total
    double finalTotalTemp =
        oriPrice - promoAmtTemp - totalProductPromosAmount + dCharge;

    totalPrice = finalTotalTemp;

    print("grg $totalPrice, $finalTotalTemp, $delCharge");

    return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_SUMMARY')! +
                    " (" +
                    cartList.length.toString() +
                    " items)",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: dynamicFontFamily.fontFamily),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        (oriPrice - totalProductPromosAmount)
                            .toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),
              if (cgstAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CGST',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontFamily: dynamicFontFamily.fontFamily),
                    ),
                    Text(
                      CUR_CURRENCY! + " " + cgstAmount.toStringAsFixed(2),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: dynamicFontFamily.fontFamily),
                    )
                  ],
                ),
              if (sgstAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SGST',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontFamily: dynamicFontFamily.fontFamily),
                    ),
                    Text(
                      CUR_CURRENCY! + " " + sgstAmount.toStringAsFixed(2),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: dynamicFontFamily.fontFamily),
                    )
                  ],
                ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Total Amount',
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.lightBlack2),
              //     ),
              //     Text(
              //       CUR_CURRENCY! + "${totalamount.toString()}" != " "
              //           ? isPromoValid == true
              //               ? (/*oriPrice - promoAmt+dCharge*/ double.parse(
              //                           totalamount ?? '0.0') -
              //                       promoAmt)
              //                   .toString()
              //               : (CUR_CURRENCY! + "${totalamount.toString()}")
              //           : "",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.fontColor,
              //           fontWeight: FontWeight.bold),
              //     ),
              //   ],
              // ),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Tax Amount',
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.lightBlack2),
              //     ),
              //     Text(
              //       CUR_CURRENCY! + " " + taxAmount.toStringAsFixed(2),
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.fontColor,
              //           fontWeight: FontWeight.bold),
              //     )
              //   ],
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'DELIVERY_CHARGE')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + dCharge.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  )
                ],
              ),
              isPromoValid == true
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                              fontFamily: dynamicFontFamily.fontFamily),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + promoAmt.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: dynamicFontFamily.fontFamily),
                        )
                      ],
                    )
                  : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                  Text(
                    CUR_CURRENCY! + finalTotalTemp.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: dynamicFontFamily.fontFamily),
                  ),
                ],
              ),

              isUseWallet!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'WALLET_BAL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                              fontFamily: dynamicFontFamily.fontFamily),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + usedBal.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: dynamicFontFamily.fontFamily),
                        )
                      ],
                    )
                  : Container(),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Total Amount',
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.lightBlack2),
              //     ),
              //     Text(
              //       CUR_CURRENCY! + "${totalamount.toString()}" != " "
              //           ? isPromoValid == true
              //               ? (/*oriPrice - promoAmt+dCharge*/ double.parse(
              //                           totalamount ?? '0.0') -
              //                       promoAmt)
              //                   .toString()
              //               : (CUR_CURRENCY! + "${totalamount.toString()}")
              //           : "",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.fontColor,
              //           fontWeight: FontWeight.bold),
              //     ),
              //   ],
              // ),
            ],
          ),
        ));
  }

  Future<void> validatePromo(bool check, productId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        if (check) {
          if (this.mounted && checkoutState != null) checkoutState!(() {});
        }
        setState(() {});
        var totalProductPromosAmount = calculateTotalPromoDiscount();

        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: (oriPrice - totalProductPromosAmount).toString(),
        };
        if (productId != 0) {
          parameter["product_id"] = productId.toString();
        }
        print('promocode:_____${parameter}______');
        Response response =
            await post(validatePromoApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            // totalPrice = double.parse(data["final_total"]) + delCharge;

            if (productId != 0) {
              promoCodes.add({
                "product_id": productId,
                "promo_code": data["promo_code"],
                "amount": double.parse(data["final_discount"])
              });
              print("added product promp");
            } else {
              print("added product promp non");
              promoAmt = double.parse(data["final_discount"]);
              promocode = data["promo_code"];
              isPromoValid = true;
            }

            setSnackbar(
                getTranslated(context, 'PROMO_SUCCESS')!, _checkscaffoldKey);
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;
            promoC.text = "";
            promoCodes.clear();
            var data = getdata["data"];

            // totalPrice = double.parse(data["final_total"]) + delCharge;

            setSnackbar(msg!, _checkscaffoldKey);
          }
          if (isUseWallet!) {
            remWalBal = 0;
            payMethod = null;
            usedBal = 0;
            isUseWallet = false;
            isPayLayShow = true;

            selectedMethod = null;
            context.read<CartProvider>().setProgress(false);
            if (mounted && check) checkoutState!(() {});
            setState(() {});
          } else {
            if (mounted && check) checkoutState!(() {});
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        if (mounted && check) checkoutState!(() {});
        setState(() {});
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      _isNetworkAvail = false;
      if (mounted && check) checkoutState!(() {});
      setState(() {});
    }
  }

  Future<void> flutterwavePayment() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          AMOUNT: totalPrice.toString(),
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(flutterwaveApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => PaypalWebview(
                          url: data,
                          from: "order",
                        )));
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
          }

          context.read<CartProvider>().setProgress(false);
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
    }
  }

  void bankTransfer() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                            child: Text(
                              getTranslated(context, 'BANKTRAN')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontFamily: dynamicFontFamily.fontFamily),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: Text(
                              getTranslated(context, 'BANK_INS')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      fontFamily: dynamicFontFamily.fontFamily),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10),
                          child: Text(
                            getTranslated(context, 'ACC_DETAIL')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'ACCNAME')! +
                                " : " +
                                acName!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'ACCNO')! + " : " + acNo!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'BANKNAME')! +
                                " : " +
                                bankName!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'BANKCODE')! +
                                " : " +
                                bankNo!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'EXTRADETAIL')! +
                                " : " +
                                exDetails!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontFamily: dynamicFontFamily.fontFamily),
                          ),
                        )
                      ]),
                  actions: <Widget>[
                    new TextButton(
                        child: Text(getTranslated(context, 'CANCEL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          checkoutState!(() {
                            _placeOrder = true;
                          });
                          Navigator.pop(context);
                        }),
                    new TextButton(
                        child: Text(getTranslated(context, 'DONE')! + "2222",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 15,
                                fontFamily: dynamicFontFamily.fontFamily,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);

                          context.read<CartProvider>().setProgress(true);

                          placeOrder('');
                        })
                  ],
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        });
  }

  Future<void> checkDeliverable() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress,
        };
        print(parameter.toString());

        Response response =
            await post(checkCartDelApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(checkCartDelApi.toString());

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        var data = getdata["data"];
        context.read<CartProvider>().setProgress(false);

        if (error) {
          deliverableList = (data as List)
              .map((data) => new Model.checkDeliverable(data))
              .toList();

          checkoutState!(() {
            deliverable = false;
            _placeOrder = true;
          });

          setSnackbar(msg!, _checkscaffoldKey);
        } else {
          deliverableList = (data as List)
              .map((data) => new Model.checkDeliverable(data))
              .toList();

          checkoutState!(() {
            deliverable = true;
          });
          doPayment();
          // confirmDialog();
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
}
