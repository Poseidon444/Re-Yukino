import 'package:utilx/utils.dart';
import '../anilist.dart';

abstract class AniListRecommendations {
  static Future<List<AniListMedia>> getRecommended(
    final int page, {
    final int perPage = 50,
    final bool onList = true,
  }) async {
    const String query = '''
query (
  \$page: Int,
  \$perpage: Int,
  \$onlist: Boolean
) {
  Page (
    page: \$page,
    perPage: \$perpage
  ) {
    recommendations (
      sort: RATING,
      onList: \$onlist
    ) {
      media ${AniListMedia.query}
    }
  }
}
  ''';

    final Map<dynamic, dynamic> res = await AnilistManager.request(
      RequestBody(
        query: query,
        variables: <dynamic, dynamic>{
          'page': page,
          'perpage': perPage,
          'onlist': onList,
        },
      ),
    ) as Map<dynamic, dynamic>;

    return MapUtils.get<List<dynamic>>(
      res,
      <dynamic>['data', 'Page', 'recommendations'],
    )
        .cast<Map<dynamic, dynamic>>()
        .map(
          (final Map<dynamic, dynamic> x) =>
              AniListMedia.fromJson(x['media'] as Map<dynamic, dynamic>),
        )
        .toList();
  }
}
