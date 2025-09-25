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
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
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

  const Cart({Key? key, required this.fromBottom}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateCart();
}

List<User> addressList = [];
//List<SectionModel> cartList = [];
List<Promo> promoList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0, taxAmount = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode;
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
                                  ),
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
                                                ),
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
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                      fontSize: 12, color: Colors.black54),
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
                                          cartList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .price!
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          letterSpacing: 0.7),
                                ),
                                Text(
                                  " " + CUR_CURRENCY! + " " + price.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
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
                            style: TextStyle(color: Colors.grey.shade800),
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
                            style: TextStyle(color: Colors.grey.shade800),
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
                            for (var item in cartList) {
                              if (item.productList![0].availability == "0") {
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
                              _getCart1("");
                              checkout1(cartList);
                            }
                          },
                          icon: Icon(Icons.shopping_bag,
                              color: Colors.grey.shade800),
                          label: Text(
                            "Buy This Now",
                            style: TextStyle(color: Colors.grey.shade800),
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
                                                .lightBlack),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // GestureDetector(
                              //   child: Padding(
                              //     padding: const EdgeInsetsDirectional.only(
                              //         start: 8.0, end: 8, bottom: 8),
                              //     child: Icon(
                              //       Icons.clear,
                              //       size: 13,
                              //       color:
                              //           Theme.of(context).colorScheme.fontColor,
                              //     ),
                              //   ),
                              //   onTap: () {
                              //     if (context.read<CartProvider>().isProgress ==
                              //         false)
                              //       removeFromCartCheckout(index, true, cartList);
                              //   },
                              // )
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
                                              ),
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
                                                  fontWeight: FontWeight.bold),
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
                                                cartList[index]
                                                    .productList![0]
                                                    .prVarientList![selectedPos]
                                                    .price!
                                            : "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                letterSpacing: 0.7),
                                      ),
                                    ),
                                    Text(
                                      " " +
                                          CUR_CURRENCY! +
                                          " " +
                                          price.toString(),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold),
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
                                            // GestureDetector(
                                            //   child: Card(
                                            //     shape: RoundedRectangleBorder(
                                            //       borderRadius:
                                            //           BorderRadius.circular(50),
                                            //     ),
                                            //     child: Padding(
                                            //       padding:
                                            //           const EdgeInsets.all(8.0),
                                            //       child: Icon(
                                            //         Icons.remove,
                                            //         size: 15,
                                            //       ),
                                            //     ),
                                            //   ),
                                            //   onTap: () {
                                            //     if (context
                                            //             .read<CartProvider>()
                                            //             .isProgress ==
                                            //         false)
                                            //       removeFromCartCheckout(
                                            //           index, false, cartList);
                                            //   },
                                            // ),
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
                                                  // PopupMenulabelLarge<String>(
                                                  //   tooltip: '',
                                                  //   icon: const Icon(
                                                  //     Icons.arrow_drop_down,
                                                  //     size: 1,
                                                  //   ),
                                                  //   onSelected: (String value) {
                                                  //     addToCartCheckout(
                                                  //         index, value, cartList);
                                                  //   },
                                                  //   itemBuilder:
                                                  //       (BuildContext context) {
                                                  //     return cartList[index]
                                                  //         .productList![0]
                                                  //         .itemsCounter!
                                                  //         .map<
                                                  //                 PopupMenuItem<
                                                  //                     String>>(
                                                  //             (String value) {
                                                  //       return new PopupMenuItem(
                                                  //           child: new Text(
                                                  //             value,
                                                  //             style: TextStyle(
                                                  //                 color: Theme.of(
                                                  //                         context)
                                                  //                     .colorScheme
                                                  //                     .fontColor),
                                                  //           ),
                                                  //           value: value);
                                                  //     }).toList();
                                                  //   },
                                                  // ),
                                                ],
                                              ),
                                            ),
                                            // GestureDetector(
                                            //   child: Card(
                                            //     shape: RoundedRectangleBorder(
                                            //       borderRadius:
                                            //           BorderRadius.circular(50),
                                            //     ),
                                            //     child: Padding(
                                            //       padding:
                                            //           const EdgeInsets.all(8.0),
                                            //       child: Icon(
                                            //         Icons.add,
                                            //         size: 15,
                                            //       ),
                                            //     ),
                                            //   ),
                                            //   onTap: () {
                                            //     addToCartCheckout(
                                            //         index,
                                            //         (int.parse(cartList[index]
                                            //                     .qty!) +
                                            //                 int.parse(cartList[
                                            //                         index]
                                            //                     .productList![0]
                                            //                     .qtyStepSize!))
                                            //             .toString(),
                                            //         cartList);
                                            //   },
                                            // )
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
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + price.toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + cartList[index].perItemTotal!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'TAXPER')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    cartList[index].productList![0].tax! + "%",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
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
                          style: TextStyle(color: colors.red),
                        )
                      : Container(),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        (double.parse(cartList[index].perItemTotal!))
                            .toStringAsFixed(2)
                            .toString(),
                    //+ " "+cartList[index].productList[0].taxrs,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.fontColor),
                  )
                ],
              )
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
                                                    ),
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
                                          fontSize: 9),
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
                                                .fontColor),
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
                                        saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .price!
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0.7),
                              ),
                              Text(
                                " " + CUR_CURRENCY! + " " + price.toString(),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold),
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

  Future<void> _getCart1(String save) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress ?? '',
          SAVE_LATER: save,
          'buy_now': 1,
          'product_variant_ids': 2
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
            promoList =
                (promo as List).map((e) => new Promo.fromJson(e)).toList();
          }

          for (int i = 0; i < cartList.length; i++) {
            _controller.add(new TextEditingController());
          }
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
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
            promoList =
                (promo as List).map((e) => new Promo.fromJson(e)).toList();
          }

          for (int i = 0; i < cartList.length; i++) {
            _controller.add(new TextEditingController());
          }
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
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
                                      color: colors.primary,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    )),
                                onTap: () {
                                  if (promoC.text.trim().isEmpty)
                                    setSnackbar(
                                        getTranslated(context, 'ADD_PROMO')!,
                                        _checkscaffoldKey);
                                  else if (!isPromoValid!) {
                                    validatePromo(false);
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
                            color: Theme.of(context).colorScheme.fontColor),
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
                                        Text(promoList[index].msg ?? ""),
                                        Text(promoList[index].promoCode ?? ''),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(promoList[index].day ?? ''),
                                SimBtn(
                                  size: 0.3,
                                  title: getTranslated(context, "APPLY"),
                                  onBtnSelected: () {
                                    promoC.text = promoList[index].promoCode!;
                                    if (!isPromoValid!) validatePromo(false);
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
          if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
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
            validatePromo(false);
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
              validatePromo(true);
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
            validatePromo(false);
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
                validatePromo(true);
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
            setSnackbar("Deleted", _scaffoldKey);
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
                validatePromo(false);
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
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  _showContent(BuildContext context) {
    List<SectionModel> cartList = context.read<CartProvider>().cartList;
    print("cart list************${cartList.length}");
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
                                                        .fontColor),
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
                  if (!_isSaveForLaterVisible && cartList.isNotEmpty)
                    Container(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            promoList.length > 0 && oriPrice > 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: InkWell(
                                      child: Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          Container(
                                              margin:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 20),
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .white,
                                                  borderRadius:
                                                      BorderRadiusDirectional
                                                          .circular(10)),
                                              child: TextField(
                                                textDirection:
                                                    Directionality.of(context),
                                                enabled: false,
                                                controller: promoC,
                                                readOnly: true,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 10),
                                                  border: InputBorder.none,
                                                  //isDense: true,
                                                  hintText: getTranslated(
                                                          context,
                                                          'PROMOCODE_LBL') ??
                                                      '',
                                                ),
                                              )),
                                          Positioned.directional(
                                            textDirection:
                                                Directionality.of(context),
                                            end: 0,
                                            child: Container(
                                                padding: EdgeInsets.all(11),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .white,
                                                )),
                                          ),
                                        ],
                                      ),
                                      onTap: promoSheet,
                                    ),
                                  )
                                : Container(),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  getTranslated(
                                                      context, 'TOTAL_PRICE')!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      CUR_CURRENCY! +
                                                          " ${oriPrice.toStringAsFixed(2)}",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium!
                                                          .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor,
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .lightBlack2,
                                                        ),
                                                  ),
                                                  Text(
                                                    CUR_CURRENCY! +
                                                        " " +
                                                        promoAmt.toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall!
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .lightBlack2,
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
                                        if (item.productList![0].availability ==
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
                            // Container(
                            //     decoration: BoxDecoration(
                            //       color: Theme.of(context).colorScheme.white,
                            //       borderRadius: BorderRadius.all(
                            //         Radius.circular(10),
                            //       ),
                            //     ),
                            //     margin: EdgeInsets.symmetric(
                            //         horizontal: 10, vertical: 8),
                            //     padding: EdgeInsets.symmetric(
                            //         vertical: 10, horizontal: 5),
                            //     //  width: deviceWidth! * 0.9,
                            //     child: Column(
                            //       children: [
                            //         Row(
                            //           mainAxisAlignment:
                            //               MainAxisAlignment.spaceBetween,
                            //           children: [
                            //             Text(getTranslated(
                            //                 context, 'TOTAL_PRICE')!),
                            //             Text(
                            //               CUR_CURRENCY! +
                            //                   " ${oriPrice.toStringAsFixed(2)}",
                            //               style: Theme.of(context)
                            //                   .textTheme
                            //                   .titleMedium!
                            //                   .copyWith(
                            //                       color: Theme.of(context)
                            //                           .colorScheme
                            //                           .fontColor),
                            //             ),
                            //           ],
                            //         ),
                            //         isPromoValid!
                            //             ? Row(
                            //                 mainAxisAlignment:
                            //                     MainAxisAlignment.spaceBetween,
                            //                 children: [
                            //                   Text(
                            //                     getTranslated(context,
                            //                         'PROMO_CODE_DIS_LBL')!,
                            //                     style: Theme.of(context)
                            //                         .textTheme
                            //                         .labelSmall!
                            //                         .copyWith(
                            //                             color: Theme.of(context)
                            //                                 .colorScheme
                            //                                 .lightBlack2),
                            //                   ),
                            //                   Text(
                            //                     CUR_CURRENCY! +
                            //                         " " +
                            //                         promoAmt.toString(),
                            //                     style: Theme.of(context)
                            //                         .textTheme
                            //                         .labelSmall!
                            //                         .copyWith(
                            //                             color: Theme.of(context)
                            //                                 .colorScheme
                            //                                 .lightBlack2),
                            //                   )
                            //                 ],
                            //               )
                            //             : Container(),
                            //       ],
                            //     )),
                            // SimBtn(
                            //   size: 0.9,
                            //   title: getTranslated(context, 'PROCEED_CHECKOUT'),
                            //   onBtnSelected: () async {
                            //     bool outOfStock = false;
                            //     for (var item in cartList) {
                            //       if (item.productList![0].availability == "0") {
                            //         outOfStock = true;
                            //         break;
                            //       }
                            //     }
                            //     if (outOfStock) {
                            //       setSnackbar(
                            //         'Some of products are out of stock. Add these product in save in later or remove from cart..!',
                            //         _checkscaffoldKey,
                            //       );
                            //     } else {
                            //       _getCart("");
                            //       checkout(cartList);
                            //     }
                            //   },
                            // ),
                          ]),
                    ),
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
                color: colors.primary, fontWeight: FontWeight.normal)));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC')!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack2,
                fontWeight: FontWeight.normal,
              )),
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.white70))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  checkout1(List<SectionModel> cartList) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

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
                                                                "${totalamount.toString()}" !=
                                                            " "
                                                        ? isPromoValid == true
                                                            ? (double.parse(totalamount ??
                                                                        '0.0') -
                                                                    promoAmt)
                                                                .toString()
                                                            : (CUR_CURRENCY! +
                                                                "${totalamount.toString()}")
                                                        : "",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.0,
                                                    ),
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
                                                          doPayment();

                                                          // confirmDialog();
                                                        }
                                                      }
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.primary,
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
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13.0,
                                                  ),
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

  checkout(List<SectionModel> cartList) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

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
                                                                "${totalamount.toString()}" !=
                                                            " "
                                                        ? isPromoValid == true
                                                            ? (double.parse(totalamount ??
                                                                        '0.0') -
                                                                    promoAmt)
                                                                .toString()
                                                            : (CUR_CURRENCY! +
                                                                "${totalamount.toString()}")
                                                        : "",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.0,
                                                    ),
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
                                                          doPayment();

                                                          // confirmDialog();
                                                        }
                                                      }
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.primary,
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
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13.0,
                                                  ),
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

  Future<void> placeOrder(String? tranId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      context.read<CartProvider>().setProgress(true);
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(this.context, listen: false);

      String? mob = settingsProvider.mobile;
      String? varientId, quantity;

      List<SectionModel> cartList = context.read<CartProvider>().cartList;
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
        var parameter = {
          USER_ID: CUR_USERID,
          MOBILE: mob,
          PRODUCT_VARIENT_ID: varientId,
          QUANTITY: quantity,
          TOTAL: oriPrice.toString(),
          FINAL_TOTAL: totalPrice.toString(),
          DEL_CHARGE: dCharge.toString(),
          // TAX_AMT: taxAmt.toString(),
          TAX_PER: taxAmount.toString(),
          PAYMENT_METHOD: payVia,
          ADD_ID: selAddress,
          ISWALLETBALUSED: isUseWallet! ? "1" : "0",
          WALLET_BAL_USED: usedBal.toString(),
          ORDER_NOTE: noteC.text
        };

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
        print(parameter.toString());
        print("PLACE ORDER PARAMETER====${parameter}");
        print("PLACE ORDER PARAMETER==== ${headers}");
        print("PLACE ORDER PARAMETER==== ${placeOrderApi}");

        Response response =
            await post(placeOrderApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(placeOrderApi.toString());
        print(parameter.toString());
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

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  address() {
    return Card(
      elevation: 0,
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
                          color: Theme.of(context).colorScheme.fontColor),
                    )),
              ],
            ),
            Divider(),
            addressList.length > 0
                ? GestureDetector(
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
                                      addressList[selectedAddress!].name!)),
                              InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    getTranslated(context, 'CHANGE')!,
                                    style: TextStyle(
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              ManageAddress(
                                                home: false,
                                              ))).then((value) {
                                    Navigator.pop(context);
                                  });

                                  checkoutState!(() {
                                    deliverable = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          Text(
                            [
                              addressList[selectedAddress!]?.address ?? "",
                              addressList[selectedAddress!]?.area ?? "",
                              addressList[selectedAddress!]?.city ?? "",
                              addressList[selectedAddress!]?.state ?? "",
                              addressList[selectedAddress!]?.country ?? "",
                              addressList[selectedAddress!]?.pincode ?? "",
                              addressList[selectedAddress!]?.landmark ?? "",
                              addressList[selectedAddress!]?.altMob ?? "",
                            ].where((element) => element.isNotEmpty).join(", "),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                              .lightBlack),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: GestureDetector(
                      child: Text(
                        getTranslated(context, 'ADDADDRESS')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
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
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              payMethod != null && payMethod != ''
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Divider(), Text(payMethod!)],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
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

/////
  orderSummary(List<SectionModel> cartList) {
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
                    fontWeight: FontWeight.bold),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + oriPrice.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
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
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      CUR_CURRENCY! + " " + cgstAmount.toStringAsFixed(2),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
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
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      CUR_CURRENCY! + " " + sgstAmount.toStringAsFixed(2),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
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
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + dCharge.toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              isPromoValid!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + promoAmt.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
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
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + "${totalamount.toString()}" != " "
                        ? isPromoValid == true
                            ? (/*oriPrice - promoAmt+dCharge*/ double.parse(
                                        totalamount ?? '0.0') -
                                    promoAmt)
                                .toString()
                            : (CUR_CURRENCY! + "${totalamount.toString()}")
                        : "",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
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
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + usedBal.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
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

  Future<void> validatePromo(bool check) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        if (check) {
          if (this.mounted && checkoutState != null) checkoutState!(() {});
        }
        setState(() {});
        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: oriPrice.toString()
        };
        print('promocode:_____${parameter}______');
        Response response =
            await post(validatePromoApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];

            totalPrice = double.parse(data["final_total"]) + delCharge;

            promoAmt = double.parse(data["final_discount"]);
            promocode = data["promo_code"];
            isPromoValid = true;
            setSnackbar(
                getTranslated(context, 'PROMO_SUCCESS')!, _checkscaffoldKey);
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;
            promoC.clear();
            var data = getdata["data"];

            totalPrice = double.parse(data["final_total"]) + delCharge;

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

  void confirmDialog() {
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
                              getTranslated(context, 'CONFIRM_ORDER')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, 'SUBTOTAL')!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack2),
                                  ),
                                  Text(
                                    CUR_CURRENCY! +
                                        " " +
                                        oriPrice.toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              // Row(
                              //   mainAxisAlignment:
                              //       MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     Text(
                              //       'Tax Amount',
                              //       style: Theme.of(context)
                              //           .textTheme
                              //           .titleMedium!
                              //           .copyWith(
                              //               color: Theme.of(context)
                              //                   .colorScheme
                              //                   .lightBlack2),
                              //     ),
                              //     Text(
                              //         CUR_CURRENCY! +
                              //             " " +
                              //             taxAmount.toStringAsFixed(2),
                              //         style: Theme.of(context)
                              //             .textTheme
                              //             .titleMedium!
                              //             .copyWith(
                              //                 color: Theme.of(context)
                              //                     .colorScheme
                              //                     .fontColor,
                              //                 fontWeight: FontWeight.bold))
                              //   ],
                              // ),
                              if (cgstAmount > 0)
                                _buildSummaryRow(
                                    context,
                                    'CGST',
                                    CUR_CURRENCY! +
                                        " " +
                                        cgstAmount.toStringAsFixed(2)),

                              if (sgstAmount > 0)
                                _buildSummaryRow(
                                    context,
                                    'SGST',
                                    CUR_CURRENCY! +
                                        " " +
                                        sgstAmount.toStringAsFixed(2)),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, 'DELIVERY_CHARGE')!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack2),
                                  ),
                                  Text(
                                    CUR_CURRENCY! +
                                        " " +
                                        dCharge.toStringAsFixed(2),
                                    // dCharge.toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              isPromoValid!
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(
                                              context, 'PROMO_CODE_DIS_LBL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack2),
                                        ),
                                        Text(
                                          CUR_CURRENCY! +
                                              " " +
                                              promoAmt.toStringAsFixed(2),
                                          // promoAmt.toStringAsFixed(2),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : Container(),
                              isUseWallet!
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, 'WALLET_BAL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack2),
                                        ),
                                        Text(
                                          CUR_CURRENCY! +
                                              " " +
                                              usedBal.toStringAsFixed(2),
                                          // usedBal.toStringAsFixed(2),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : Container(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, 'TOTAL_PRICE')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack2),
                                    ),
                                    Text(
                                      CUR_CURRENCY! +
                                                  "${totalamount.toString()}" !=
                                              " "
                                          ? isPromoValid == true
                                              ? (/*oriPrice - promoAmt+dCharge*/ double
                                                          .parse(totalamount ??
                                                              '0.0') -
                                                      promoAmt)
                                                  .toString()
                                              //  ? (oriPrice - promoAmt).toString()
                                              : (CUR_CURRENCY! +
                                                  "${totalamount.toString()}")
                                          : "",
                                      //   "$CUR_CURRENCY  +${totalPrice.toStringAsFixed(2)}",
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  /* decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),*/
                                  child: TextField(
                                    controller: noteC,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor:
                                          colors.primary.withOpacity(0.1),
                                      //isDense: true,
                                      hintText: getTranslated(context, 'NOTE'),
                                    ),
                                  )),
                            ],
                          ),
                        ),
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
                        child: Text(getTranslated(context, 'DONE')!,
                            style: TextStyle(
                                color: colors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);

                          doPayment();
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

  Widget _buildSummaryRow(BuildContext context, String label, String value,
      {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Theme.of(context).colorScheme.lightBlack2),
        ),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: isDiscount
                    ? Colors.green
                    : Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold))
      ],
    );
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
                                          .fontColor),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: Text(getTranslated(context, 'BANK_INS')!,
                                style: Theme.of(context).textTheme.bodySmall)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10),
                          child: Text(
                            getTranslated(context, 'ACC_DETAIL')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor),
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'ACCNO')! + " : " + acNo!,
                            style: Theme.of(context).textTheme.titleMedium,
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
                            style: Theme.of(context).textTheme.titleMedium,
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
                            style: Theme.of(context).textTheme.titleMedium,
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
                            style: Theme.of(context).textTheme.titleMedium,
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
