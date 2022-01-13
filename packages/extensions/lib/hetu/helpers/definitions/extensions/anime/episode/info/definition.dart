import './binding.dart';
import '../../../../../model.dart';

final HetuHelperClass hEpisodeInfoClass = HetuHelperClass(
  definition: EpisodeInfoClassBinding(),
  declaration: '''
external class EpisodeInfo {
  construct({ episode, url, locale });
}
      '''
      .trim(),
);