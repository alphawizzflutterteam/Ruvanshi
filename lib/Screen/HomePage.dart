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
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import '../Model/Welcome_Offer_Model.dart';
import '../Model/city_model.dart';
import 'Login.dart';
import 'Offer.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';
import 'package:http/http.dart' as http;

import 'Search.dart';

class HomePage extends StatefulWidget {
  // Create Callback function
  final VoidCallback? callback;

  // Constructor with callback parameter
  const HomePage({Key? key, this.callback}) : super(key: key);

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

  late var _controller = PageController(viewportFraction: 1);
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
    _setStatusBarColor();
    getOfferGif();
    dynamicGradient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getOfferData();
    });
    // getOfferData();
    _controller = PageController(
      viewportFraction: 1,
    );
    _animateSlider();
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

  Color primaryColor = Colors.black;
  Color secondaryColor = Colors.white;

  BoxDecoration dynamicGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  Future<void> getOfferData() async {
    try {
      var headers = {
        'Cookie': 'ci_session=0eba83f24da5e2ebd0f228b98bbeb3506df9bf21'
      };
      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}get_active_popups'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String res = await response.stream.bytesToString();
        final Map<String, dynamic> jsonRes = json.decode(res);
        final WelcomeOfferModel model = WelcomeOfferModel.fromJson(jsonRes);

        if (model.data != null && model.data!.isNotEmpty) {
          final String rawImage = model.data![0].imageUrl ?? '';
          String imageLink = '';

          if (rawImage.startsWith('http')) {
            imageLink = rawImage;
          } else {
            imageLink = 'https://developmentalphawizz.com/ruvanshi/$rawImage';
          }
          if (imageLink.isNotEmpty && mounted && !isSpecialOfferShown) {
            openBottomSheet(imageLink: imageLink);
          }
        }
      } else {
        debugPrint("API Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
  }

  void openBottomSheet({required String imageLink}) {
    isSpecialOfferShown = true;
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            // margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  // borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageLink,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 40, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  List<String> offerImgs = [];
  int currentIndex = 0;
  Timer? timer;

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

  void startImageLoop() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 4), (Timer t) {
      if (offerImgs.isNotEmpty) {
        setState(() {
          currentIndex = (currentIndex + 1) % offerImgs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setStatusBarColor();
    return SafeArea(
      child: Scaffold(
        backgroundColor: colors.grad1Color1,
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
                        height: 2,
                      ),
                      // _deliverCity(),
                      // _buildHeader(),
                      _slider(),
                      _catList(),
                      SizedBox(
                        height: 10,
                      ),
                      _section(),
                      // _seller(),
                      SizedBox(
                        height: 100,
                      ),
                    ],
                  ),
                ),
              )
            : noInternet(context),
        floatingActionButton: offerImages.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Offer(
                        fromSeller: false,
                        tag: false,
                        name: "Offer Section",
                      ),
                    ),
                  );
                },
                child: offerImgs.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: AnimatedSwitcher(
                          duration: const Duration(seconds: 4),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: Container(
                            width: 50,
                            height: 50,
                            child: CachedNetworkImage(
                              key: ValueKey<String>(offerImgs[currentIndex]),
                              imageUrl: offerImgs[currentIndex],
                              fit: BoxFit.cover,
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
                          ),
                        ),
                      )
                    : Image.asset(
                        "assets/images/offer.gif",
                        fit: BoxFit.cover,
                      ),
              )
            : SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<Null> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);
    widget.callback!();
    getOfferGif();
    return callApi();
  }

  Widget _slider() {
    double height = deviceWidth! / 2.0;

    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: height,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: homeSliderList.length,
                          scrollDirection: Axis.horizontal,
                          controller: _controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            context.read<HomeProvider>().setCurSlider(index);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            return pages[index];
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
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!mounted || !_controller.hasClients || homeSliderList.isEmpty) return;
      int nextPage = _controller.page?.round() ?? 0;
      nextPage++;
      if (nextPage >= homeSliderList.length) {
        nextPage = 0;
      }
      _controller
          .animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          )
          .then((_) => _animateSlider());
    });
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
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 10),
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
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  fontFamily: dynamicFontFamily.fontFamily),
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

  _section() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: sectionLoading(),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: sectionList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _singleSection(index);
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.secLoading,
    );
  }

  // Add this as a class-level variable
  final int _catListInsertIndex =
      2; // Show after 2nd section (between 2nd and 3rd)

  _singleSection(int index) {
    Color back;
    int pos = index % 5;
    if (pos == 0)
      back = Theme.of(context).colorScheme.back1;
    else if (pos == 1)
      back = Theme.of(context).colorScheme.back2;
    else if (pos == 2)
      back = Theme.of(context).colorScheme.back3;
    else if (pos == 3)
      back = Theme.of(context).colorScheme.back4;
    else
      back = Theme.of(context).colorScheme.back5;

    Widget _sectionBody() => sectionList[index].productList!.length > 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _getHeading(sectionList[index].title ?? "", index),
                    _getSection(index),
                  ],
                ),
              ),
            ],
          )
        : Container();

    if (index == _catListInsertIndex) {
      return Column(
        children: [
          _sectionBody(),
          const SizedBox(height: 10),
          _catList1(),
          const SizedBox(height: 10),
        ],
      );
    } else {
      return _sectionBody();
    }
  }

  _catList1() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: catLoading(),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: catList.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return GestureDetector(
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: catList[index].image != null
                                      ? CachedNetworkImage(
                                          imageUrl: catList[index].image!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(colors.primary),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[400],
                                              size: 30,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: Image.asset(
                                            "assets/images/homelogo.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  catList[index].name?.toUpperCase() ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
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
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );
  }

  _getSection(int i) {
    var orient = MediaQuery.of(context).orientation;
    return sectionList[i].style == DEFAULT
        ? Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15, bottom: 15),
            child: GridView.count(
              padding: EdgeInsetsDirectional.only(top: 5),
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 0.750,
              physics: NeverScrollableScrollPhysics(),
              children: List.generate(
                sectionList[i].productList!.length < 4
                    ? sectionList[i].productList!.length
                    : 4,
                (index) {
                  return productItem(i, index, index % 2 == 0 ? true : false);
                },
              ),
            ),
          )
        : sectionList[i].style == STYLE1
            ? sectionList[i].productList!.isNotEmpty
                ? SizedBox(
                    height: deviceHeight! * 0.35,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      scrollDirection: Axis.horizontal,
                      itemCount: sectionList[i].productList!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: productItem(i, index, index % 2 == 0),
                          ),
                        );
                      },
                    ),
                  )
                : Container()
            : sectionList[i].style == STYLE2
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 0, true)),
                              Container(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.2
                                    : deviceHeight! * 0.5,
                                child: productItem(i, 1, true),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          flex: 3,
                          fit: FlexFit.loose,
                          child: Container(
                            height: orient == Orientation.portrait
                                ? deviceHeight! * 0.4
                                : deviceHeight,
                            child: productItem(i, 2, false),
                          ),
                        ),
                      ],
                    ),
                  )
                : sectionList[i].style == STYLE3
                    ? Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              flex: 1,
                              fit: FlexFit.loose,
                              child: Container(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.3
                                    : deviceHeight! * 0.6,
                                child: productItem(i, 0, false),
                              ),
                            ),
                            Container(
                              height: orient == Orientation.portrait
                                  ? deviceHeight! * 0.2
                                  : deviceHeight! * 0.5,
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: productItem(i, 1, true),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: productItem(i, 2, true),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: productItem(i, 3, false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : sectionList[i].style == STYLE4
                        ? Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: Container(
                                        height: orient == Orientation.portrait
                                            ? deviceHeight! * 0.25
                                            : deviceHeight! * 0.5,
                                        child: productItem(i, 0, false))),
                                Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: Row(
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        fit: FlexFit.loose,
                                        child: productItem(i, 1, true),
                                      ),
                                      Flexible(
                                        flex: 1,
                                        fit: FlexFit.loose,
                                        child: productItem(i, 2, false),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: GridView.count(
                              padding: EdgeInsetsDirectional.only(top: 5),
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              childAspectRatio: 1.2,
                              physics: NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                              children: List.generate(
                                sectionList[i].productList!.length < 6
                                    ? sectionList[i].productList!.length
                                    : 6,
                                (index) {
                                  return productItem(
                                      i, index, index % 2 == 0 ? true : false);
                                },
                              ),
                            ),
                          );
  }

  Widget productItem(int secPos, int index, bool pad) {
    if (sectionList[secPos].productList!.length > index) {
      String? offPer;
      double price = double.parse(
          sectionList[secPos].productList![index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(
            sectionList[secPos].productList![index].prVarientList![0].price!);
      } else {
        double off = double.parse(sectionList[secPos]
                .productList![index]
                .prVarientList![0]
                .price!) -
            price;
        offPer = ((off * 100) /
                double.parse(sectionList[secPos]
                    .productList![index]
                    .prVarientList![0]
                    .price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Hero(
                  tag:
                      "${sectionList[secPos].productList![index].id}$secPos$index",
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(
                          sectionList[secPos].productList![index].image!,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 5.0,
                  top: 3,
                ),
                child: Text(
                  sectionList[secPos].productList![index].name!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontSize: 14,
                      fontFamily: dynamicFontFamily.fontFamily,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                " " + CUR_CURRENCY! + " " + price.toString(),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: dynamicFontFamily.fontFamily,
                    fontSize: 15),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 5.0, bottom: 5, top: 3),
                child: double.parse(sectionList[secPos]
                            .productList![index]
                            .prVarientList![0]
                            .disPrice!) !=
                        0
                    ? Row(
                        children: <Widget>[
                          Text(
                            double.parse(sectionList[secPos]
                                        .productList![index]
                                        .prVarientList![0]
                                        .disPrice!) !=
                                    0
                                ? CUR_CURRENCY! +
                                    "" +
                                    double.parse(sectionList[secPos]
                                            .productList![index]
                                            .prVarientList![0]
                                            .price!)
                                        .toStringAsFixed(2)
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                    fontSize: 15,
                                    color: Colors.grey,
                                    fontFamily: dynamicFontFamily.fontFamily,
                                    fontWeight: FontWeight.bold),
                          ),
                          Flexible(
                            child: Text(
                              " | " + "$offPer%",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                      color: colors.primary,
                                      letterSpacing: 0,
                                      fontSize: 15,
                                      fontFamily: dynamicFontFamily.fontFamily,
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              ),
            ],
          ),
          onTap: () {
            Product model = sectionList[secPos].productList![index];
            Navigator.push(
              context,
              PageRouteBuilder(
                // transitionDuration: Duration(milliseconds: 150),
                pageBuilder: (_, __, ___) => ProductDetail(
                    model: model, secPos: secPos, index: index, list: false
                    //  title: sectionList[secPos].title,
                    ),
              ),
            );
          },
        ),
      );
    } else
      return Container();
  }

  _getHeading(String title, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  // color: colors.primary
                ),
                padding: EdgeInsetsDirectional.only(
                    start: 10, bottom: 0, top: 0, end: 10),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: colors.blackTemp,
                      fontSize: 18,
                      fontFamily: dynamicFontFamily.fontFamily,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  // overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          // color: Colors.red,
          padding: const EdgeInsets.symmetric(
            vertical: 0.0,
            horizontal: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(sectionList[index].shortDesc ?? "",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: dynamicFontFamily.fontFamily)),
              ),
            ],
          ),
        ),
      ],
    );
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
      // getSeller();
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
        title: Text(getTranslated(context, 'UPDATE_APP')!,
            style: TextStyle(fontFamily: dynamicFontFamily.fontFamily)),
        content: Text(
          getTranslated(context, 'UPDATE_AVAIL')!,
          style: Theme.of(this.context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontFamily: dynamicFontFamily.fontFamily),
        ),
        actions: <Widget>[
          new TextButton(
              child: Text(
                getTranslated(context, 'NO')!,
                style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontFamily: dynamicFontFamily.fontFamily,
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
                    fontFamily: dynamicFontFamily.fontFamily,
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

  String? selectedCity;

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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFamily: dynamicFontFamily.fontFamily),
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
                                      Theme.of(context).colorScheme.onSurface,
                                  fontFamily: dynamicFontFamily.fontFamily),
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
                                        fontFamily:
                                            dynamicFontFamily.fontFamily,
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

  void setSnackbar(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message,
          style: TextStyle(fontFamily: dynamicFontFamily.fontFamily)),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

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
    apiBaseHelper.postAPICall(getSellerApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
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

// String? PRIMARY = '';
// String? SECONDARY = '';
// String PRIMARY_COLOR = 'primary';
// String SECONDARY_COLOR = 'secondary';

// void getThemeSetting() {
//   CUR_USERID = context.read<SettingProvider>().userId;
//   Map<String, dynamic> parameter = {};
//   if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

//   apiBaseHelper.postAPICall(getThemeApi, parameter).then((getdata) async {
//     bool error = getdata["error"];
//     if (!error) {
//       var colors = getdata["data"]["colors"];

//       String? primaryHex = colors[PRIMARY_COLOR]?.toString();
//       String? secondaryHex = colors[SECONDARY_COLOR]?.toString();
//       String? backgroundHex = colors["background"]?.toString();
//       String? textHex = colors["text"]?.toString();
//       // Color backgroundColor = colors.background;
//       // Color textColor = colors.text;
//       primaryHex = "c3831d";
//       if (primaryHex != null && primaryHex.isNotEmpty) {
//         primaryColor = Color(int.parse("0xFF$primaryHex"));
//       }
//       if (secondaryHex != null && secondaryHex.isNotEmpty) {
//         secondaryColor = Color(int.parse("0xFF$secondaryHex"));
//       }
//       // if (backgroundHex != null && backgroundHex.isNotEmpty) {
//       //   backgroundColor = Color(int.parse("0xFF$backgroundHex"));
//       // }
//       // if (textHex != null && textHex.isNotEmpty) {
//       //   textColor = Color(int.parse("0xFF$textHex"));
//       // }

//       print("Primary: $primaryColor, Secondary: $secondaryColor");
//       updateAppColors(primaryColor, secondaryColor);
//       if (mounted) setState(() {});
//     }
//   }, onError: (error) {
//     print("API Error: $error");
//   });
// }

// void updateAppColors(Color newPrimary, Color newSecondary) {
//   setState(() {
//     colors.setPrimary(newPrimary);
//     colors.setSecondary(newSecondary);
//   });
//   themeNotifier.value = !themeNotifier.value;
//   // colors.setPrimary = newPrimary;
//   // colors.setSecondary = newSecondary;
//   // // colors.b

//   // // Rebuild MaterialColor swatch
//   // colors.primary_app = MaterialColor(
//   //   newPrimary.value,
//   //   <int, Color>{
//   //     50: newPrimary,
//   //     100: newPrimary,
//   //     200: newPrimary,
//   //     300: newPrimary,
//   //     400: newPrimary,
//   //     500: newPrimary,
//   //     600: newPrimary,
//   //     700: newPrimary,
//   //     800: newPrimary,
//   //     900: newPrimary,
//   //   },
//   // );
// }
}
