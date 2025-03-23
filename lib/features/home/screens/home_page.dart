// lib/features/home/screens/home_page.dart

import 'package:Psiconnect/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '/navigation/nav_bar.dart';
import '../screens/contact_content.dart';
import '../screens/feature_content.dart';
import '../screens/home_content.dart';
import '../screens/screenshots_content.dart';

// Create a provider to expose scroll controllers
final homeScrollProvider = Provider<HomeScrollControllers>((ref) {
  return HomeScrollControllers();
});

// Class to hold all section scroll controllers
class HomeScrollControllers {
  final scrollController = ScrollController();
  final homeKey = GlobalKey();
  final featuresKey = GlobalKey();
  final screenshotsKey = GlobalKey();
  final contactKey = GlobalKey();
  
  void scrollToHome() {
    _scrollToSection(homeKey);
  }
  
  void scrollToFeatures() {
    _scrollToSection(featuresKey);
  }
  
  void scrollToScreenshots() {
    _scrollToSection(screenshotsKey);
  }
  
  void scrollToContact() {
    _scrollToSection(contactKey);
  }
  
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Parse section from query parameters and scroll to it
  void scrollToSectionFromQuery(BuildContext context) {
    final section = GoRouterState.of(context).uri.queryParameters['section'];
    if (section != null) {
      switch (section) {
        case 'services':
          scrollToFeatures();
          break;
        case 'contact':
          scrollToContact();
          break;
      }
    }
  }
}

// Updated HomePage with dark mode navbar and light mode content

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollControllers = ref.watch(homeScrollProvider);
    final scrollController = scrollControllers.scrollController;
    
    // Effect to handle query parameters when page loads
    useEffect(() {
      // Use a post-frame callback to ensure the context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollControllers.scrollToSectionFromQuery(context);
      });
      return null;
    }, []);

    return Scaffold(
      body: Column(
        children: [
          // Navbar in dark mode - this stays outside the Theme widget
          Theme(
            data: ThemeData.dark().copyWith(
              // Customize dark theme for navbar
              colorScheme: ColorScheme.dark(
                primary: AppColors.primaryColor,
                secondary: AppColors.primaryLight,
                surface: AppColors.primaryColor,
                background: AppColors.primaryColor,
              ),
              // Other customizations for the navbar
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            child: const NavBar(),
          ),
          
          // Content in light mode
          Expanded(
            child: Theme(
              // Override with light mode for content
              data: ThemeData.light().copyWith(
                // Customize light theme for content
                colorScheme: ColorScheme.light(
                  primary: AppColors.primaryLight,
                  secondary: AppColors.accentBlue,
                  background: Colors.white,
                  surface: Colors.white,
                ),
                scaffoldBackgroundColor: Colors.white,
                // Add other theme customizations for content
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: AppColors.primaryColor,
                  displayColor: AppColors.primaryColor,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.white,
                body: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Assign keys to each section
                      KeyedSubtree(
                        key: scrollControllers.homeKey,
                        child: const HomeContent(),
                      ),
                      KeyedSubtree(
                        key: scrollControllers.featuresKey,
                        child: FeaturesContent(),
                      ),
                      KeyedSubtree(
                        key: scrollControllers.screenshotsKey,
                        child: const ScreenshotsContent(),
                      ),
                      KeyedSubtree(
                        key: scrollControllers.contactKey,
                        child: ContactContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        child: const Icon(Icons.arrow_upward),
        tooltip: 'Volver arriba',
      ),
    );
  }
}
