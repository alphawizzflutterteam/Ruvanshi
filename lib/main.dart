import 'package:TGSawadesiMartUser/Helper/Color.dart';
import 'package:TGSawadesiMartUser/Helper/Constant.dart';
import 'package:TGSawadesiMartUser/Provider/CartProvider.dart';
import 'package:TGSawadesiMartUser/Provider/CategoryProvider.dart';
import 'package:TGSawadesiMartUser/Provider/FavoriteProvider.dart';
import 'package:TGSawadesiMartUser/Provider/HomeProvider.dart';
import 'package:TGSawadesiMartUser/Provider/ProductDetailProvider.dart';
import 'package:TGSawadesiMartUser/Provider/UserProvider.dart';
import 'package:TGSawadesiMartUser/Screen/Splash.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Helper/Demo_Localization.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Helper/notification_service.dart';
import 'Provider/Theme.dart';
import 'Provider/SettingProvider.dart';
import 'Provider/order_provider.dart';
import 'Screen/Dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestLocationPermission();
  await Firebase.initializeApp();
  //initializedDownload();
  LocalNotificationService.initialize();
  // FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  FirebaseMessaging.instance.getToken().then((value) {
    String fcmToken = value!;

    print("fcm is ${fcmToken}");
  });

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (BuildContext context) {
        String? theme = prefs.getString(APP_THEME);

        if (theme == DARK)
          ISDARK = "true";
        else if (theme == LIGHT) ISDARK = "false";

        if (theme == null || theme == "" || theme == DEFAULT_SYSTEM) {
          prefs.setString(APP_THEME, DEFAULT_SYSTEM);
          var brightness = SchedulerBinding.instance!.window.platformBrightness;
          ISDARK = (brightness == Brightness.dark).toString();

          return ThemeNotifier(ThemeMode.system);
        }

        return ThemeNotifier(theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
      },
      child: MyApp(sharedPreferences: prefs),
    ),
  );
}

Future<void> _requestLocationPermission() async {
  // Check if the permission is already granted
  if (await Permission.location.isGranted) {
    return;
  }

  // Request permission
  var status = await Permission.location.request();

  // Check the status and handle accordingly
  if (status.isGranted) {
    print("Location permission granted");
  } else {
    print("Location permission denied");
    // Handle the denial, for example, show a message or disable location-based features
  }
}

Future<void> initializedDownload() async {}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  late SharedPreferences sharedPreferences;

  MyApp({Key? key, required this.sharedPreferences}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    if (mounted)
      setState(() {
        _locale = locale;
      });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      if (mounted)
        setState(() {
          this._locale = locale;
        });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: colors.primary));
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (this._locale == null) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color?>(colors.primary)),
        ),
      );
    } else {
      return MultiProvider(
          providers: [
            Provider<SettingProvider>(
              create: (context) => SettingProvider(widget.sharedPreferences),
            ),
            ChangeNotifierProvider<UserProvider>(
                create: (context) => UserProvider()),
            ChangeNotifierProvider<HomeProvider>(
                create: (context) => HomeProvider()),
            ChangeNotifierProvider<CategoryProvider>(
                create: (context) => CategoryProvider()),
            ChangeNotifierProvider<ProductDetailProvider>(
                create: (context) => ProductDetailProvider()),
            ChangeNotifierProvider<FavoriteProvider>(
                create: (context) => FavoriteProvider()),
            ChangeNotifierProvider<OrderProvider>(
                create: (context) => OrderProvider()),
            ChangeNotifierProvider<CartProvider>(
                create: (context) => CartProvider()),
          ],
          child: MaterialApp(
            //scaffoldMessengerKey: rootScaffoldMessengerKey,
            locale: _locale,
            supportedLocales: [
              Locale("en", "US"),
              Locale("zh", "CN"),
              Locale("es", "ES"),
              Locale("hi", "IN"),
              Locale("ar", "DZ"),
              Locale("ru", "RU"),
              Locale("ja", "JP"),
              Locale("de", "DE")
            ],
            localizationsDelegates: [
              CountryLocalizations.delegate,
              DemoLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale!.languageCode &&
                    supportedLocale.countryCode == locale.countryCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            title: appName,

            // theme: ThemeData(
            //   canvasColor: Theme.of(context).colorScheme.lightWhite,
            //   cardColor: Theme.of(context).colorScheme.white,
            //   dialogBackgroundColor: Theme.of(context).colorScheme.white,
            //   iconTheme:
            //       Theme.of(context).iconTheme.copyWith(color: colors.primary),
            //   primarySwatch: colors.primary_app,
            //   primaryColor: Theme.of(context).colorScheme.lightWhite,
            //   fontFamily: 'opensans',
            //   brightness: Brightness.light,
            //   textTheme: TextTheme(
            //           titleLarge: TextStyle(
            //             color: Theme.of(context).colorScheme.fontColor,
            //             fontWeight: FontWeight.w600,
            //           ),
            //           titleMedium: TextStyle(
            //               color: Theme.of(context).colorScheme.fontColor,
            //               fontWeight: FontWeight.bold))
            //       .apply(bodyColor: Theme.of(context).colorScheme.fontColor),
            // ),
            theme: ThemeData(
              canvasColor: Theme.of(context).colorScheme.lightWhite,
              cardColor: Theme.of(context).colorScheme.white,
              dialogBackgroundColor: Theme.of(context).colorScheme.white,
              iconTheme:
                  Theme.of(context).iconTheme.copyWith(color: colors.primary),
              primarySwatch: colors.primary_app,
              primaryColor: Theme.of(context).colorScheme.lightWhite,
              fontFamily: 'opensans',
              brightness: Brightness.light,
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  // 🔁 titleLarge → titleLarge
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  // 🔁 titleMedium → titleMedium
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                ),
              ).apply(
                bodyColor: Theme.of(context).colorScheme.fontColor,
              ),
            ),

            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => Splash(),
              '/home': (context) => Dashboard(),
            },
            darkTheme: ThemeData(
              canvasColor: colors.darkColor,
              cardColor: colors.darkColor2,
              dialogBackgroundColor: colors.darkColor2,
              primaryColor: colors.darkColor,
              textSelectionTheme: TextSelectionThemeData(
                  cursorColor: colors.darkIcon,
                  selectionColor: colors.darkIcon,
                  selectionHandleColor: colors.darkIcon),
              fontFamily: 'opensans',
              brightness: Brightness.light,
              iconTheme:
                  Theme.of(context).iconTheme.copyWith(color: colors.secondary),
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  // 🔁 titleLarge → titleLarge
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  // 🔁 titleMedium → titleMedium
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                ),
              ).apply(bodyColor: Theme.of(context).colorScheme.fontColor),
              colorScheme:
                  ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
                      .copyWith(secondary: colors.darkIcon),
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return null;
                  }
                  if (states.contains(MaterialState.selected)) {
                    return colors.primary;
                  }
                  return null;
                }),
              ),
              radioTheme: RadioThemeData(
                fillColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return null;
                  }
                  if (states.contains(MaterialState.selected)) {
                    return colors.primary;
                  }
                  return null;
                }),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return null;
                  }
                  if (states.contains(MaterialState.selected)) {
                    return colors.primary;
                  }
                  return null;
                }),
                trackColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return null;
                  }
                  if (states.contains(MaterialState.selected)) {
                    return colors.primary;
                  }
                  return null;
                }),
              ),
            ),
            themeMode: themeNotifier.getThemeMode(),
          ));
    }
  }
}
