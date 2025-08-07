import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Login.dart';

class IntroSlider extends StatefulWidget {
  @override
  _GettingStartedScreenState createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<IntroSlider>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  List slideList = [];

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.initState();

    new Future.delayed(Duration.zero, () {
      setState(() {
        slideList = [
          Slide(
            imageUrl: 'assets/images/introimage_a.png',
            title: getTranslated(context, 'TITLE1_LBL'),
            description: getTranslated(context, 'DISCRIPTION1'),
          ),
          Slide(
            imageUrl: 'assets/images/introimage_b.png',
            title: getTranslated(context, 'TITLE2_LBL'),
            description: getTranslated(context, 'DISCRIPTION2'),
          ),
          Slide(
            imageUrl: 'assets/images/introimage_c.png',
            title: getTranslated(context, 'TITLE3_LBL'),
            description: getTranslated(context, 'DISCRIPTION3'),
          ),
        ];
      });
    });

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.9,
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
    super.dispose();
    _pageController.dispose();
    buttonController!.dispose();

    // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  _onPageChanged(int index) {
    if (mounted)
      setState(() {
        _currentPage = index;
      });
  }

  List<T?> map<T>(List list, Function handler) {
    List<T?> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  // Widget _slider() {
  //   return Expanded(
  //     child: PageView.builder(
  //       itemCount: slideList.length,
  //       scrollDirection: Axis.horizontal,
  //       controller: _pageController,
  //       onPageChanged: _onPageChanged,
  //       itemBuilder: (BuildContext context, int index) {
  //         return SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.max,
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: <Widget>[
  //               Container(
  //                 height: MediaQuery.of(context).size.height * .5,
  //                 child: Image.asset(
  //                   slideList[index].imageUrl,
  //                 ),
  //               ),
  //               Container(
  //                   margin: EdgeInsetsDirectional.only(top: 20),
  //                   child: Text(slideList[index].title,
  //                       style: Theme.of(context)
  //                           .textTheme
  //                           .titleMedium!
  //                           .copyWith(
  //                               color: Theme.of(context).colorScheme.fontColor,
  //                               fontWeight: FontWeight.bold))),
  //               Container(
  //                 padding: EdgeInsetsDirectional.only(
  //                     top: 30.0, start: 15.0, end: 15.0),
  //                 child: Text(slideList[index].description,
  //                     textAlign: TextAlign.center,
  //                     style: Theme.of(context).textTheme.titleSmall!.copyWith(
  //                         color: Theme.of(context).colorScheme.fontColor,
  //                         fontWeight: FontWeight.normal)),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
  _slider() {
    return Expanded(
      child: PageView.builder(
        itemCount: slideList.length,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final slide = slideList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Image.asset(
                    slide.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  slide.title ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.fontColor,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.description ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    if (_currentPage == slideList.length - 1) {
                      setPrefrenceBool(ISFIRSTTIME, true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    child: Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                _buildIndicatorDots(),
              ],
            ),
          );
        },
      ),
    );
  }

  // _btn() {
  //   return Column(
  //     children: [
  //       Row(
  //           mainAxisSize: MainAxisSize.min,
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: getList()),
  //       Center(
  //           child: Padding(
  //         padding: const EdgeInsetsDirectional.only(bottom: 18.0),
  //         child: AppBtn(
  //             title: _currentPage == 0 || _currentPage == 1
  //                 ? getTranslated(context, 'NEXT_LBL')
  //                 : getTranslated(context, 'GET_STARTED'),
  //             btnAnim: buttonSqueezeanimation,
  //             btnCntrl: buttonController,
  //             onBtnSelected: () {
  //               if (_currentPage == 2) {
  //                 setPrefrenceBool(ISFIRSTTIME, true);
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(builder: (context) => SignInUpAcc()),
  //                 );
  //               } else {
  //                 _currentPage = _currentPage + 1;
  //                 _pageController.animateToPage(_currentPage,
  //                     curve: Curves.decelerate,
  //                     duration: Duration(milliseconds: 300));
  //               }
  //             }),
  //       )),
  //     ],
  //   );
  // }

  _buildIndicatorDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(slideList.length, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 16 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Theme.of(context).colorScheme.fontColor
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  List<Widget> getList() {
    List<Widget> childs = [];

    for (int i = 0; i < slideList.length; i++) {
      childs.add(Container(
          width: 10.0,
          height: 10.0,
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == i
                ? Theme.of(context).colorScheme.fontColor
                : Theme.of(context).colorScheme.fontColor.withOpacity((0.5)),
          )));
    }
    return childs;
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    // SystemChrome.setEnabledSystemUIOverlays([]);

    return Scaffold(
        body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // skipBtn(),
          _slider(),
          // _buildIndicatorDots(),
          // _btn(),
        ],
      ),
    ));
  }
}

class Slide {
  final String imageUrl;
  final String? title;
  final String? description;

  Slide({
    required this.imageUrl,
    required this.title,
    required this.description,
  });
}
