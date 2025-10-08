import 'package:cached_network_image/cached_network_image.dart';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Helper/String.dart';
import 'package:TGSawadesiMartUser/Provider/CategoryProvider.dart';
import 'package:TGSawadesiMartUser/Provider/HomeProvider.dart';
import 'package:TGSawadesiMartUser/Screen/SubCategory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../Helper/Session.dart';
import '../Model/Section_Model.dart';
import 'HomePage.dart';
import 'ProductList.dart';

class AllCategory extends StatefulWidget {
  @override
  State<AllCategory> createState() => _AllCategoryState();
}

class _AllCategoryState extends State<AllCategory> {
  @override
  void initState() {
    super.initState();
    getCat();
  }

  Future<void> getCat() async {
    await Future.delayed(Duration.zero);
    Map parameter = {
      CAT_FILTER: "false",
    };
    apiBaseHelper.postAPICall(getCatApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        print("CATEGORY PARAMETER PRINT HERE${getCatApi.toString()}");
        print(parameter.toString());

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
        Fluttertoast.showToast(msg: msg!, backgroundColor: colors.primary);
      }

      context.read<HomeProvider>().setCatLoading(false);
    }, onError: (error) {
      Fluttertoast.showToast(msg: error, backgroundColor: colors.primary);
      context.read<HomeProvider>().setCatLoading(false);
    });
  }

  Widget catLoading() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: 9,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.white,
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
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 12,
                  color: Colors.grey[200],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.grad1Color1,
      body: _catList(),
    );
  }

  Widget catItem(int index, BuildContext context1) {
    return Selector<CategoryProvider, int>(
      builder: (context, data, child) {
        if (index == 0 && (popularList.length > 0)) {
          return GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: data == index
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
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
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        data == index
                            ? imagePath + "popular_sel.svg"
                            : imagePath + "popular.svg",
                        color: colors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      catList[index].name!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context1).textTheme.bodySmall!.copyWith(
                            color: data == index
                                ? colors.primary
                                : Theme.of(context).colorScheme.fontColor,
                            fontSize: 11,
                            fontFamily: dynamicFontFamily.fontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              context1.read<CategoryProvider>().setCurSelected(index);
              context1.read<CategoryProvider>().setSubList(popularList);
            },
          );
        } else {
          return GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: data == index
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: catList[index].image ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(colors.primary),
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
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      catList[index].name ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context1).textTheme.bodySmall!.copyWith(
                            color: data == index
                                ? colors.primary
                                : Theme.of(context).colorScheme.fontColor,
                            fontSize: 11,
                            fontFamily: dynamicFontFamily.fontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              context1.read<CategoryProvider>().setCurSelected(index);
              if (catList[index].subList == null ||
                  catList[index].subList!.length == 0) {
                context1.read<CategoryProvider>().setSubList([]);
                Navigator.push(
                  context1,
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
                context1
                    .read<CategoryProvider>()
                    .setSubList(catList[index].subList);
              }
            },
          );
        }
      },
      selector: (_, cat) => cat.curCat,
    );
  }

  _catList() {
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
                                        fontFamily:
                                            dynamicFontFamily.fontFamily,
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

  subCatItem(List<Product> subList, int index, BuildContext context) {
    return GestureDetector(
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
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: subList[index].image ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.primary),
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
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  subList[index].name ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: dynamicFontFamily.fontFamily),
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        if (context.read<CategoryProvider>().curCat == 0 &&
            popularList.length > 0) {
          if (popularList[index].subList == null ||
              popularList[index].subList!.length == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  name: popularList[index].name,
                  id: popularList[index].id,
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
                  subList: popularList[index].subList,
                  title: popularList[index].name ?? "",
                ),
              ),
            );
          }
        } else if (subList[index].subList == null ||
            subList[index].subList!.length == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductList(
                name: subList[index].name,
                id: subList[index].id,
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
                subList: subList[index].subList,
                title: subList[index].name ?? "",
              ),
            ),
          );
        }
      },
    );
  }
}
