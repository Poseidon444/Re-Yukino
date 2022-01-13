import 'package:hetu_script/binding.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:utilx/utilities/locale.dart';
import '../../../../../../../models/manga/page/info.dart';
import '../../../../../model.dart';

class PageInfoClassBinding extends HTExternalClass {
  PageInfoClassBinding() : super('PageInfo');

  @override
  dynamic memberGet(
    final String varName, {
    final String? from,
  }) {
    switch (varName) {
      case 'PageInfo':
        return createHTExternalFunction(
          (
            final HTEntity entity, {
            final List<dynamic> positionalArgs = const <dynamic>[],
            final Map<String, dynamic> namedArgs = const <String, dynamic>{},
            final List<HTType> typeArgs = const <HTType>[],
          }) =>
              PageInfo(
            url: namedArgs['url'] as String,
            locale: Locale.parse(namedArgs['locale'] as String),
          ),
        );

      default:
        throw HTError.undefined(varName);
    }
  }
}