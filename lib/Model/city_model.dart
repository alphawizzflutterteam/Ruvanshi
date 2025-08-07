import 'dart:convert';


class CityListModel {
    final String? id;
    final String? name;

    CityListModel({
        this.id,
        this.name,
    });

    factory CityListModel.fromRawJson(String str) => CityListModel.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory CityListModel.fromJson(Map<String, dynamic> json) => CityListModel(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}
