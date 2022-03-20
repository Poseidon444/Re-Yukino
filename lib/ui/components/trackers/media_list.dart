import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:tenka/tenka.dart';
import '../../../config/defaults.dart';
import '../../../modules/helpers/ui.dart';
import '../../../modules/state/hooks.dart';
import '../../../modules/translator/translator.dart';

class MediaList extends StatefulWidget {
  const MediaList({
    required final this.type,
    required final this.status,
    required final this.getMediaList,
    required final this.getItemCard,
    required final this.getItemPage,
    final this.maybeRefresh,
    final Key? key,
  }) : super(key: key);

  final TenkaType type;
  final dynamic status;
  final Future<List<dynamic>> Function(int page) getMediaList;
  final Widget Function(BuildContext, dynamic) getItemCard;
  final Widget Function(BuildContext, dynamic) getItemPage;
  final void Function(dynamic)? maybeRefresh;

  @override
  _MediaListState createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> with HooksMixin {
  List<dynamic>? mediaList;
  int page = 0;

  final Widget loader = const Center(
    child: CircularProgressIndicator(),
  );

  @override
  void initState() {
    super.initState();

    onReady(load);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    hookState.markReady();
  }

  Future<void> load() async {
    final List<dynamic> _mediaList = await widget.getMediaList(page);

    if (!mounted) return;
    setState(() {
      mediaList = _mediaList;
    });
  }

  @override
  Widget build(final BuildContext context) => ListView(
        children: <Widget>[
          if (mediaList != null) ...<Widget>[
            if (mediaList!.isEmpty) ...<Widget>[
              SizedBox(
                height: remToPx(2),
              ),
              Center(
                child: Text(
                  Translator.t.nothingWasFoundHere(),
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ),
              SizedBox(
                height: remToPx(2),
              ),
            ] else ...<Widget>[
              ...UiUtils.getGridded(
                MediaQuery.of(context).size.width.toInt(),
                mediaList!
                    .asMap()
                    .map(
                      (
                        final int k,
                        final dynamic x,
                      ) =>
                          MapEntry<int, Widget>(
                        k,
                        OpenContainer(
                          transitionType: ContainerTransitionType.fadeThrough,
                          openColor: Theme.of(context).scaffoldBackgroundColor,
                          closedColor: Colors.transparent,
                          closedElevation: 0,
                          transitionDuration: Defaults.animationsSlower,
                          onClosed: (final dynamic result) {
                            setState(() {});
                          },
                          openBuilder: (
                            final BuildContext context,
                            final VoidCallback cb,
                          ) =>
                              widget.getItemPage(context, x),
                          closedBuilder: (
                            final BuildContext context,
                            final VoidCallback cb,
                          ) =>
                              MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: widget.getItemCard(context, x),
                          ),
                        ),
                      ),
                    )
                    .values
                    .toList(),
                spacer: SizedBox(
                  width: remToPx(0.4),
                ),
              ),
              SizedBox(
                height: remToPx(1.5),
              ),
            ]
          ] else ...<Widget>[
            SizedBox(
              height: remToPx(3),
            ),
            loader,
            SizedBox(
              height: remToPx(3),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                splashRadius: remToPx(1),
                onPressed: mediaList != null && page > 0
                    ? () {
                        setState(() {
                          page = page - 1;
                          mediaList = null;
                        });

                        load();
                      }
                    : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: Translator.t.back(),
              ),
              SizedBox(
                width: remToPx(0.8),
              ),
              Text('${Translator.t.page()} ${page + 1}'),
              SizedBox(
                width: remToPx(0.8),
              ),
              IconButton(
                splashRadius: remToPx(1),
                onPressed: mediaList != null && mediaList!.isNotEmpty
                    ? () {
                        setState(() {
                          page = page + 1;
                          mediaList = null;
                        });

                        load();
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: Translator.t.next(),
              ),
            ],
          ),
        ],
      );
}
