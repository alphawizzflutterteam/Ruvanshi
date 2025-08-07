import 'dart:io';
import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Helper/Constant.dart';
import 'package:TGSawadesiMartUser/Helper/Public%20Api/api.dart';
import 'package:TGSawadesiMartUser/Helper/Session.dart';
import 'package:TGSawadesiMartUser/Helper/widgets.dart';
import 'package:TGSawadesiMartUser/Model/UpdateUserModels.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:TGSawadesiMartUser/Screen/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool edit = true;
  DateTime selectedDate = DateTime.now();

  var userNameController = TextEditingController();
  var emailController = TextEditingController();
  var dob;

  String? newDob;
  //image

  File? _image;
  final picker = ImagePicker();

  String? typeImage;

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _cropImage(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<Null> _cropImage(image) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image,
        aspectRatio: const CropAspectRatio(ratioX: 400, ratioY: 400)
        // aspectRatioPresets: Platform.isAndroid
        //     ? [
        //         CropAspectRatioPreset.square,
        //       ]
        //     : [
        //         CropAspectRatioPreset.square,
        //       ],
        /* androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'ZuqZuq',
            toolbarColor: colors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        )*/
        );
    if (croppedFile != null) {
      showToast("Uploading Image");
      _image = File(croppedFile.path);
      setState(() {});
      UpdateUserModels? model = await uploadImage(
          typeImage == "pro" ? "image" : "bank_pass", _image!.path);
      if (model!.error == false) {
        setState(() {
          showToast(model.message);
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: FutureBuilder(
            future: userDetails(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                var user = snapshot.data;
                if (selCityPos == null || selCityPos == -1) {
                  cityId = user.date[0].city;
                  for (int i = 0; i < cityList.length; i++) {
                    if (cityList[i].id == cityId) {
                      selCityPos = i;
                      break;
                    }
                  }
                  // Set selected city position
                }

                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon: Icon(Icons.arrow_back)),
                    backgroundColor: Colors.white,
                    iconTheme: IconThemeData(color: colors.primary),
                    actions: [
                      edit
                          ? TextButton(
                              onPressed: () {
                                setState(() {
                                  edit = false;
                                  userNameController.text =
                                      user!.date![0].username;
                                  emailController.text = user!.date![0].email;
                                  dob = user!.date![0].dob;
                                });
                              },
                              child: Text("Edit",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: colors.primary)))
                          : TextButton(
                              onPressed: () async {
                                if (dob != null) {
                                  DateTime date = selectedDate;
                                  var userName = userNameController.text;
                                  var email = emailController.text;
                                  var updateDOB = dob == null
                                      ? "${date.day}-${date.month}-${date.year}"
                                      : dob;
                                  UpdateUserModels? model =
                                      await updateUserDetails(
                                          userName, email, updateDOB, cityId);
                                  if (model!.error == false) {
                                    setState(() {
                                      showToast(model.message);
                                      edit = true;
                                      UserProvider userProvider =
                                          Provider.of<UserProvider>(context,
                                              listen: false);
                                      userProvider.setName(userName);
                                      userProvider.setEmail(email);
                                      // userProvider.mob(updateDOB);
                                    });
                                  } else {
                                    showToast(model.message);
                                  }
                                } else {
                                  showToast("Select Date");
                                }
                                setState(() {});
                              },
                              child: Text(
                                "Save",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colors.primary),
                              ))
                    ],
                    title: Text(
                      "Profile",
                      style: TextStyle(color: colors.primary),
                    ),
                  ),
                  body: ListView(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      edit
                          ? Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    user!.date![0].proPic != ""
                                        ? CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 50,
                                            backgroundImage: NetworkImage(
                                                "$imageUrl${user!.date![0].proPic}"),
                                          )
                                        : CircleAvatar(
                                            radius: 50,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                    CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                            onPressed: () {
                                              typeImage = "pro";
                                              getImage();
                                            },
                                            icon: Icon(
                                              Icons.edit,
                                              color: colors.primary,
                                              size: 15,
                                            )))
                                  ],
                                ),
                                ListTile(
                                  leading: Icon(Icons.person),
                                  title: Text("User Name"),
                                  trailing: Text("${user!.date![0].username}"),
                                ),
                                ListTile(
                                  leading: Icon(Icons.email),
                                  title: Text("Email Id"),
                                  trailing: Text("${user!.date![0].email}"),
                                ),
                                ListTile(
                                  leading: Icon(Icons.call),
                                  title: Text("Phone Number"),
                                  trailing: Text("${user!.date![0].mobile}"),
                                ),
                                ListTile(
                                  leading: Icon(Icons.accessibility),
                                  title: Text("Gender"),
                                  trailing: Text("${user!.date![0].gender}"),
                                ),
                                ListTile(
                                  leading: Icon(Icons.accessibility),
                                  title: Text("City"),
                                  trailing: Text(
                                      "${cityList[selCityPos!].name ?? ""}"),
                                ),
                                ListTile(
                                  leading: Icon(Icons.date_range),
                                  title: Text("Date Of Birth"),
                                  trailing: user!.date![0].dob != null
                                      ? Text("${user!.date![0].dob}")
                                      : TextButton(
                                          onPressed: () {
                                            setState(() {
                                              edit = false;
                                              userNameController.text =
                                                  user!.date![0].username;
                                              emailController.text =
                                                  user!.date![0].email;
                                              dob = user!.date![0].dob;
                                            });
                                          },
                                          child: Text("Update")),
                                ),
                                ListTile(
                                  leading: Icon(Icons.document_scanner),
                                  title: Text("Upload Passbook"),
                                  trailing: TextButton(
                                    onPressed: () {
                                      typeImage = "pas";
                                      getImage();
                                    },
                                    child: Text("Upload"),
                                  ),
                                  subtitle: user!.date![0].bankPass != ""
                                      ? Container(
                                          height: 170,
                                          width: 150,
                                          child: Image.network(
                                            "$imageUrl${user!.date![0].bankPass}",
                                          ),
                                        )
                                      : Text(""),
                                )
                              ],
                            )
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: userNameController,
                                      decoration: InputDecoration(
                                          label: Text("User Name")),
                                    ),
                                    TextField(
                                      controller: emailController,
                                      decoration:
                                          InputDecoration(label: Text("Email")),
                                    ),
                                    getDob(),
                                    setCities()

                                    ///ds
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Icon(Icons.error_outline);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }

  setCities() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: GestureDetector(
            child: InputDecorator(
              decoration: InputDecoration(
                fillColor: Theme.of(context).colorScheme.surface,
                isDense: true,
                border: InputBorder.none,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslated(context, 'CITYSELECT_LBL') ??
                              'Select City',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          selCityPos != null && selCityPos != -1
                              ? cityList[selCityPos!].name ?? ""
                              : "Select a city",
                          style: TextStyle(
                            color: selCityPos != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
            onTap: () {
              cityDialog();
            },
          ),
        ),
      ),
    );
  }

  getDob() {
    DateTime date = selectedDate;
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: ListTile(
        onTap: () {
          _selectDate(context);
        },
        title: Text("Select Date Of Birth"),
        subtitle: dob != null ? Text(dob) : Text("dd-mm-yy"),
        trailing: Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  String cityId = "";

  // cityDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setStater) {
  //           cityState = setStater;
  //           return AlertDialog(
  //             contentPadding: const EdgeInsets.all(0.0),
  //             // shape: RoundedRectangleBorder(
  //             //   borderRadius: BorderRadius.all(
  //             //     Radius.circular(5.0),
  //             //   ),
  //             // ),
  //             content: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Padding(
  //                   padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
  //                   child: Text(
  //                     getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
  //                     style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurface),
  //                   ),
  //                 ),
  //                 Divider(color: Theme.of(context).colorScheme.onSurface),
  //                 Flexible(
  //                   child: SingleChildScrollView(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: cityList.map((city) {
  //                         return InkWell(
  //                           onTap: () {
  //                             selCityPos = cityList.indexOf(city);
  //                             cityId = city.id ?? '';
  //                             Navigator.pop(context);
  //                             setState(() {});
  //                           },
  //                           child: Container(
  //                             margin: EdgeInsets.symmetric(
  //                                 vertical: 5, horizontal: 10),
  //                             padding: EdgeInsets.all(10),
  //                             // decoration: BoxDecoration(
  //                             //   color: Colors.grey[200],
  //                             //   borderRadius: BorderRadius.circular(8),
  //                             //   boxShadow: [
  //                             //     BoxShadow(
  //                             //       color: Colors.grey.withOpacity(0.5),
  //                             //       spreadRadius: 1,
  //                             //       blurRadius: 3,
  //                             //       offset: Offset(0, 2),
  //                             //     ),
  //                             //   ],
  //                             // ),
  //                             child: Text(
  //                               city.name ?? '',
  //                               style: TextStyle(
  //                                   fontSize: 16, fontWeight: FontWeight.w500),
  //                             ),
  //                           ),
  //                         );
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  //new
  cityDialog() {
    List filteredCities = List.from(cityList);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            void filterCities(String query) {
              query = query.trim().toLowerCase();
              filteredCities = cityList.where((city) {
                return (city.name ?? '').toLowerCase().contains(query);
              }).toList();
              setStater(() {}); // rebuild
            }

            cityState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                    child: Text(
                      getTranslated(context, 'CITYSELECT_LBL') ?? 'Select City',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: TextField(
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
                  Flexible(
                    child: filteredCities.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                getTranslated(context, 'NO_CITY_FOUND') ??
                                    'No city found',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filteredCities.map((city) {
                                return InkWell(
                                  onTap: () {
                                    selCityPos = cityList.indexOf(city);
                                    cityId = city.id ?? '';
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      city.name ?? '',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
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

  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1970),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFD7AF33),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            child: child!,
          );
        });
    if (selected != null && selected != selectedDate)
      setState(() {
        selectedDate = selected;
        DateTime date = selectedDate;
        dob = "${date.day}-${date.month}-${date.year}";
      });
  }
}
