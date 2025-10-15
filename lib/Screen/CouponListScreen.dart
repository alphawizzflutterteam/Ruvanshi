import 'dart:convert';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Screen/CoupanProductList.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Helper/Constant.dart';
import '../Helper/NoData.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Coupon_Model.dart';

// Test
class CouponListScreen extends StatefulWidget {
  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  late Future my;

  @override
  void initState() {
    my = getCouponList();
    super.initState();
  }

  CouponListModel? couponListModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          getSimpleAppBar(getTranslated(context, "MY_COUPON_LBL")!, context),
      body: FutureBuilder(
        future: my,
        builder: (context, s) {
          return s.connectionState == ConnectionState.waiting
              ? Center(child: CircularProgressIndicator())
              : couponListModel == null || couponListModel!.data?.length == 0
                  ? NoDataFound(slug: '')
                  : GridView.builder(
                      shrinkWrap: true,
                      itemCount: couponListModel!.data!.length,
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final item = couponListModel!.data![index];
                        return GestureDetector(
                          onTap: () {
                            print("itetetet $item");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoupanProductList(
                                  name: item.promoCode,
                                  id: item.id,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(
                                      0, 0), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      item.image ?? "",
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              erroWidget(80),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    item.promoCode ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontFamily:
                                            dynamicFontFamily.fontFamily),
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Promo Code
                                Text(
                                  item.message ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  item.endDate != null
                                      ? "Valid till ${item.endDate}"
                                      : "Expires Soon",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: dynamicFontFamily.fontFamily),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
        },
      ),
    );
  }

  Future<void> getCouponList() async {
    var request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}get_promo_codes'));
    request.fields.addAll({
      'user_id': CUR_USERID.toString(),
    });
    http.StreamedResponse response = await request.send();
    var json = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode == 200) {
      couponListModel = CouponListModel.fromJson(json);
      if (couponListModel != null &&
          couponListModel!.data != null &&
          couponListModel!.data!.isNotEmpty) {
        setState(() {});
      } else {
        print(response.reasonPhrase);
      }
    }
  }
}
