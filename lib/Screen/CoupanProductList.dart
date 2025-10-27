import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:TGSawadesiMartUser/Helper/AppBtn.dart';
import 'package:TGSawadesiMartUser/Helper/Public%20Api/api.dart';
import 'package:TGSawadesiMartUser/Helper/SimBtn.dart';
import 'package:TGSawadesiMartUser/Provider/CartProvider.dart';
import 'package:TGSawadesiMartUser/Provider/FavoriteProvider.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import 'HomePage.dart';
import 'Login.dart';
import 'Product_Detail.dart';

class CoupanProductList extends StatefulWidget {
  final String? name, id;

  const CoupanProductList({Key? key, this.id, this.name}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProduct();
}

class StateProduct extends State<CoupanProductList>
    with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  String? totalProduct;
  ScrollController controller = new ScrollController();
  bool _isNetworkAvail = true;
  List<String> selectedId = [];

  String selId = "";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool listType = true;
  bool isOnOff = false;
  List<TextEditingController> _controller = [];
  List<String>? tagList = [];
  ChoiceChip? tagChip, choiceChip;

  // late UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    getProduct();

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    controller.removeListener(() {});
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  @override
  Widget build(BuildContext context) {
    // userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
        appBar: getAppBar(widget.name!, context),
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : Stack(
                    children: <Widget>[
                      _showForm(context),
                      showCircularProgress(_isProgress, colors.primary),
                    ],
                  )
            : noInternet(context));
  }

  _showForm(BuildContext context) {
    return /*RefreshIndicator(
        key: _refreshIndicatorKey,
        //onRefresh: _refresh,
        child: */
        Column(
      children: [
        Expanded(
          child: productList.length == 0
              ? getNoItem(context)
              : listType
                  ? ListView.builder(
                      controller: controller,
                      itemCount: (offset < total)
                          ? productList.length + 1
                          : productList.length,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return listItem(index);
                      },
                    )
                  : GridView.count(
                      padding: EdgeInsetsDirectional.only(top: 5),
                      crossAxisCount: 2,
                      controller: controller,
                      childAspectRatio: 0.78,
                      physics: AlwaysScrollableScrollPhysics(),
                      children: List.generate(
                        (offset < total)
                            ? productList.length + 1
                            : productList.length,
                        (index) {
                          return productItem(
                              index, index % 2 == 0 ? true : false);
                        },
                      )),
        ),
      ],
    );
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
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  offset = 0;
                  total = 0;
                  getProduct();
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  noIntBtn(BuildContext context) {
    double width = deviceWidth!;
    return Container(
        padding: EdgeInsetsDirectional.only(bottom: 10.0, top: 50.0),
        child: Center(
            child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80.0)),
          ),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => super.widget));
          },
          child: Ink(
            child: Container(
              constraints: BoxConstraints(maxWidth: width / 1.2, minHeight: 45),
              alignment: Alignment.center,
              child: Text(getTranslated(context, 'TRY_AGAIN_INT_LBL')!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.white,
                      fontWeight: FontWeight.normal,
                      fontFamily: dynamicFontFamily.fontFamily)),
            ),
          ),
        )));
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      Product model = productList[index];
      totalProduct = model.total;

      if (_controller.length < index + 1)
        _controller.add(new TextEditingController());

      _controller[index].text =
          model.prVarientList![model.selVarient!].cartCount!;

      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }

      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = 0;
      if (model.prVarientList![model.selVarient!].disPrice! != "0") {
        off = (double.parse(model.prVarientList![model.selVarient!].price!) -
                double.parse(model.prVarientList![model.selVarient!].disPrice!))
            .toDouble();
        off = off *
            100 /
            double.parse(model.prVarientList![model.selVarient!].price!);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Hero(
                          tag: "ProList$index${model.id}",
                          child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: Stack(
                                children: [
                                  FadeInImage(
                                    image: NetworkImage(model.image!),
                                    height: 125.0,
                                    width: 135.0,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(125),
                                    placeholder: placeHolder(125),
                                  ),
                                  Positioned.fill(
                                      child: model.availability == "0"
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
                                                      .bodySmall!
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
                                  (off != 0 || off != 0.0 || off != 0.00)
                                      ? Container(
                                          decoration: BoxDecoration(
                                              color: colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              off.toStringAsFixed(2) + "%",
                                              style: TextStyle(
                                                  color: colors.whiteTemp,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                  fontFamily: dynamicFontFamily
                                                      .fontFamily),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(5),
                                        )
                                      : Container()
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: colors.red,
                                  //       borderRadius:
                                  //           BorderRadius.circular(10)),
                                  //   child: Padding(
                                  //     padding: const EdgeInsets.all(5.0),
                                  //     child: Text(
                                  //       off.toStringAsFixed(2) + "%",
                                  //       style: TextStyle(
                                  //           color: colors.whiteTemp,
                                  //           fontWeight: FontWeight.bold,
                                  //           fontSize: 9),
                                  //     ),
                                  //   ),
                                  //   margin: EdgeInsets.all(5),
                                  // )
                                ],
                              ))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                model.name!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack,
                                        fontFamily:
                                            dynamicFontFamily.fontFamily),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              model.prVarientList![model.selVarient!]
                                              .attr_name !=
                                          null &&
                                      model.prVarientList![model.selVarient!]
                                          .attr_name!.isNotEmpty
                                  ? ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount:
                                          att.length >= 2 ? 2 : att.length,
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
                                            padding: EdgeInsetsDirectional.only(
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
                                                          FontWeight.bold,
                                                      fontFamily:
                                                          dynamicFontFamily
                                                              .fontFamily),
                                            ),
                                          )
                                        ]);
                                      })
                                  : Container(),
                              (model.rating! == "0" || model.rating! == "0.0")
                                  ? Container()
                                  : Row(
                                      children: [
                                        RatingBarIndicator(
                                          rating: double.parse(model.rating!),
                                          itemBuilder: (context, index) => Icon(
                                            Icons.star_rate_rounded,
                                            color: Colors.amber,
                                            //color: colors.primary,
                                          ),
                                          unratedColor:
                                              Colors.grey.withOpacity(0.5),
                                          itemCount: 5,
                                          itemSize: 18.0,
                                          direction: Axis.horizontal,
                                        ),
                                        Text(
                                          " (" + model.noOfRating! + ")",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  fontFamily: dynamicFontFamily
                                                      .fontFamily),
                                        )
                                      ],
                                    ),
                              Row(
                                children: <Widget>[
                                  Text(
                                      CUR_CURRENCY! +
                                          " " +
                                          price.toStringAsFixed(2) +
                                          " ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: dynamicFontFamily
                                                  .fontFamily)),
                                  Text(
                                    double.parse(model
                                                .prVarientList![
                                                    model.selVarient!]
                                                .disPrice!) !=
                                            0
                                        ? CUR_CURRENCY! +
                                            "" +
                                            double.parse(model
                                                        .prVarientList![
                                                            model.selVarient!]
                                                        .price! ??
                                                    '0.0')
                                                .toStringAsFixed(2)
                                        : "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            letterSpacing: 0,
                                            fontSize: 15,
                                            fontFamily:
                                                dynamicFontFamily.fontFamily,
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              _controller[index].text != "0"
                                  ? Row(
                                      children: [
                                        //Spacer(),
                                        model.availability == "0"
                                            ? Container()
                                            : cartBtnList
                                                ? Row(
                                                    children: <Widget>[
                                                      Row(
                                                        children: <Widget>[
                                                          GestureDetector(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Icon(
                                                                  Icons.remove,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                      false &&
                                                                  (int.parse(_controller[
                                                                              index]
                                                                          .text) >
                                                                      0))
                                                                removeFromCart(
                                                                    index);
                                                            },
                                                          ),
                                                          Container(
                                                            width: 37,
                                                            height: 20,
                                                            child: Stack(
                                                              children: [
                                                                Selector<
                                                                    CartProvider,
                                                                    Tuple2<
                                                                        List<
                                                                            dynamic>,
                                                                        List<
                                                                            dynamic>>>(
                                                                  builder:
                                                                      (context,
                                                                          data,
                                                                          child) {
                                                                    _controller[
                                                                            index]
                                                                        .text = data
                                                                            .item1
                                                                            .contains(model
                                                                                .id)
                                                                        ? data
                                                                            .item2[data.item1.indexWhere((element) =>
                                                                                element ==
                                                                                model.id)]
                                                                            .toString()
                                                                        : "0";

                                                                    ///here we have fixed the remove quantity value
                                                                    _controller[index].text = model
                                                                        .prVarientList!
                                                                        .first
                                                                        .cartCount
                                                                        .toString();
                                                                    return TextField(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      readOnly:
                                                                          true,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .fontColor),
                                                                      controller:
                                                                          _controller[
                                                                              index],
                                                                      // _controller[index],
                                                                      decoration:
                                                                          InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                      ),
                                                                    );
                                                                  },
                                                                  selector: (_,
                                                                          provider) =>
                                                                      Tuple2(
                                                                          provider
                                                                              .cartIdList,
                                                                          provider
                                                                              .qtyList),
                                                                ),
                                                                // PopupMenuButton<
                                                                //     String>(
                                                                //   tooltip: '',
                                                                //   icon:
                                                                //       const Icon(
                                                                //     Icons
                                                                //         .arrow_drop_down,
                                                                //     size: 1,
                                                                //   ),
                                                                //   onSelected:
                                                                //       (String
                                                                //           value) {
                                                                //     if (_isProgress ==
                                                                //         false)
                                                                //       addToCart(
                                                                //           index,
                                                                //           value);
                                                                //   },
                                                                //   itemBuilder:
                                                                //       (BuildContext
                                                                //           context) {
                                                                //     return model
                                                                //         .itemsCounter!
                                                                //         .map<
                                                                //             PopupMenuItem<
                                                                //                 String>>((String
                                                                //             value) {
                                                                //       return new PopupMenuItem(
                                                                //           child: new Text(
                                                                //               value,
                                                                //               style: TextStyle(color: Theme.of(context).colorScheme.fontColor)),
                                                                //           value: value);
                                                                //     }).toList();
                                                                //   },
                                                                // ),
                                                              ],
                                                            ),
                                                          ), // ),

                                                          GestureDetector(
                                                            child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                ),
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              if (_isProgress ==
                                                                  false)
                                                                addToCart(
                                                                    index,
                                                                    (int.parse(model.prVarientList![model.selVarient!].cartCount!) +
                                                                            int.parse(model.qtyStepSize!))
                                                                        .toString());
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Container(),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ]),
                onTap: () {
                  Product model = productList[index];
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
              ),
            ),
            _controller[index].text == "0"
                ? Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: 5,
                    end: 50,
                    child: InkWell(
                      onTap: () {
                        if (_isProgress == false)
                          addToCart(
                              index,
                              (int.parse(_controller[index].text) +
                                      int.parse(model.qtyStepSize!))
                                  .toString());
                      },
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 5,
                end: 0,
                child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: model.isFavLoading!
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 0.7,
                                )),
                          )
                        : Selector<FavoriteProvider, List<String?>>(
                            builder: (context, data, child) {
                              return InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    !data.contains(model.id)
                                        ? Icons.favorite_border
                                        : Icons.favorite,
                                    size: 24,
                                  ),
                                ),
                                onTap: () {
                                  if (CUR_USERID != null) {
                                    !data.contains(model.id)
                                        ? _setFav(-1, model)
                                        : _removeFav(-1, model);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Login()),
                                    );
                                  }
                                },
                              );
                            },
                            selector: (_, provider) => provider.favIdList,
                          )))
          ],
        ),
      );
    } else
      return Container();
  }

  _setFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          index == -1 ? model.isFav = "1" : productList[index].isFav = "1";

          context.read<FavoriteProvider>().addFavItem(model);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _removeFav(int index, Product model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = true
                : productList[index].isFavLoading = true;
          });

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(removeFavApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          index == -1 ? model.isFav = "0" : productList[index].isFav = "0";
          context
              .read<FavoriteProvider>()
              .removeFavItem(model.prVarientList![0].id!);
        } else {
          setSnackbar(msg!, context);
        }

        if (mounted)
          setState(() {
            index == -1
                ? model.isFavLoading = false
                : productList[index].isFavLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCart(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        int qty;

        qty =
            /*      (int.parse(productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount!)*/
            (int.parse(_controller[index].text) -
                int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };
        print('addtocart:_____${parameter}______');

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = ;

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();
            print('qtydfhdh_____${qty}______');

            var cart = getdata["cart"];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => new SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          setState(() {
            _isProgress = false;
          });
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  void getProduct() {
    Map parameter = {"promo_code_id": widget.id, USER_ID: CUR_USERID!};

    print("ufjparameter ${parameter}");

    apiBaseHelper.postAPICall(getProductByCoupanApi, parameter).then((getdata) {
      print("ufjparameter daraaa ${getdata}");

      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        print("Product List Data ====================> : $data");
        tempList =
            (data as List).map((data) => new Product.fromJson(data)).toList();

        getAvailVarient();
      } else {
        if (msg != "Products Not Found !") setSnackbar(msg!, context);
      }

      setState(() {
        _isLoading = false;
      });
      // context.read<ProductListProvider>().setProductLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      setState(() {
        _isLoading = false;
      });
      //context.read<ProductListProvider>().setProductLoading(false);
    });
  }

  void getAvailVarient() {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == "2") {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == "1") {
            tempList[j].selVarient = i;

            break;
          }
        }
      }
    }
    productList.addAll(tempList);
  }

  Widget productItem(int index, bool pad) {
    if (index < productList.length) {
      Product model = productList[index];

      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = 0;
      if (model.prVarientList![model.selVarient!].disPrice! != "0") {
        off = (double.parse(model.prVarientList![model.selVarient!].price!) -
                double.parse(model.prVarientList![model.selVarient!].disPrice!))
            .toDouble();
        off = off *
            100 /
            double.parse(model.prVarientList![model.selVarient!].price!);
      }

      if (_controller.length < index + 1)
        _controller.add(new TextEditingController());

      _controller[index].text =
          model.prVarientList![model.selVarient!].cartCount!;

      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }
      double width = deviceWidth! * 0.5;

      return InkWell(
        child: Card(
          elevation: 4,
          margin: EdgeInsetsDirectional.only(
              bottom: 10, end: 10, start: pad ? 10 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Hero(
                        tag: "ProGrid$index${model.id}",
                        child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: CachedNetworkImageProvider(model.image!),
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                          placeholder: placeHolder(width),
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(width),
                        ),
                      ),
                    ),
                    Positioned.fill(
                        child: model.availability == "0"
                            ? Container(
                                height: 55,
                                color: Colors.white70,
                                // width: double.maxFinite,
                                padding: EdgeInsets.all(2),
                                child: Center(
                                  child: Text(
                                    getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                dynamicFontFamily.fontFamily),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Container()),
                    // Align(
                    //   alignment: AlignmentDirectional.center,
                    //   child: model.availability == "0"
                    //       ? Text(getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                    //           style: Theme.of(context)
                    //               .textTheme
                    //               .subtitle2!
                    //               .copyWith(
                    //                   color: Colors.red,
                    //                   fontWeight: FontWeight.bold))
                    //       : Container(),
                    // ),
                    (off != 0 || off != 0.0 || off != 0.00)
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: colors.red,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  off.toStringAsFixed(2) + "%",
                                  style: TextStyle(
                                      color: colors.whiteTemp,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                              ),
                              margin: EdgeInsets.all(5),
                            ),
                          )
                        : Container(),

                    // Align(
                    //   alignment: Alignment.topLeft,
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //         color: colors.red,
                    //         borderRadius: BorderRadius.circular(10)),
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(5.0),
                    //       child: Text(
                    //         off.toStringAsFixed(2) + "%",
                    //         style: TextStyle(
                    //             color: colors.whiteTemp,
                    //             fontWeight: FontWeight.bold,
                    //             fontSize: 9),
                    //       ),
                    //     ),
                    //     margin: EdgeInsets.all(5),
                    //   ),
                    // ),
                    Divider(
                      height: 1,
                    ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: 0,
                      // bottom: -18,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          model.availability == "0" && !cartBtnList
                              ? Container()
                              : _controller[index].text == "0"
                                  ? InkWell(
                                      onTap: () {
                                        if (_isProgress == false)
                                          addToCart(
                                              index,
                                              (int.parse(_controller[index]
                                                          .text) +
                                                      int.parse(
                                                          model.qtyStepSize!))
                                                  .toString());
                                      },
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 3.0, bottom: 5, top: 3),
                                      child: Row(
                                        children: <Widget>[
                                          GestureDetector(
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                            onTap: () {
                                              if (_isProgress == false &&
                                                  (int.parse(_controller[index]
                                                          .text) >
                                                      0)) removeFromCart(index);
                                            },
                                          ),
                                          Container(
                                            width: 26,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: colors.white70,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Stack(
                                              children: [
                                                Selector<
                                                    CartProvider,
                                                    Tuple2<List<dynamic>,
                                                        List<dynamic>>>(
                                                  builder:
                                                      (context, data, child) {
                                                    _controller[index]
                                                        .text = data.item1
                                                            .contains(model.id)
                                                        ? data.item2[data.item1
                                                                .indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        model
                                                                            .id)]
                                                            .toString()
                                                        : "0";
                                                    return TextField(
                                                      textAlign:
                                                          TextAlign.center,
                                                      readOnly: true,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .fontColor),
                                                      controller:
                                                          _controller[index],
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                    );
                                                  },
                                                  selector: (_, provider) =>
                                                      Tuple2(
                                                          provider.cartIdList,
                                                          provider.qtyList),
                                                ),
                                                // PopupMenuButton<String>(
                                                //   tooltip: '',
                                                //   icon: const Icon(
                                                //     Icons.arrow_drop_down,
                                                //     size: 0,
                                                //   ),
                                                //   onSelected: (String value) {
                                                //     if (_isProgress == false)
                                                //       addToCart(index, value);
                                                //   },
                                                //   itemBuilder:
                                                //       (BuildContext context) {
                                                //     return model.itemsCounter!
                                                //         .map<
                                                //                 PopupMenuItem<
                                                //                     String>>(
                                                //             (String value) {
                                                //       return new PopupMenuItem(
                                                //           child:
                                                //               new Text(value),
                                                //           value: value);
                                                //     }).toList();
                                                //   },
                                                // ),
                                              ],
                                            ),
                                          ), // ),

                                          GestureDetector(
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                            onTap: () {
                                              if (_isProgress == false)
                                                addToCart(
                                                    index,
                                                    (int.parse(_controller[
                                                                    index]
                                                                .text) +
                                                            int.parse(model
                                                                .qtyStepSize!))
                                                        .toString());
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                          Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: model.isFavLoading!
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                          height: 15,
                                          width: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 0.7,
                                          )),
                                    )
                                  : Selector<FavoriteProvider, List<String?>>(
                                      builder: (context, data, child) {
                                        return InkWell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              !data.contains(model.id)
                                                  ? Icons.favorite_border
                                                  : Icons.favorite,
                                              size: 15,
                                            ),
                                          ),
                                          onTap: () {
                                            if (CUR_USERID != null) {
                                              !data.contains(model.id)
                                                  ? _setFav(-1, model)
                                                  : _removeFav(-1, model);
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Login()),
                                              );
                                            }
                                          },
                                        );
                                      },
                                      selector: (_, provider) =>
                                          provider.favIdList,
                                    )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              (model.rating! == "0" || model.rating! == "0.0")
                  ? Container()
                  : Row(
                      children: [
                        RatingBarIndicator(
                          rating: double.parse(model.rating!),
                          itemBuilder: (context, index) => Icon(
                            Icons.star_rate_rounded,
                            color: Colors.amber,
                            //color: colors.primary,
                          ),
                          unratedColor: Colors.grey.withOpacity(0.5),
                          itemCount: 5,
                          itemSize: 12.0,
                          direction: Axis.horizontal,
                          itemPadding: EdgeInsets.all(0),
                        ),
                        Text(
                          " (" + model.noOfRating! + ")",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  fontFamily: dynamicFontFamily.fontFamily),
                        )
                      ],
                    ),
              Row(
                children: [
                  Text(" " + CUR_CURRENCY! + " " + price.toString() + " ",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: dynamicFontFamily.fontFamily)),
                  double.parse(model
                              .prVarientList![model.selVarient!].disPrice!) !=
                          0
                      ? Flexible(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  double.parse(model
                                              .prVarientList![model.selVarient!]
                                              .disPrice!) !=
                                          0
                                      ? CUR_CURRENCY! +
                                          "" +
                                          model
                                              .prVarientList![model.selVarient!]
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
                                          letterSpacing: 0,
                                          fontFamily:
                                              dynamicFontFamily.fontFamily),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container()
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: [
                    Expanded(
                      child: model.prVarientList![model.selVarient!]
                                      .attr_name !=
                                  null &&
                              model.prVarientList![model.selVarient!].attr_name!
                                  .isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: att.length >= 2 ? 2 : att.length,
                              itemBuilder: (context, index) {
                                return Row(children: [
                                  Flexible(
                                    child: Text(
                                      att[index].trim() + ":",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: 5.0),
                                      child: Text(
                                        val[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: dynamicFontFamily
                                                    .fontFamily),
                                      ),
                                    ),
                                  )
                                ]);
                              })
                          : Container(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 5.0, bottom: 5),
                child: Text(
                  model.name!,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontFamily: dynamicFontFamily.fontFamily),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          //),
        ),
        onTap: () {
          Product model = productList[index];

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
      );
    } else
      return Container();
  }

  Future<void> addToCart(int index, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted)
          setState(() {
            _isProgress = true;
          });

        if (int.parse(qty) < productList[index].minOrderQuntity!) {
          qty = productList[index].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          QTY: qty
        };
        print('hdffffffffffff:_____${parameter}______');

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String? qty = data['total_quantity'];
            print('totalquantity:_____${qty}______');
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();
            print(
                'qtyjjhh:_____${productList[index].prVarientList![productList[index].selVarient!].cartCount}______');

            var cart = getdata["cart"];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => new SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          if (mounted)
            setState(() {
              _isProgress = false;
            });
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
}
