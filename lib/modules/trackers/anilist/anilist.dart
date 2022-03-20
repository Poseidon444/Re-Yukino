import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import './handlers/auth.dart';
import '../../../config/app.dart';
import '../../../config/secrets/anilist.dart';
import '../../database/database.dart';

export './handlers/auth.dart';
export './handlers/character.dart';
export './handlers/media.dart';
export './handlers/media_list.dart';
export './handlers/recommendations.dart';
export './handlers/user_info.dart';

class RequestBody {
  RequestBody({
    required final this.query,
    final this.variables,
  });

  final String query;
  final Map<dynamic, dynamic>? variables;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'query': query,
        'variables': json.encode(variables),
      };
}

abstract class AnilistManager {
  static const String webURL = 'https://anilist.co';
  static const String baseURL = 'https://graphql.anilist.co';

  static final AniListAuth auth = AniListAuth(AnilistSecrets.clientId);

  static Future<void> initialize() async {
    final CredentialsSchema creds = CredentialsBox.get();

    if (creds.anilist != null) {
      auth.token = creds.anilist;

      if (!auth.isValidToken()) {
        await auth.deleteToken();
      }
    }
  }

  static Future<void> authenticate(final AniListTokenInfo token) async {
    auth.authorize(token);
    if (auth.token != null) {
      await auth.saveToken();
    }
  }

  static Future<dynamic> request(final RequestBody body) async {
    if (!auth.isValidToken()) throw StateError('Not logged in');

    final http.Response res = await http.post(
      Uri.parse(baseURL),
      body: json.encode(body.toJson()),
      headers: <String, String>{
        'User-Agent': '${Config.name} v${Config.version}',
        'Authorization': '${auth.token!.tokenType} ${auth.token!.accessToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final dynamic parsed = res.body.isNotEmpty ? json.decode(res.body) : null;
    if (parsed is Map<dynamic, dynamic> &&
        (parsed['errors'] as List<dynamic>?)?.firstWhereOrNull(
              (final dynamic x) =>
                  (x as Map<dynamic, dynamic>)['message'] == 'Invalid token',
            ) !=
            null) {
      await auth.deleteToken();
      throw StateError('Login expired');
    }

    return parsed;
  }

  bool get isLoggedIn => auth.isValidToken();
}
