import 'package:extensions/extensions.dart' as extensions;
import 'package:flutter/material.dart';
import './update_tracker.dart';
import '../../components/full_screen_image.dart';
import '../../plugins/database/schemas/settings/settings.dart' show MangaMode;
import '../../plugins/helpers/screen.dart';
import '../../plugins/helpers/stateful_holder.dart';
import '../../plugins/helpers/ui.dart';
import '../../plugins/state.dart' show AppState;
import '../../plugins/translator/translator.dart';
import '../settings_page/setting_radio.dart';

class ListReader extends StatefulWidget {
  const ListReader({
    required final this.extractor,
    required final this.info,
    required final this.chapter,
    required final this.pages,
    required final this.onPop,
    required final this.previousChapter,
    required final this.nextChapter,
    required final this.ignoreAutoFullscreen,
    required final this.onIgnoreAutoFullscreenChange,
    final Key? key,
  }) : super(key: key);

  final extensions.MangaExtractor extractor;
  final extensions.MangaInfo info;
  final extensions.ChapterInfo chapter;
  final List<extensions.PageInfo> pages;

  final void Function() onPop;
  final void Function() previousChapter;
  final void Function() nextChapter;

  final bool ignoreAutoFullscreen;
  final void Function(bool ignoreAutoFullscreen) onIgnoreAutoFullscreenChange;

  @override
  _ListReaderState createState() => _ListReaderState();
}

class _ListReaderState extends State<ListReader> with FullscreenMixin {
  final Widget loader = const CircularProgressIndicator();

  late final Map<extensions.PageInfo, StatefulHolder<extensions.ImageInfo?>>
      images = <extensions.PageInfo, StatefulHolder<extensions.ImageInfo?>>{};

  bool hasSynced = false;
  bool ignoreExitFullscreen = false;

  @override
  void initState() {
    super.initState();

    initFullscreen();
    if (AppState.settings.current.mangaAutoFullscreen &&
        !widget.ignoreAutoFullscreen) {
      enterFullscreen();
    }
  }

  @override
  void dispose() {
    if (!ignoreExitFullscreen) {
      exitFullscreen();
    }

    super.dispose();
  }

  Future<void> getPage(final extensions.PageInfo page) async {
    images[page]!.state = LoadState.resolving;
    final extensions.ImageInfo image = await widget.extractor.getPage(page);
    setState(() {
      images[page]!.value = image;
      images[page]!.state = LoadState.resolved;
    });
  }

  void showOptions() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(remToPx(0.5)),
          topRight: Radius.circular(remToPx(0.5)),
        ),
      ),
      context: context,
      builder: (final BuildContext context) => StatefulBuilder(
        builder: (
          final BuildContext context,
          final StateSetter setState,
        ) =>
            Padding(
          padding: EdgeInsets.symmetric(vertical: remToPx(0.25)),
          child: Wrap(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SettingRadio<MangaMode>(
                    title: Translator.t.mangaReaderMode(),
                    icon: Icons.pageview,
                    value: AppState.settings.current.mangaReaderMode,
                    labels: <MangaMode, String>{
                      MangaMode.list: Translator.t.list(),
                      MangaMode.page: Translator.t.page(),
                    },
                    onChanged: (final MangaMode val) async {
                      AppState.settings.current.mangaReaderMode = val;
                      await AppState.settings.current.save();
                      AppState.settings.modify(AppState.settings.current);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _maybeUpdateTrackers(final int index) async {
    if (!hasSynced && index == widget.pages.length - 1) {
      hasSynced = true;

      await updateTrackers(
        widget.info.title,
        widget.extractor.id,
        widget.chapter.chapter,
        widget.chapter.volume,
      );
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onPop,
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                ignoreExitFullscreen = true;
                widget.previousChapter();
              },
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              onPressed: () {
                ignoreExitFullscreen = true;
                widget.nextChapter();
              },
              icon: const Icon(Icons.last_page),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isFullscreened,
              builder: (
                final BuildContext builder,
                final bool isFullscreened,
                final Widget? child,
              ) =>
                  IconButton(
                onPressed: () {
                  if (isFullscreened) {
                    widget.onIgnoreAutoFullscreenChange(true);
                    exitFullscreen();
                  } else {
                    widget.onIgnoreAutoFullscreenChange(false);
                    enterFullscreen();
                  }
                },
                icon: Icon(
                  isFullscreened ? Icons.fullscreen_exit : Icons.fullscreen,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                showOptions();
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.info.title,
              ),
              Text(
                '${widget.chapter.volume != null ? '${Translator.t.vol()} ${widget.chapter.volume} ' : ''}${Translator.t.ch()} ${widget.chapter.chapter} ${widget.chapter.title != null ? '- ${widget.chapter.title}' : ''}',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.subtitle2?.fontSize,
                ),
              ),
            ],
          ),
        ),
        body: widget.pages.isEmpty
            ? Center(
                child: Text(Translator.t.noPagesFound()),
              )
            : ListView.builder(
                itemCount: widget.pages.length,
                itemBuilder: (final BuildContext context, final int index) {
                  final extensions.PageInfo page = widget.pages[index];

                  if (images[page] == null) {
                    images[page] = StatefulHolder<extensions.ImageInfo?>(null);
                  }

                  if (!images[page]!.hasValue) {
                    if (!images[page]!.isResolving) {
                      getPage(page);
                    }

                    return Padding(
                      padding: EdgeInsets.all(remToPx(5)),
                      child: Center(
                        child: loader,
                      ),
                    );
                  }

                  _maybeUpdateTrackers(index);

                  final extensions.ImageInfo image = images[page]!.value!;
                  return Image.network(
                    image.url,
                    headers: image.headers,
                    loadingBuilder: (
                      final BuildContext context,
                      final Widget child,
                      final ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return Stack(
                          children: <Widget>[
                            Align(
                              alignment: AlignmentDirectional.center,
                              child: child,
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<dynamic>(
                                        builder: (final BuildContext context) =>
                                            FullScreenInteractiveImage(
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return SizedBox(
                        height: remToPx(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      );
}
