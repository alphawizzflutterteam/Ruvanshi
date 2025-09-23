class WelcomeOfferModel {
  bool? error;
  String? message;
  int? total;
  List<WelcomeOfferData>? data;

  WelcomeOfferModel({this.error, this.message, this.total, this.data});

  WelcomeOfferModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    message = json['message'];
    total = json['total'];
    if (json['data'] != null) {
      data = <WelcomeOfferData>[];
      json['data'].forEach((v) {
        data!.add(new WelcomeOfferData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['message'] = this.message;
    data['total'] = this.total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class WelcomeOfferData {
  String? id;
  String? title;
  String? message;
  String? imageUrl;
  String? popupType;
  String? startDate;
  String? endDate;
  String? isActive;
  String? priority;
  String? createdAt;
  String? updatedAt;

  WelcomeOfferData(
      {this.id,
      this.title,
      this.message,
      this.imageUrl,
      this.popupType,
      this.startDate,
      this.endDate,
      this.isActive,
      this.priority,
      this.createdAt,
      this.updatedAt});

  WelcomeOfferData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    message = json['message'];
    imageUrl = json['image_url'];
    popupType = json['popup_type'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    isActive = json['is_active'];
    priority = json['priority'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['message'] = this.message;
    data['image_url'] = this.imageUrl;
    data['popup_type'] = this.popupType;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['is_active'] = this.isActive;
    data['priority'] = this.priority;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
