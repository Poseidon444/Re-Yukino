import './binding.dart';
import '../../../../../model.dart';

final HetuHelperClass hPageInfoClass = HetuHelperClass(
  definition: PageInfoClassBinding(),
  declaration: '''
external class PageInfo {
  construct({ url, locale });
}
      '''
      .trim(),
);
