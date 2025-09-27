class SubscriptionModel {
  bool? error;
  int? total;
  String? message;
  List<Data>? data;

  SubscriptionModel({this.error, this.total, this.message, this.data});

  SubscriptionModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    total = json['total'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['total'] = this.total;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? id;
  String? name;
  String? description;
  String? price;
  String? billingInfo;
  String? trialDays;
  String? status;
  String? createdAt;

  Data(
      {this.id,
      this.name,
      this.description,
      this.price,
      this.billingInfo,
      this.trialDays,
      this.status,
      this.createdAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    billingInfo = json['billing_info'];
    trialDays = json['trial_days'];
    status = json['status'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['price'] = this.price;
    data['billing_info'] = this.billingInfo;
    data['trial_days'] = this.trialDays;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    return data;
  }
}
