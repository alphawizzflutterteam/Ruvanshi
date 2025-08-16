import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:TGSawadesiMartUser/Helper/ApiBaseHelper.dart';
import 'package:TGSawadesiMartUser/Helper/AppBtn.dart';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Helper/Constant.dart';
import 'package:TGSawadesiMartUser/Helper/Session.dart';
import 'package:TGSawadesiMartUser/Helper/String.dart';
import 'package:TGSawadesiMartUser/Helper/widgets.dart';
import 'package:TGSawadesiMartUser/Model/Model.dart';
import 'package:TGSawadesiMartUser/Model/Section_Model.dart';
import 'package:TGSawadesiMartUser/Provider/CartProvider.dart';
import 'package:TGSawadesiMartUser/Provider/CategoryProvider.dart';
import 'package:TGSawadesiMartUser/Provider/FavoriteProvider.dart';
import 'package:TGSawadesiMartUser/Provider/HomeProvider.dart';
import 'package:TGSawadesiMartUser/Provider/SettingProvider.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:TGSawadesiMartUser/Screen/SellerList.dart';
import 'package:TGSawadesiMartUser/Screen/Seller_Details.dart';
import 'package:TGSawadesiMartUser/Screen/SubCategory.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import '../Model/city_model.dart';
import 'Login.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';
import 'package:http/http.dart' as http;

import 'Search.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

