// import 'dart:convert';
// import 'dart:developer';
// import 'package:carousel_slider/carousel_options.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// import '../Helper/Session.dart';
// import '../Model/SubscriptionModel.dart';
//
// class SubscriptionScreen extends StatefulWidget {
//   const SubscriptionScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SubscriptionScreen> createState() => _SubscriptionScreenState();
// }
//
// class _SubscriptionScreenState extends State<SubscriptionScreen> {
//   Razorpay _razorpay = Razorpay();
//   String? email;
//   String? userId;
//   String? phone;
//   int? price;
//   var amounts;
//   var planT;
//   var planI;
//
//   String planID = '';
//   String planeAmount = '';
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     // getUserDetails();
//     Future.delayed(Duration(milliseconds: 200), () {
//       return getPlans();
//     });
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _razorpay.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final height = mediaQuery.size.height;
//     final width = mediaQuery.size.width;
//     return Scaffold(
//         appBar: getSimpleAppBar(
//             getTranslated(context, "MYSUBSCRIPTIONS")!, context),
//         body: Padding(
//           padding: EdgeInsets.symmetric(
//               horizontal: width * 0.040, vertical: height * 0.014),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: height * 0.025),
//               plansModel == null
//                   ? const Center(
//                       child: CircularProgressIndicator(),
//                     )
//                   : plansModel!.data == null
//                       ? const Center(child: Text("No Data Found"))
//                       : SizedBox(
//                           height: MediaQuery.of(context).size.height * 0.5,
//                           width: MediaQuery.of(context).size.width * 0.8,
//                           child: CarouselSlider(
//                             options: CarouselOptions(
//                               autoPlayInterval: const Duration(seconds: 4),
//                               autoPlay: true,
//                               aspectRatio: .5,
//                               enlargeCenterPage: true,
//                               // enlargeStrategy: CenterPageEnlargeStrategy.height,
//                             ),
//                             items: plansModel!.data!
//                                 .map<Widget>((item) => Container(
//                                       margin: const EdgeInsets.all(5.0),
//                                       child: ClipRRect(
//                                           borderRadius: const BorderRadius.all(
//                                               Radius.circular(5.0)),
//                                           child: Column(
//                                             children: [
//                                               Expanded(
//                                                 child: Card(
//                                                   elevation: 5,
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             20.0),
//                                                   ),
//                                                   child: Padding(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             12.0),
//                                                     child:
//                                                         SingleChildScrollView(
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           SizedBox(
//                                                               height: height *
//                                                                   0.0125),
//                                                           item.price == 0
//                                                               ? const SizedBox
//                                                                   .shrink()
//                                                               : const Align(
//                                                                   alignment:
//                                                                       Alignment
//                                                                           .topRight,
//                                                                   child: Center(
//                                                                     child: Text(
//                                                                       "Special Offer",
//                                                                       style:
//                                                                           TextStyle(
//                                                                         color: Colors
//                                                                             .red,
//                                                                         fontWeight:
//                                                                             FontWeight.bold,
//                                                                       ),
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                           const SizedBox(
//                                                               height: 20),
//                                                           Text(
//                                                             item.name ?? "",
//                                                             style:
//                                                                 const TextStyle(
//                                                               fontSize: 18,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 20),
//                                                           Text(
//                                                             "${item.price.toString()}",
//                                                             style:
//                                                                 const TextStyle(
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                               fontSize: 30,
//                                                               color:
//                                                                   Colors.blue,
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 20),
//                                                           Text(
//                                                             "${item.trialDays} Days",
//                                                             style: const TextStyle(
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w600),
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           Html(
//                                                             data:
//                                                                 item.description ??
//                                                                     "",
//                                                             style: {
//                                                               "body": Style(
//                                                                   fontSize:
//                                                                       FontSize
//                                                                           .small),
//                                                             },
//                                                           ),
//                                                           const Divider(
//                                                               color:
//                                                                   Colors.blue),
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           const Row(
//                                                             children: [
//                                                               SizedBox(
//                                                                   width: 5),
//                                                               Icon(
//                                                                   Icons
//                                                                       .check_circle,
//                                                                   color: Color(
//                                                                       0xff0007a3),
//                                                                   size: 20),
//                                                               SizedBox(
//                                                                   width: 6),
//                                                               Expanded(
//                                                                 child: Text(
//                                                                   "Lifetime Service Support",
//                                                                   style: TextStyle(
//                                                                       color: Colors
//                                                                           .black,
//                                                                       fontSize:
//                                                                           16),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           const Row(
//                                                             children: [
//                                                               SizedBox(
//                                                                   width: 5),
//                                                               Icon(
//                                                                   Icons
//                                                                       .check_circle,
//                                                                   color: Color(
//                                                                       0xff0007a3),
//                                                                   size: 18),
//                                                               SizedBox(
//                                                                   width: 6),
//                                                               Expanded(
//                                                                 child: Text(
//                                                                   "User Priority Support",
//                                                                   style: TextStyle(
//                                                                       color: Colors
//                                                                           .black,
//                                                                       fontSize:
//                                                                           16),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           const Row(
//                                                             children: [
//                                                               SizedBox(
//                                                                   width: 5),
//                                                               Icon(
//                                                                   Icons
//                                                                       .check_circle,
//                                                                   color: Color(
//                                                                       0xff0007a3),
//                                                                   size: 18),
//                                                               SizedBox(
//                                                                   width: 6),
//                                                               Expanded(
//                                                                 child: Text(
//                                                                   "Basic Plan",
//                                                                   style: TextStyle(
//                                                                       color: Colors
//                                                                           .black,
//                                                                       fontSize:
//                                                                           16),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 20),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                               (item.price == 0 ||
//                                                       item.price == "0")
//                                                   ? Container()
//                                                   : ElevatedButton(
//                                                       style: ButtonStyle(
//                                                           backgroundColor:
//                                                               MaterialStateProperty
//                                                                   .all(Colors
//                                                                       .blue)),
//                                                       onPressed: () async {
//                                                         var userId =
//                                                             // await MyToken
//                                                             //     .getUserID();
//                                                             planI = item.id
//                                                                 .toString();
//                                                         if (item.price == 0 ||
//                                                             item.price == "0") {
//                                                           Fluttertoast.showToast(
//                                                               msg:
//                                                                   "Plan amount is not valid");
//                                                         } else {
//                                                           planID = item.id
//                                                               .toString();
//                                                           planeAmount = item
//                                                               .price
//                                                               .toString();
//                                                           checkOut(item.price);
//                                                         }
//                                                       },
//                                                       child: Text(
//                                                         "Buy Plan",
//                                                         style: TextStyle(
//                                                             color: Colors.white,
//                                                             fontSize: 16,
//                                                             fontWeight:
//                                                                 FontWeight
//                                                                     .bold),
//                                                       ))
//                                             ],
//                                           )),
//                                     ))
//                                 .toList(),
//                           ),
//                         ),
//             ],
//           ),
//         ));
//   }

import 'dart:convert';
import 'dart:developer';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/SubscriptionModel.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Razorpay _razorpay = Razorpay();
  String? email;
  String? userId;
  String? phone;
  int? price;
  var amounts;
  var planT;
  var planI;

  String planID = '';
  String planeAmount = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200), () {
      return getPlans();
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Color _getPlanColor(int index, dynamic price) {
    if (price == 0) return Colors.orange;
    switch (index % 4) {
      case 0:
        return colors.secondary;
      case 1:
        return colors.primary;
      case 2:
        return Colors.red;
      case 3:
        return const Color(0xFF4A5EAD);
      default:
        return Colors.blue;
    }
  }

  String _getPlanName(int index, String? originalName) {
    if (originalName != null && originalName.isNotEmpty) {
      return originalName;
    }
    switch (index % 4) {
      case 0:
        return "Light";
      case 1:
        return "Business";
      case 2:
        return "Pro";
      case 3:
        return "Unlimited";
      default:
        return "Plan";
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    final width = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          getTranslated(context, "MYSUBSCRIPTIONS") ?? "",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.02,
            vertical: height * 0.02,
          ),
          child: Column(
            children: [
              Text(
                "Choose Your Plan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: height * 0.01),
              Text(
                "Select the perfect plan for your needs",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: height * 0.03),
              plansModel == null
                  ? SizedBox(
                      height: height * 0.6,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : plansModel!.data == null || plansModel!.data!.isEmpty
                      ? SizedBox(
                          height: height * 0.6,
                          child: const Center(
                            child: Text(
                              "No Plans Available",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: height * 0.65,
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: height * 0.65,
                              autoPlay: false,
                              enlargeCenterPage: true,
                              enlargeFactor: 0.25,
                              viewportFraction: 0.85,
                              enableInfiniteScroll: false,
                            ),
                            items: plansModel!.data!
                                .asMap()
                                .entries
                                .map<Widget>((entry) {
                              int index = entry.key;
                              var item = entry.value;
                              return _buildPricingCard(item, index, context);
                            }).toList(),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(dynamic item, int index, BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final planColor = _getPlanColor(index, item.price);
    final planName = _getPlanName(index, item.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: planColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              planName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (item.trialDays != null)
                    _buildInfoRow("Trial Days: ${item.trialDays}"),
                  const SizedBox(height: 12),
                  _buildInfoRow("Lifetime Service Support"),
                  const SizedBox(height: 12),
                  _buildInfoRow("User Priority Support"),
                  const SizedBox(height: 12),
                  _buildInfoRow("Basic Plan"),
                  if (item.description != null &&
                      item.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Html(
                        data: item.description ?? "",
                        style: {
                          "body": Style(
                            fontSize: FontSize.small,
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                        },
                      ),
                    ),
                  ],

                  const Spacer(),
                  if (item.price != 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Text(
                        "Special Offer",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Price
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: planColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.price == 0 ? "free" : "${item.price}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (item.price != 0 && item.price != "0")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          planI = item.id.toString();
                          if (item.price == 0 || item.price == "0") {
                            Fluttertoast.showToast(
                                msg: "Plan amount is not valid");
                          } else {
                            planID = item.id.toString();
                            planeAmount = item.price.toString();
                            checkOut(item.price);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: planColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Buy Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  SubscriptionModel? plansModel;

  getPlans() async {
    var headers = {
      'Cookie': 'ci_session=f1791de67399698ea2182039c6d53618b1741266'
    };

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl}get_subscriptions'),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final str = await response.stream.bytesToString();
      print(str);
      var finalResponse = SubscriptionModel.fromJson(json.decode(str));
      setState(() {
        plansModel = finalResponse;
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  checkOut(planAmount) {
    // Example: "₹ 500.00" -> 50000
    int getAmountInPaise(String planAmount) {
      // Sabse pehle ₹ aur space aur decimal hatao
      String cleaned = planAmount.replaceAll("₹", "").trim();
      cleaned = cleaned.replaceAll(",", ""); // agar 1,000 format aa raha ho
      double value = double.tryParse(cleaned) ?? 0.0;
      return (value * 100).toInt(); // Razorpay paise me chahta hai
    }

    print(price);
    var options = {
      'key': "rzp_test_1DP5mmOlF5G5ag",
      // 'amount': price * 100,
      'amount': getAmountInPaise(planAmount),
      'currency': 'INR',
      'name': 'Ruvanshi',
      'description': '',
      "image":
          "https://developmentalphawizz.com/uploads/logo/Antsnest-fev1.png",
    };
    print("OPTIONS ===== $options");
    _razorpay.open(options);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setSnackbar("Payment Successful", context);
    purchasePlan(
        planId: planID, txnId: "${response.paymentId}", amount: planeAmount);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("FAILURE === ${response.message}");
    setSnackbar("Payment Failed", context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}
}

Future<void> purchasePlan({
  required String planId,
  required String txnId,
  required String amount,
}) async {
  var headers = {
    'Cookie': 'ci_session=ce3bc2711eacad5e95ef13803d905eeaeb8e9239'
  };

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${baseUrl}buy_subscription'),
  );

  request.fields.addAll({
    'user_id': CUR_USERID.toString(),
    'plan_id': planId,
    'amount': amount,
    'payment_gateway': 'razorpay',
    'payment_status': 'paid',
    'gateway_payment_id': txnId,
    'gateway_invoice_id': '12345',
  });

  request.headers.addAll(headers);

  print("PURCHASE PLAN PARAMS => ${request.fields}");

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final str = await response.stream.bytesToString();
    print("Response: $str");
  } else {
    print("Error: ${response.reasonPhrase}");
  }
}
