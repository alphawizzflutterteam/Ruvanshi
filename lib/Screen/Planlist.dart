import 'dart:convert';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Helper/Constant.dart';
import '../Helper/NoData.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/SubscriptionListModel.dart';

class PlanListScreen extends StatefulWidget {
  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  late Future my;

  @override
  void initState() {
    // TODO: implement initState
    my = getPlanList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getSimpleAppBar(
          getTranslated(context, 'MYSUBSCRIPTIONSLIST')!, context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: my,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (subscriptionListModel == null ||
                subscriptionListModel!.data == null) {
              return NoDataFound(slug: 'Subscription');
            }
            var plan = subscriptionListModel!.data!;
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(1, 1),
                    blurRadius: 5,
                    color: Colors.grey.shade300,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User Name: ${plan.username ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("User Mobile: ${plan.mobile ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Plan Name: ${plan.planName ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Amount: ${plan.price ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Start Date: ${plan.startDate ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("End Date: ${plan.endDate ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Duration: ${plan.billingInfo ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Description: ${plan.description ?? ''}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SubscriptionListModel? subscriptionListModel;

  Future<void> getPlanList() async {
    try {
      var headers = {
        'Cookie': 'ci_session=0e3727cdd5c81698ee3ef27562dea504302eb82e'
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}get_user_subscription_info'),
      );
      request.fields.addAll({
        'user_id': CUR_USERID.toString(),
      });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseBody);

        subscriptionListModel = SubscriptionListModel.fromJson(jsonData);

        if (subscriptionListModel != null &&
            subscriptionListModel!.data != null) {
          var plan = subscriptionListModel!.data!;
          print("Plan Name: ${plan.planName}");
          setState(() {});
        } else {
          print("No subscription found");
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }
}