List<SectionModel> sectionList = [];
List<CityListModel> cityList = [];
List<CityListModel> citySearchLIst = [];
List<Product> catList = [];
List<Product> popularList = [];
ApiBaseHelper apiBaseHelper = ApiBaseHelper();
List<String> tagList = [];
List<Product> sellerList = [];
int count = 1;
List<Model> homeSliderList = [];
List<Widget> pages = [];
bool cityLoading = true;
StateSetter? cityState;
int? selCityPos = -1;

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;

  late var _controller = PageController();
  late Animation labelLargeSqueezeanimation;
  late AnimationController labelLargeController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<Model> offerImages = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.9, // 👈 dono side gap ke liye
    );
    getCities();
    callApi();
    labelLargeController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    labelLargeSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      new CurvedAnimation(
        parent: labelLargeController,
        curve: new Interval(
          0.0,
          0.150,
        ),
      ),
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) => _animateSlider());
  }

  Future<void> getCities() async {
    try {
      SettingProvider setting =
          Provider.of<SettingProvider>(context, listen: false);
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
            for (var i = 0; i < cityList.length; i++) {
              if (setting.city == cityList[i].id) {
                selectedCity = cityList[i].name;
              }
            }
            print("City List: $cityList");
            citySearchLIst.addAll(cityList);
          } else {
            print("Error: Data is null or not a list");
            setSnackbar("Invalid city data received", context);
          }
        } else {
          print("Error from API: $msg");
          setSnackbar(msg ?? "Unknown error occurred", context);
        }
      } else {
        print("HTTP Error: ${response.reasonPhrase}");
        setSnackbar(
            "Failed to fetch cities: ${response.reasonPhrase}", context);
      }

      // Update state
      cityLoading = false;

      if (mounted) {
        if (cityState != null) cityState!(() {});
        setState(() {});
      }
    } on TimeoutException {
      setSnackbar(getTranslated(context, 'timeoutError') ?? 'Request timed out',
          context);
    } catch (e) {
      setSnackbar(
          getTranslated(context, 'somethingMsg') ?? 'Something went wrong',
          context);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.white30,
      body: _isNetworkAvail
          ? RefreshIndicator(
              color: colors.primary,
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    // _deliverCity(),
                    // _buildHeader(),
                    _slider(),
                    SizedBox(
                      height: 10,
                    ),
                    _catList(),
                    SizedBox(
                      height: 10,
                    ),
                    _section(),
                    // _seller(),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            )
          : noInternet(context),
    );
  }

  Future<Null> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);

    return callApi();
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      child: TextFormField(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Search(),
            ),
          );
        },
        enabled: true,
        decoration: InputDecoration(
          hintText: 'Search Product',
          prefixIcon: Icon(
            Icons.search,
            color: colors.blackTemp,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
          hintStyle: Theme.of(this.context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  // Widget _slider() {
  //   double height = deviceWidth! / 2.0;
  //
  //   return Selector<HomeProvider, bool>(
  //     builder: (context, data, child) {
  //       return data
  //           ? sliderLoading()
  //           : Column(
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 2.0),
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(20),
  //                     child: Container(
  //                       height: height,
  //                       width: double.infinity,
  //                       decoration: BoxDecoration(
  //                         // color: Colors.white,
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: PageView.builder(
  //                         itemCount: homeSliderList.length,
  //                         scrollDirection: Axis.horizontal,
  //                         controller: _controller,
  //                         physics: AlwaysScrollableScrollPhysics(),
  //                         onPageChanged: (index) {
  //                           context.read<HomeProvider>().setCurSlider(index);
  //                         },
  //                         itemBuilder: (BuildContext context, int index) {
  //                           return pages[index];
  //                         },
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 // SizedBox(height: 10), // Adjusted gap
  //                 Row(
  //                   mainAxisSize: MainAxisSize.max,
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: map<Widget>(
  //                     homeSliderList,
  //                     (index, url) {
  //                       return Consumer<HomeProvider>(
  //                         builder: (context, val, _) {
  //                           return Container(
  //                             width: 8.0,
  //                             height: 10.0,
  //                             margin: const EdgeInsets.symmetric(
  //                                 vertical: 10.0,
  //                                 horizontal: 4.0), // Adjust spacing
  //                             decoration: BoxDecoration(
  //                               shape: BoxShape.circle,
  //                               color: val.curSlider == index
  //                                   ? colors.primary
  //                                   : Colors.grey.shade400,
  //                             ),
  //                           );
  //                         },
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             );
  //     },
  //     selector: (_, homeProvider) => homeProvider.sliderLoading,
  //   );
  // }
  Widget _slider() {
    double height = deviceWidth! / 2.0;

    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: height,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PageView.builder(
                          itemCount: homeSliderList.length,
                          scrollDirection: Axis.horizontal,
                          controller: _controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            context.read<HomeProvider>().setCurSlider(index);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      6), // 👈 thoda extra gap smoothness ke liye
                              child: pages[index],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: map<Widget>(
                      homeSliderList,
                      (index, url) {
                        return Consumer<HomeProvider>(
                          builder: (context, val, _) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: val.curSlider == index
                                    ? colors.primary
                                    : Colors.grey.shade400,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
      },
      selector: (_, homeProvider) => homeProvider.sliderLoading,
    );
  }

  void _animateSlider() {
    Future.delayed(Duration(seconds: 30)).then(
      (_) {
        if (mounted) {
          int nextPage = _controller.hasClients
              ? _controller.page!.round() + 1
              : _controller.initialPage;

          if (nextPage == homeSliderList.length) {
            nextPage = 0;
          }
          if (_controller.hasClients)
            _controller
                .animateToPage(nextPage,
                    duration: Duration(milliseconds: 200), curve: Curves.linear)
                .then((_) => _animateSlider());
        }
      },
    );
  }

  _catList() {
    return Selector<HomeProvider, bool>(
      selector: (_, homeProvider) => homeProvider.catLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Container(
            width: double.infinity,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.simmerBase,
              highlightColor: Theme.of(context).colorScheme.simmerHigh,
              child: catLoading(),
            ),
          );
        }

        return SizedBox(
          height: 120, // Increased height for square design
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 10, left: 10),
            itemCount: catList.length,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: GestureDetector(
                  onTap: () async {
                    if (catList[index].subList == null ||
                        catList[index].subList!.isEmpty) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            name: catList[index].name,
                            id: catList[index].id,
                            tag: false,
                            fromSeller: false,
                          ),
                        ),
                      );
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubCategory(
                            title: catList[index].name!,
                            subList: catList[index].subList,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Square Image Container
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(catList[index].image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Category Name
                      SizedBox(
                        width: 70,
                        child: Text(
                          catList[index].name!.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _section() {
    return Selector<HomeProvider, bool>(
      selector: (_, homeProvider) => homeProvider.secLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Container(
            color: Colors.white,
            width: double.infinity,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.simmerBase,
              highlightColor: Theme.of(context).colorScheme.simmerHigh,
              child: sectionLoading(),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: sectionList.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildSingleSection(index);
          },
        );
      },
    );
  }

  Widget _buildSingleSection(int index) {
    if (sectionList[index].productList?.isEmpty ?? true)
      return const SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader(sectionList[index].title ?? "", index),
              _buildProductGrid(index),
            ],
          ),
        ),
        if (offerImages.length > index) _buildOfferImage(index),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if ((sectionList[index].shortDesc ?? "").isNotEmpty)
            Text(
              sectionList[index].shortDesc!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferImage(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        onTap: () => _onOfferTap(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FadeInImage(
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            image: CachedNetworkImageProvider(offerImages[index].image!),
            width: double.infinity,
            height: 150,
            placeholder: const AssetImage("assets/images/sliderph.png"),
            imageErrorBuilder: (context, error, stackTrace) => erroWidget(150),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(int sectionIndex) {
    final productCount = sectionList[sectionIndex].productList!.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: productCount > 4 ? 4 : productCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          return _buildProductCard(sectionIndex, index);
        },
      ),
    );
  }

  Widget _buildProductCard(int secPos, int index) {
    final product = sectionList[secPos].productList![index];
    final variant = product.prVarientList![0];

    double price = double.parse(variant.disPrice!) == 0
        ? double.parse(variant.price!)
        : double.parse(variant.disPrice!);

    double? offPercent;
    if (double.parse(variant.disPrice!) != 0) {
      final off = double.parse(variant.price!) - price;
      offPercent = (off * 100) / double.parse(variant.price!);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ProductDetail(
                model: product, secPos: secPos, index: index, list: false),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: FadeInImage(
                  image: CachedNetworkImageProvider(product.image!),
                  placeholder: placeHolder(120),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  imageErrorBuilder: (context, error, stackTrace) =>
                      erroWidget(double.infinity),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                product.name!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                product.shortDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Text(
                    "$CUR_CURRENCY $price",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (offPercent != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "${offPercent.toStringAsFixed(0)}% OFF",
                        style: TextStyle(
                          color: colors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _onOfferTap(int index) {
    if (offerImages[index].type == "products") {
      Product? item = offerImages[index].list;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              ProductDetail(model: item, secPos: 0, index: 0, list: true),
        ),
      );
    } else if (offerImages[index].type == "categories") {
      Product item = offerImages[index].list;
      if (item.subList == null || item.subList!.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductList(
              name: item.name,
              id: item.id,
              tag: false,
              fromSeller: false,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategory(
              title: item.name!,
              subList: item.subList,
            ),
          ),
        );
      }
    }
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Future<Null> callApi() async {
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);

    user.setUserId(setting.userId);

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
      getSlider();
      getCat();
      getSeller();
      getSection();
      getOfferImages();
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    return null;
  }

  Future _getFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        Map parameter = {
          USER_ID: CUR_USERID,
        };
        apiBaseHelper.postAPICall(getFavApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            List<Product> tempList = (data as List)
                .map((data) => new Product.fromJson(data))
                .toList();

            context.read<FavoriteProvider>().setFavlist(tempList);
          } else {
            if (msg != 'No Favourite(s) Product Are Added')
              setSnackbar(msg!, context);
          }

          context.read<FavoriteProvider>().setLoading(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<FavoriteProvider>().setLoading(false);
        });
      } else {
        context.read<FavoriteProvider>().setLoading(false);
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

  void getOfferImages() {
    Map parameter = Map();
    apiBaseHelper.postAPICall(getOfferImageApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        offerImages.clear();
        offerImages =
            (data as List).map((data) => new Model.fromSlider(data)).toList();
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setOfferLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setOfferLoading(false);
    });
  }

  void getSection() {
    // Map parameter = {PRODUCT_LIMIT: "5", PRODUCT_OFFSET: "6"};
    Map parameter = {PRODUCT_LIMIT: "5"};
    print("section params______${parameter}");

    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
    String curPin = context.read<UserProvider>().curPincode;
    if (curPin != '') parameter[ZIPCODE] = curPin;

    apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print("Get Section Data---------: $getdata");
      sectionList.clear();
      if (!error) {
        var data = getdata["data"];
        print("Get Section Data2: $data");
        sectionList = (data as List)
            .map((data) => new SectionModel.fromJson(data))
            .toList();
      } else {
        if (curPin != '') context.read<UserProvider>().setPincode('');
        setSnackbar(msg!, context);
        print("Get Section Error Msg: $msg");
      }
      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  void getSetting() {
    CUR_USERID = context.read<SettingProvider>().userId;
    //print("")
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

    apiBaseHelper.postAPICall(getSettingApi, parameter).then((getdata) async {
      bool error = getdata["error"];
      String? msg = getdata["message"];

      print("Get Setting Api${getSettingApi.toString()}");
      print(parameter.toString());

      if (!error) {
        var data = getdata["data"]["system_settings"][0];
        cartBtnList = data["cart_btn_on_list"] == "1" ? true : false;
        refer = data["is_refer_earn_on"] == "1" ? true : false;
        CUR_CURRENCY = data["currency"];
        RETURN_DAYS = data['max_product_return_days'];
        MAX_ITEMS = data["max_items_cart"];
        MIN_AMT = data['min_amount'];
        CUR_DEL_CHR = data['delivery_charge'];
        String? isVerion = data['is_version_system_on'];
        extendImg = data["expand_product_images"] == "1" ? true : false;
        String? del = data["area_wise_delivery_charge"];
        MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];

        if (del == "0")
          ISFLAT_DEL = true;
        else
          ISFLAT_DEL = false;

        if (CUR_USERID != null) {
          REFER_CODE = getdata['data']['user_data'][0]['referral_code'];

          context
              .read<UserProvider>()
              .setPincode(getdata["data"]["user_data"][0][PINCODE]);

          if (REFER_CODE == null || REFER_CODE == '' || REFER_CODE!.isEmpty)
            generateReferral();

          context.read<UserProvider>().setCartCount(
              getdata["data"]["user_data"][0]["cart_total_items"].toString());
          context
              .read<UserProvider>()
              .setBalance(getdata["data"]["user_data"][0]["balance"]);

          _getFav();
          _getCart("0");
        }

        UserProvider user = Provider.of<UserProvider>(context, listen: false);
        SettingProvider setting =
            Provider.of<SettingProvider>(context, listen: false);
        user.setMobile(setting.mobile);
        user.setName(setting.userName);
        user.setEmail(setting.email);
        user.setProfilePic(setting.profileUrl);

        Map<String, dynamic> tempData = getdata["data"];
        if (tempData.containsKey(TAG))
          tagList = List<String>.from(getdata["data"][TAG]);

        if (isVerion == "1") {
          String? verionAnd = data['current_version'];
          String? verionIOS = data['current_version_ios'];

          PackageInfo packageInfo = await PackageInfo.fromPlatform();

          String version = packageInfo.version;

          final Version currentVersion = Version.parse(version);
          final Version latestVersionAnd = Version.parse(verionAnd.toString());
          final Version latestVersionIos = Version.parse(verionIOS.toString());

          if ((Platform.isAndroid && latestVersionAnd > currentVersion) ||
              (Platform.isIOS && latestVersionIos > currentVersion))
            updateDailog();
        }
      } else {
        setSnackbar(msg!, context);
      }
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    });
  }

  Future<void> _getCart(String save) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};

        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          List<SectionModel> cartList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();
          context.read<CartProvider>().setCartlist(cartList);
        }
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<Null> generateReferral() async {
    String refer = getRandomString(8);

    Map parameter = {
      REFERCODE: refer,
    };

    apiBaseHelper.postAPICall(validateReferalApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        REFER_CODE = refer;

        Map parameter = {
          USER_ID: CUR_USERID,
          REFERCODE: refer,
        };

        apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
      } else {
        if (count < 5) generateReferral();
        count++;
      }

      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  updateDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: Text(getTranslated(context, 'UPDATE_APP')!),
        content: Text(
          getTranslated(context, 'UPDATE_AVAIL')!,
          style: Theme.of(this.context)
              .textTheme
              .titleMedium!
              .copyWith(color: Theme.of(context).colorScheme.fontColor),
        ),
        actions: <Widget>[
          new TextButton(
              child: Text(
                getTranslated(context, 'NO')!,
                style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          new TextButton(
              child: Text(
                getTranslated(context, 'YES')!,
                style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop(false);

                String _url = '';
                if (Platform.isAndroid) {
                  _url = androidLink + packageName;
                } else if (Platform.isIOS) {
                  _url = iosLink;
                }

                if (await canLaunch(_url)) {
                  await launch(_url);
                } else {
                  throw 'Could not launch $_url';
                }
              })
        ],
      );
    }));
  }

  Widget homeShimmer() {
    return Container(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
          children: [
            catLoading(),
            sliderLoading(),
            sectionLoading(),
          ],
        )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget _buildImagePageItem(Model slider) {
    double height = deviceWidth! / 0.43;

    return GestureDetector(
      child: FadeInImage(
          fadeInDuration: Duration(milliseconds: 150),
          image: CachedNetworkImageProvider(slider.image!),
          height: height,
          width: double.maxFinite,
          fit: BoxFit.fill,
          imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/sliderph.png",
                fit: BoxFit.fill,
                height: height,
                color: colors.primary,
              ),
          placeholderErrorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/sliderph.png",
                fit: BoxFit.fill,
                height: height,
                color: colors.primary,
              ),
          placeholder: AssetImage(imagePath + "sliderph.png")),
      onTap: () async {
        int curSlider = context.read<HomeProvider>().curSlider;

        if (homeSliderList[curSlider].type == "products") {
          Product? item = homeSliderList[curSlider].list;

          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                    model: item, secPos: 0, index: 0, list: true)),
          );
        } else if (homeSliderList[curSlider].type == "categories") {
          Product item = homeSliderList[curSlider].list;
          if (item.subList == null || item.subList!.length == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductList(
                    name: item.name,
                    id: item.id,
                    tag: false,
                    fromSeller: false,
                  ),
                ));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubCategory(
                    title: item.name!,
                    subList: item.subList,
                  ),
                ));
          }
        }
      },
    );
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            shape: BoxShape.circle,
                          ),
                          width: 50.0,
                          height: 50.0,
                        ))
                    .toList()),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
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
            btnAnim: labelLargeSqueezeanimation,
            btnCntrl: labelLargeController,
            onBtnSelected: () async {
              context.read<HomeProvider>().setCatLoading(true);
              context.read<HomeProvider>().setSecLoading(true);
              context.read<HomeProvider>().setSliderLoading(true);
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  if (mounted)
                    setState(() {
                      _isNetworkAvail = true;
                    });
                  callApi();
                } else {
                  await labelLargeController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  _deliverCity() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        dense: true,
        minLeadingWidth: 10,
        leading: Icon(Icons.location_city),
        title: Text(
          selectedCity == null
              ? getTranslated(context, 'SELOC') ?? 'Select Location'
              : '${getTranslated(context, 'DELIVERTO') ?? 'Deliver to'} ${selectedCity}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_down),
        onTap: () {
          cityDialog();
        },
      ),
    );
  }

  String? selectedCity;

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
  //                             // selCityPos = cityList.indexOf(city);
  //                             // Navigator.pop(context);
  //                             // setState(() {});
  //
  //                             SettingProvider setting =
  //                                 Provider.of<SettingProvider>(context,
  //                                     listen: false);
  //
  //                             setting.setCity(CITY, city.id ?? '');
  //                             selectedCity = city.name ?? '';
  //                             _refresh();
  //                             setState(() {});
  //                             Navigator.pop(context);
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

  //new

  cityDialog() {
    final TextEditingController searchController = TextEditingController();
    List cityListFiltered = List.from(cityList);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            void filterCities(String query) {
              query = query.trim().toLowerCase();
              cityListFiltered = cityList.where((city) {
                final name = city.name ?? '';
                return name.toLowerCase().contains(query);
              }).toList();
              setStater(() {});
            }

            return AlertDialog(
              contentPadding: EdgeInsets.all(0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  // 🔍 Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchController,
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
                  SizedBox(height: 8),
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Flexible(
                    child: cityListFiltered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No city found',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: cityListFiltered.length,
                            itemBuilder: (context, index) {
                              final city = cityListFiltered[index];
                              return InkWell(
                                onTap: () {
                                  final setting = Provider.of<SettingProvider>(
                                      context,
                                      listen: false);
                                  setting.setCity(CITY, city.id ?? '');
                                  selectedCity = city.name ?? '';
                                  _refresh();
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    city.name ?? '',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              );
                            },
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

  // setCities() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
  //     ),
  //     builder: (BuildContext context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
  //               style: Theme.of(context)
  //                   .textTheme
  //                   .titleMedium!
  //                   .copyWith(color: Theme.of(context).colorScheme.onSurface),
  //             ),
  //             Divider(color: Theme.of(context).colorScheme.onSurface),

  //             Container(
  //               height: MediaQuery.of(context).size.height * 0.4,
  //               width: MediaQuery.of(context).size.width,
  //               child: ListView.builder(
  //                 itemCount: cityList.length,
  //                 itemBuilder: (context, index) {
  //                   return InkWell(
  //                     onTap: () {
  //                       SettingProvider setting = Provider.of<SettingProvider>(
  //                           context,
  //                           listen: false);

  //                       setting.setCity(CITY, cityList[index].id ?? '');
  //                       selectedCity = cityList[index].name;
  //                       _refresh();
  //                       setState(() {});
  //                       Navigator.pop(context);
  //                     },
  //                     child: Container(
  //                       padding:
  //                           EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //                       child: Text(
  //                         cityList[index].name ?? '',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           color: Theme.of(context).colorScheme.fontColor,
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             )
  //             // DropdownlabelLargeHideUnderline(
  //             //   child: DropdownlabelLarge<int>(
  //             //     isExpanded: true,
  //             //     value: selCityPos,
  //             //     hint: Text(
  //             //       getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
  //             //       style: TextStyle(color: Colors.grey),
  //             //     ),
  //             //     items: List.generate(cityList.length, (index) {
  //             //       return DropdownMenuItem<int>(
  //             //         value: index,
  //             //         child: Text(
  //             //           cityList[index].name ?? '',
  //             //           style: TextStyle(
  //             //             fontSize: 16,
  //             //             color: Theme.of(context).colorScheme.onSurface,
  //             //           ),
  //             //         ),
  //             //       );
  //             //     }),
  //             //     onChanged: (int? newValue) {
  //             //       setState(() {
  //             //         selCityPos = newValue;
  //             //       });
  //             //       Navigator.pop(context);
  //             //     },
  //             //     icon: Icon(Icons.keyboard_arrow_down),
  //             //   ),
  //             // ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // _deliverCity() {
  //   return GestureDetector(
  //     child: Container(
  //       color: Theme.of(context).colorScheme.lightWhite,
  //       child: ListTile(
  //         dense: true,
  //         minLeadingWidth: 10,
  //         leading: Icon(Icons.location_city),
  //         title: Selector<UserProvider, String>(
  //           builder: (context, data, child) {
  //             return Text(
  //               data == ''
  //                   ? getTranslated(context, 'SELOC')!
  //                   : getTranslated(context, 'DELIVERTO')! + data,
  //               style: TextStyle(
  //                 color: Theme.of(context).colorScheme.fontColor,
  //               ),
  //             );
  //           },
  //           selector: (_, provider) => provider.curPincode,
  //         ),
  //         trailing: Icon(Icons.keyboard_arrow_up),
  //       ),
  //     ),
  //     onTap: () {
  //       setCities();
  //     },
  //   );
  // }
  //
  // setCities() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5.0),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.surface,
  //         borderRadius: BorderRadius.circular(5.0),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //         child: GestureDetector(
  //           child: InputDecorator(
  //             decoration: InputDecoration(
  //               fillColor: Theme.of(context).colorScheme.surface,
  //               isDense: true,
  //               border: InputBorder.none,
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         getTranslated(context, 'CITYSELECT_LBL') ??
  //                             'Select City',
  //                         style: Theme.of(context).textTheme.bodySmall,
  //                       ),
  //                       Text(
  //                         selCityPos != null && selCityPos != -1
  //                             ? cityList[selCityPos!].name ?? ""
  //                             : "Select a city",
  //                         style: TextStyle(
  //                           color: selCityPos != null
  //                               ? Theme.of(context).colorScheme.onSurface
  //                               : Colors.grey,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Icon(Icons.keyboard_arrow_down),
  //               ],
  //             ),
  //           ),
  //           onTap: () {
  //             cityBottomSheet();
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }
  //
  // cityBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
  //     ),
  //     builder: (BuildContext context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
  //               style: Theme.of(context)
  //                   .textTheme
  //                   .titleMedium!
  //                   .copyWith(color: Theme.of(context).colorScheme.onSurface),
  //             ),
  //             Divider(color: Theme.of(context).colorScheme.onSurface),
  //             Flexible(
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   children: cityList.map((city) {
  //                     return InkWell(
  //                       onTap: () {
  //                         selCityPos = cityList.indexOf(city);
  //                         Navigator.pop(context);
  //                         setState(() {});
  //                       },
  //                       child: Container(
  //                         margin: EdgeInsets.symmetric(vertical: 5),
  //                         padding: EdgeInsets.all(10),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[200],
  //                           borderRadius: BorderRadius.circular(8),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.grey.withOpacity(0.5),
  //                               spreadRadius: 1,
  //                               blurRadius: 3,
  //                               offset: Offset(0, 2),
  //                             ),
  //                           ],
  //                         ),
  //                         child: Text(
  //                           city.name ?? '',
  //                           style: TextStyle(
  //                               fontSize: 16, fontWeight: FontWeight.w500),
  //                         ),
  //                       ),
  //                     );
  //                   }).toList(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // _deliverPincode() {
  //   // String curpin = context.read<UserProvider>().curPincode;
  //   return GestureDetector(
  //     child: Container(
  //       // padding: EdgeInsets.symmetric(vertical: 8),
  //       color: colors.text,
  //       child: ListTile(
  //         dense: true,
  //         minLeadingWidth: 10,
  //         leading: Icon(
  //           Icons.location_pin,
  //         ),
  //         title: Selector<UserProvider, String>(
  //           builder: (context, data, child) {
  //             return Text(
  //               data == ''
  //                   ? getTranslated(context, 'SELOC')!
  //                   : getTranslated(context, 'DELIVERTO')! + data,
  //               style:
  //                   TextStyle(color: Theme.of(context).colorScheme.fontColor),
  //             );
  //           },
  //           selector: (_, provider) => provider.curPincode,
  //         ),
  //         trailing: Icon(Icons.keyboard_arrow_right),
  //       ),
  //     ),
  //     onTap: setCities(),
  //   );
  // }
  // _deliverPincode() {
  //   return GestureDetector(
  //     child: Container(
  //       color: colors.text,
  //       child: ListTile(
  //         dense: true,
  //         minLeadingWidth: 10,
  //         leading: Icon(Icons.location_pin),
  //         title: Selector<UserProvider, String>(
  //           builder: (context, data, child) {
  //             return Text(
  //               data == ''
  //                   ? getTranslated(context, 'SELOC')!
  //                   : getTranslated(context, 'DELIVERTO')! + data,
  //               style: TextStyle(
  //                 color: Theme.of(context).colorScheme.fontColor,
  //               ),
  //             );
  //           },
  //           selector: (_, provider) => provider.curPincode,
  //         ),
  //         trailing: Icon(Icons.keyboard_arrow_right),
  //       ),
  //     ),
  //     onTap: () {
  //       setCities();
  //     },
  //   );
  // }
  //
  // setCities() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5.0),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.surface,
  //         borderRadius: BorderRadius.circular(5.0),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //         child: GestureDetector(
  //           child: InputDecorator(
  //             decoration: InputDecoration(
  //               fillColor: Theme.of(context).colorScheme.surface,
  //               isDense: true,
  //               border: InputBorder.none,
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         getTranslated(context, 'CITYSELECT_LBL') ??
  //                             'Select City',
  //                         style: Theme.of(context).textTheme.bodySmall,
  //                       ),
  //                       Text(
  //                         selCityPos != null && selCityPos != -1
  //                             ? cityList[selCityPos!].name ?? ""
  //                             : "Select a city",
  //                         style: TextStyle(
  //                           color: selCityPos != null
  //                               ? Theme.of(context).colorScheme.onSurface
  //                               : Colors.grey,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Icon(Icons.keyboard_arrow_down),
  //               ],
  //             ),
  //           ),
  //           onTap: () {
  //             cityDialog();
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }
  //
  // cityDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setStater) {
  //           cityState = setStater;
  //           return AlertDialog(
  //             contentPadding: const EdgeInsets.all(0.0),
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
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[200],
  //                               borderRadius: BorderRadius.circular(8),
  //                               boxShadow: [
  //                                 BoxShadow(
  //                                   color: Colors.grey.withOpacity(0.5),
  //                                   spreadRadius: 1,
  //                                   blurRadius: 3,
  //                                   offset: Offset(0, 2),
  //                                 ),
  //                               ],
  //                             ),
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

  // void _pincodeCheck() {
  //   showModalBottomSheet<dynamic>(
  //       context: context,
  //       isScrollControlled: true,
  //       shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.only(
  //               topLeft: Radius.circular(25), topRight: Radius.circular(25))),
  //       builder: (builder) {
  //         return StatefulBuilder(
  //             builder: (BuildContext context, StateSetter setState) {
  //           return Container(
  //             constraints: BoxConstraints(
  //                 maxHeight: MediaQuery.of(context).size.height * 0.9),
  //             child: ListView(shrinkWrap: true, children: [
  //               Padding(
  //                   padding: const EdgeInsets.only(
  //                       left: 20.0, right: 20, bottom: 40, top: 30),
  //                   child: Padding(
  //                     padding: EdgeInsets.only(
  //                         bottom: MediaQuery.of(context).viewInsets.bottom),
  //                     child: Form(
  //                         key: _formkey,
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Align(
  //                               alignment: Alignment.topRight,
  //                               child: InkWell(
  //                                 onTap: () {
  //                                   Navigator.pop(context);
  //                                 },
  //                                 child: Icon(Icons.close),
  //                               ),
  //                             ),
  //                             TextFormField(
  //                               keyboardType: TextInputType.text,
  //                               textCapitalization: TextCapitalization.words,
  //                               validator: (val) => validatePincode(val!,
  //                                   getTranslated(context, 'PIN_REQUIRED')),
  //                               onSaved: (String? value) {
  //                                 context
  //                                     .read<UserProvider>()
  //                                     .setPincode(value!);
  //                               },
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .titleSmall!
  //                                   .copyWith(
  //                                       color: Theme.of(context)
  //                                           .colorScheme
  //                                           .fontColor),
  //                               decoration: InputDecoration(
  //                                 isDense: true,
  //                                 prefixIcon: Icon(Icons.location_on),
  //                                 hintText:
  //                                     getTranslated(context, 'PINCODEHINT_LBL'),
  //                               ),
  //                             ),
  //                             Padding(
  //                               padding: const EdgeInsets.only(top: 8.0),
  //                               child: Row(
  //                                 children: [
  //                                   Container(
  //                                     margin:
  //                                         EdgeInsetsDirectional.only(start: 20),
  //                                     width: deviceWidth! * 0.35,
  //                                     child: OutlinedlabelLarge(
  //                                       onPressed: () {
  //                                         context
  //                                             .read<UserProvider>()
  //                                             .setPincode('');
  //
  //                                         context
  //                                             .read<HomeProvider>()
  //                                             .setSecLoading(true);
  //                                         getSection();
  //                                         Navigator.pop(context);
  //                                       },
  //                                       child: Text(
  //                                           getTranslated(context, 'All')!),
  //                                     ),
  //                                   ),
  //                                   Spacer(),
  //                                   SimBtn(
  //                                       size: 0.35,
  //                                       title: getTranslated(context, 'APPLY'),
  //                                       onBtnSelected: () async {
  //                                         if (validateAndSave()) {
  //                                           // validatePin(curPin);
  //                                           context
  //                                               .read<HomeProvider>()
  //                                               .setSecLoading(true);
  //                                           getSection();
  //
  //                                           context
  //                                               .read<HomeProvider>()
  //                                               .setSellerLoading(true);
  //                                           sellerList.clear();
  //                                           getSeller();
  //                                           Navigator.pop(context);
  //                                         }
  //                                       }),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         )),
  //                   ))
  //             ]),
  //           );
  //           //});
  //         });
  //       });
  // }
  void setSnackbar(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Future<void> getCities(BuildContext context) async {
  //   try {
  //     var headers = {
  //       'Cookie': 'ci_session=cc08d4381b4fdf4681fe5697fbda2886d2fda585',
  //     };
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse(
  //           'https://developmentalphawizz.com/ruvanshi/app/v1/api/city'),
  //     );
  //     request.headers.addAll(headers);
  //     print("Sending request to: ${request.url}");
  //     print("Headers: ${request.headers}");
  //     http.StreamedResponse response = await request.send();
  //     String responseBody = await response.stream.bytesToString();
  //     print("Response Status: ${response.statusCode}");
  //     print("Response Body: $responseBody");
  //     if (response.statusCode == 200) {
  //       var getdata = json.decode(responseBody);
  //       print("Decoded Data: $getdata");
  //       bool error = getdata["error"];
  //       String? msg = getdata["message"];
  //       if (!error) {
  //         var data = getdata["data"];
  //         if (data != null && data is List) {
  //           cityList = data.map((e) => CityListModel.fromJson(e)).toList();
  //           print("City List: $cityList");
  //           citySearchLIst.addAll(cityList);
  //         } else {
  //           print("Error: Data is null or not a list");
  //           setSnackbar("Invalid city data received", context);
  //         }
  //       } else {
  //         print("Error from API: $msg");
  //         setSnackbar(msg ?? "Unknown error occurred", context);
  //       }
  //     } else {
  //       print("HTTP Error: ${response.reasonPhrase}");
  //       setSnackbar(
  //           "Failed to fetch cities: ${response.reasonPhrase}", context);
  //     }

  //     cityLoading = false;

  //     if (mounted) {
  //       if (cityState != null) cityState!(() {});
  //       setState(() {});
  //     }
  //   } on TimeoutException {
  //     setSnackbar(getTranslated(context, 'timeoutError') ?? 'Request timed out',
  //         context);
  //   } catch (e) {
  //     setSnackbar(
  //         getTranslated(context, 'somethingMsg') ?? 'Something went wrong',
  //         context);
  //     print("Error: $e");
  //   }
  // }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<Null> _playAnimation() async {
    try {
      await labelLargeController.forward();
    } on TickerCanceled {}
  }

  void getSlider() {
    Map map = Map();

    apiBaseHelper.postAPICall(getSliderApi, map).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        print(getSliderApi.toString());

        homeSliderList =
            (data as List).map((data) => new Model.fromSlider(data)).toList();

        pages = homeSliderList.map((slider) {
          return _buildImagePageItem(slider);
        }).toList();
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSliderLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSliderLoading(false);
    });
  }

  void getCat() {
    Map parameter = {
      CAT_FILTER: "false",
    };
    print('category:_____${parameter}______');
    apiBaseHelper.postAPICall(getCatApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];

        catList =
            (data as List).map((data) => new Product.fromCat(data)).toList();

        if (getdata.containsKey("popular_categories")) {
          var data = getdata["popular_categories"];
          popularList =
              (data as List).map((data) => new Product.fromCat(data)).toList();

          if (popularList.length > 0) {
            Product pop =
                new Product.popular("Popular", imagePath + "popular.svg");
            catList.insert(0, pop);
            context.read<CategoryProvider>().setSubList(popularList);
          }
        }
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setCatLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setCatLoading(false);
    });
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              GridView.count(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                childAspectRatio: 1.0,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 5,
                                children: List.generate(
                                  4,
                                  (index) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    sliderLoading()
                    //offerImages.length > index ? _getOfferImage(index) : Container(),
                  ],
                ))
            .toList());
  }

  void getSeller() {
    String pin = context.read<UserProvider>().curPincode;
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);
    Map parameter = {};
    if (setting.city != '') {
      parameter = {
        // ZIPCODE: pin,
        CITY_ID: setting.city,
      };
    }
    print("seller params_____${parameter}");
    apiBaseHelper.postAPICall(getSellerApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        print("Seller Parameter =========> $parameter");
        print("Seller Data=====================> : $data ");
        sellerList =
            (data as List).map((data) => new Product.fromSeller(data)).toList();
        setState(() {});
      } else {
        setSnackbar(msg!, context);
      }
      context.read<HomeProvider>().setSellerLoading(false);
    }, onError: (error) {
      // setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSellerLoading(false);
    });
  }

  _seller() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sellerList.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(getTranslated(context, 'SHOP_BY_SELLER')!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold)),
                              GestureDetector(
                                child:
                                    Text(getTranslated(context, 'VIEW_ALL')!),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SellerList()));
                                },
                              )
                            ],
                          ),
                        )
                      : Container(),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: ListView.builder(
                      itemCount: sellerList.length,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        print(
                            'PrintData:_____${sellerList[index].proPic}______');
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: GestureDetector(
                            onTap: () {
                              print(sellerList[index].open_close_status);
                              if (sellerList[index].open_close_status == '1') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SellerProfile(
                                              sellerStoreName: sellerList[index]
                                                      .store_name ??
                                                  "",
                                              sellerRating: sellerList[index]
                                                      .seller_rating ??
                                                  "",
                                              sellerImage: sellerList[index]
                                                      .seller_profile ??
                                                  "",
                                              sellerName: sellerList[index]
                                                      .seller_name ??
                                                  "",
                                              sellerID:
                                                  sellerList[index].seller_id,
                                              storeDesc: sellerList[index]
                                                  .store_description,
                                            )));
                              } else {
                                showToast("Currently Store is Off");
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 5.0),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(
                                        "${sellerList[index].proPic}"),
                                  ),

                                  // new ClipRRect(
                                  //   borderRadius: BorderRadius.circular(25.0),
                                  //   child: new FadeInImage(
                                  //     fadeInDuration:
                                  //         Duration(milliseconds: 150),
                                  //     image: CachedNetworkImageProvider(
                                  //       sellerList[index].seller_profile!,
                                  //     ),
                                  //     height: 50.0,
                                  //     width: 50.0,
                                  //     fit: BoxFit.contain,
                                  //     imageErrorBuilder:
                                  //         (context, error, stackTrace) =>
                                  //             erroWidget(50),
                                  //     placeholder: placeHolder(50),
                                  //   ),
                                  // ),
                                ),
                                Container(
                                  child: Text(
                                    sellerList[index].store_name ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12),
                                    // overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                  width: 50,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
      },
      selector: (_, homeProvider) => homeProvider.sellerLoading,
    );
  }
}
