class SubscriptionListModel {
  bool? error;
  String? message;
  SubscriptionData? data;

  SubscriptionListModel({this.error, this.message, this.data});

  SubscriptionListModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    message = json['message'];
    data = json['data'] != null
        ? new SubscriptionData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SubscriptionData {
  String? id;
  String? planName;
  String? description;
  String? price;
  String? status;
  String? startDate;
  String? endDate;
  String? createdAt;
  String? username;
  String? mobile;
  String? email;

  SubscriptionData(
      {this.id,
      this.planName,
      this.description,
      this.price,
      this.status,
      this.startDate,
      this.endDate,
      this.createdAt,
      this.username,
      this.mobile,
      this.email});

  SubscriptionData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    planName = json['plan_name'];
    description = json['description'];
    price = json['price'];
    status = json['status'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    createdAt = json['created_at'];
    username = json['username'];
    mobile = json['mobile'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['plan_name'] = this.planName;
    data['description'] = this.description;
    data['price'] = this.price;
    data['status'] = this.status;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['created_at'] = this.createdAt;
    data['username'] = this.username;
    data['mobile'] = this.mobile;
    data['email'] = this.email;
    return data;
  }
}
