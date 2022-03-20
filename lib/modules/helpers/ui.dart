import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:utilx/utils.dart';

abstract class ResponsiveSizes {
  static const int xs = 480;
  static const int sm = 640;
  static const int md = 768;
  static const int lg = 1024;
  static const int xl = 1280;

  static bool isXs(final double size) => size > xs;
  static bool isSm(final double size) => size > sm;
  static bool isMd(final double size) => size > md;
  static bool isLg(final double size) => size > lg;
  static bool isXl(final double size) => size > xl;
}

class ResponsiveSize extends Size {
  const ResponsiveSize({
    required final double width,
    required final double height,
  }) : super(width, height);

  factory ResponsiveSize.fromSize(final Size size) =>
      ResponsiveSize(height: size.height, width: size.width);

  factory ResponsiveSize.fromContext(final BuildContext context) =>
      ResponsiveSize.fromSize(MediaQuery.of(context).size);

  bool get isXs => ResponsiveSizes.isXs(width);
  bool get isSm => ResponsiveSizes.isSm(width);
  bool get isMd => ResponsiveSizes.isMd(width);
  bool get isLg => ResponsiveSizes.isLg(width);
  bool get isXl => ResponsiveSizes.isXl(width);
}

abstract class Palette {
  static const MaterialColor indigo = MaterialColor(0xFF6366F1, <int, Color>{
    50: Color(0xFFEEF2FF),
    100: Color(0xFFE0E7FF),
    200: Color(0xFFC7D2FE),
    300: Color(0xFFA5B4FC),
    400: Color(0xFF818CF8),
    500: Color(0xFF6366F1),
    600: Color(0xFF4F46E5),
    700: Color(0xFF4338CA),
    800: Color(0xFF3730A3),
    900: Color(0xFF312E81)
  });

  static const MaterialColor gray = MaterialColor(0xFF6366F1, <int, Color>{
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF4F4F5),
    200: Color(0xFFE4E4E7),
    300: Color(0xFFD4D4D8),
    400: Color(0xFFA1A1AA),
    500: Color(0xFF71717A),
    600: Color(0xFF52525B),
    700: Color(0xFF3F3F46),
    800: Color(0xFF27272A),
    900: Color(0xFF18181B)
  });

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Palette.indigo[500],
    primarySwatch: Palette.indigo,
    backgroundColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Palette.gray[100],
    fontFamily: 'Poppins',
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Palette.indigo[500],
    primarySwatch: Palette.indigo,
    backgroundColor: Palette.gray[800],
    scaffoldBackgroundColor: Palette.gray[900],
    cardColor: Palette.gray[800],
    dialogBackgroundColor: Palette.gray[800],
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: Palette.indigo[500],
    ),
    colorScheme: ColorScheme.dark(
      primary: Palette.indigo[500]!,
      secondary: Palette.indigo[400]!,
      background: Palette.gray[900]!,
    ),
    fontFamily: 'Poppins',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.gray[700],
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
      ),
    ),
  );

  static final ThemeData errorTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    backgroundColor: Colors.red[500],
    scaffoldBackgroundColor: Colors.red[500],
    textTheme: Typography.englishLike2018,
    fontFamily: 'Poppins',
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

double remToPx(final double rem) => rem * 20;

class UiUtils {
  static bool isDarkContext(final BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static List<Widget> getGridded(
    final int size,
    final List<Widget> children, {
    final Map<int, int> breakpoint = const <int, int>{
      ResponsiveSizes.lg: 2,
    },
    final Widget? spacer,
    final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    final CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final MapEntry<int, int>? point = (breakpoint.entries.toList()
          ..sort(
            (final MapEntry<int, int> a, final MapEntry<int, int> b) =>
                b.key.compareTo(a.key),
          ))
        .firstWhereOrNull((final MapEntry<int, int> x) => size > x.key);

    if (point != null && point.value > 1) {
      const Widget filler = SizedBox.shrink();

      return ListUtils.chunk(children, point.value, filler).map(
        (final List<Widget> x) {
          final List<Widget> children = <Widget>[];

          for (int i = 0; i < x.length; i++) {
            children.add(Expanded(child: x[i]));

            if (spacer != null && i != 0 && i < x.length) {
              children.add(spacer);
            }
          }

          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        },
      ).toList();
    }

    return children;
  }

  static ScrollController createMultiplierScrollController({
    final int multiplier = 80,
    final bool enabled = true,
  }) {
    final ScrollController controller = ScrollController();

    if (enabled) {
      controller.addListener(() {
        final ScrollDirection scrollDirection =
            controller.position.userScrollDirection;

        if (scrollDirection != ScrollDirection.idle) {
          double scrollEnd = controller.offset +
              (scrollDirection == ScrollDirection.reverse
                  ? multiplier
                  : -multiplier);

          scrollEnd = min(
            controller.position.maxScrollExtent,
            max(controller.position.minScrollExtent, scrollEnd),
          );

          controller.jumpTo(scrollEnd);
        }
      });
    }

    return controller;
  }
}

class MiceScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
