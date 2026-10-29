import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:bitSave/state.dart';
import 'package:bitSave/ui/common/app_colors.dart';
import 'core/utils/local_stotage.dart';
import 'core/utils/local_store_dir.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register services / locator for use in viewmodels
  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    fetchUiState();
    super.initState();
  }

  void fetchUiState() async {
    String? savedMode =
    await locator<LocalStorage>().fetch(LocalStorageDir.uiMode);
    if (savedMode != null) {
      switch (savedMode) {
        case "light":
          uiMode.value = AppUiModes.light;
          break;
        case "dark":
          uiMode.value = AppUiModes.dark;
      }
    }
  }

  BoxDecoration _getBackgroundDecoration(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? kcGradientDecoration
        : kcLightBackgroundDecoration;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUiModes>(
      valueListenable: uiMode,
      builder: (context, value, child) => MaterialApp(
        title: 'bitSave',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: value == AppUiModes.dark ? ThemeMode.dark : ThemeMode.light,
        initialRoute: Routes.startupView,
        onGenerateRoute: StackedRouter().onGenerateRoute,
        navigatorKey: StackedService.navigatorKey,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [StackedService.routeObserver],
        builder: (context, child) {
          return Container(
            decoration: _getBackgroundDecoration(context),
            child: child!,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: kcWhiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kcBlackColor),
        titleTextStyle: GoogleFonts.redHatDisplay(
          color: kcBlackColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: kcWhiteColor,
        selectedItemColor: kcPrimaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kcWhiteColor),
        titleTextStyle: GoogleFonts.redHatDisplay(
          color: kcWhiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: kcWhiteColor,
        unselectedItemColor: kcWhiteColor.withOpacity(0.5),
      ),
    );
  }
}