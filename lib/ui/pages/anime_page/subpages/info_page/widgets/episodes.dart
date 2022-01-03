import 'package:extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:utilx/utilities/utils.dart';
import '../../../../../../modules/helpers/ui.dart';
import '../../../../../../modules/translator/translator.dart';
import '../../../controller.dart';

class Episodes extends StatelessWidget {
  const Episodes({
    required final this.start,
    required final this.end,
    required final this.padding,
    required final this.controller,
    final Key? key,
  }) : super(key: key);

  final int start;
  final int end;
  final EdgeInsets padding;
  final AnimePageController controller;

  @override
  Widget build(final BuildContext context) => MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
          padding: padding,
          children: <Widget>[
            SizedBox(height: remToPx(1)),
            Text(
              Translator.t.episodes(),
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyText2?.fontSize,
                color: Theme.of(context)
                    .textTheme
                    .bodyText2
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
            ...ListUtils.chunk<Widget>(
              controller.info.value!.sortedEpisodes
                  .sublist(start, end)
                  .asMap()
                  .map(
                    (
                      final int k,
                      final EpisodeInfo x,
                    ) =>
                        MapEntry<int, Widget>(
                      k,
                      Expanded(
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: remToPx(0.4),
                                vertical: remToPx(0.3),
                              ),
                              child: Text(
                                '${Translator.t.episode(x.episode.padLeft(2, '0'))} ',
                                style: Theme.of(context).textTheme.subtitle2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            onTap: () async {
                              controller.setCurrentEpisodeIndex(start + k);
                              await controller.goToPage(SubPages.player);
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                  .values
                  .toList(),
              MediaQuery.of(context).size.width ~/ remToPx(8),
              const Expanded(child: SizedBox.shrink()),
            ).map((final List<Widget> x) => Row(children: x)).toList(),
          ],
        ),
      );
}
