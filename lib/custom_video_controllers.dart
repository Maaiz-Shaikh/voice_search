// dart package
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 3-rd party package
import 'package:pod_player/pod_player.dart';
import 'package:voice_search/utils/app_links.dart';
import 'package:voice_search/utils/app_strings.dart';

class CustomVideoControllers extends StatefulWidget {
  const CustomVideoControllers({Key? key}) : super(key: key);

  @override
  State<CustomVideoControllers> createState() => _CustomVideoControllersState();
}

class _CustomVideoControllersState extends State<CustomVideoControllers> {
  late PodPlayerController controller;
  bool? isVideoPlaying;

  final youtubeTextFieldCtr = TextEditingController(
    text: AppLinks.firstYoutubeLink,
  );

  final durationTextFieldCtr = TextEditingController(
    text: AppStrings.initialDuration,
  );

  bool alwaysShowProgressBar = true;
  @override
  void initState() {
    super.initState();
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube(AppLinks.firstYoutubeLink),
    )..initialise().then((value) {
        setState(() {
          isVideoPlaying = controller.isVideoPlaying;
        });
      });
    controller.addListener(_listner);
  }

  ///Listnes to changes in video
  void _listner() {
    if (controller.isVideoPlaying != isVideoPlaying) {
      isVideoPlaying = controller.isVideoPlaying;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_listner);
    controller.dispose();
    super.dispose();
  }

  // Convert String to Duration
  Duration stringToDuration(String timeString) {
    List<String> timeComponents = timeString.split(':');
    int hours = int.parse(timeComponents[0]);
    int minutes = int.parse(timeComponents[1]);
    int seconds = int.parse(timeComponents[2]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    ///
    const sizeH20 = SizedBox(height: 20);
    final totalHour = controller.currentVideoPosition.inHours == 0
        ? '0'
        : '${controller.currentVideoPosition.inHours}:';
    final totalMinute =
        controller.currentVideoPosition.toString().split(':')[1];
    final totalSeconds = (controller.currentVideoPosition -
            Duration(minutes: controller.currentVideoPosition.inMinutes))
        .inSeconds
        .toString()
        .padLeft(2, '0');

    ///
    const videoTitle = Padding(
      padding: kIsWeb
          ? EdgeInsets.symmetric(vertical: 25, horizontal: 15)
          : EdgeInsets.only(left: 15),
      child: Text(
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    const textStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
    return Scaffold(
      // App Bar
      appBar: AppBar(title: Text(AppStrings.customPlayer)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Some Spacing
              sizeH20,

              // Video Player
              PodVideoPlayer(
                alwaysShowProgressBar: alwaysShowProgressBar,
                controller: controller,
                matchFrameAspectRatioToVideo: true,
                matchVideoAspectRatioToFrame: true,
                videoTitle: videoTitle,
              ),

              // Video URL
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Text('${AppStrings.videoUrl} : '),
                    Expanded(
                      child: Text(
                        controller.videoUrl ?? '',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Custom Controllers
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Video State
                    Text(
                      '${AppStrings.videoState}: ${controller.videoState.name}',
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),

                    // Some Spacing
                    sizeH20,

                    // Video played so far
                    Text(
                      '$totalHour ${AppStrings.hour}: '
                      '$totalMinute ${AppStrings.minute}: '
                      '$totalSeconds ${AppStrings.seconds}',
                      style: textStyle,
                    ),

                    // Some Spacing
                    sizeH20,

                    // Youtube URL Video
                    _loadVideoFromYoutube(),

                    // Some Spacing
                    sizeH20,

                    // Jump to input duration of Video
                    _jumpToInputDuration(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Row _loadVideoFromYoutube() {
    return Row(
      children: [
        // Input textfield for url
        Expanded(
          flex: 2,
          child: TextField(
            controller: youtubeTextFieldCtr,
            decoration: InputDecoration(
              labelText: AppStrings.enterYoutubeUrl,
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        // Some Spacing
        const SizedBox(width: 10),

        // Load video button
        ElevatedButton(
          onPressed: () async {
            if (youtubeTextFieldCtr.text.isEmpty) {
              snackBar(AppStrings.pleaseEnterYoutubeUrl);
              return;
            }
            try {
              snackBar('${AppStrings.loading}....');
              FocusScope.of(context).unfocus();
              await controller.changeVideo(
                playVideoFrom: PlayVideoFrom.youtube(youtubeTextFieldCtr.text),
              );
              controller.addListener(_listner);
              controller.onVideoQualityChanged(
                () {
                  log(AppStrings.youtubeVideoQualityChanged);
                  controller.addListener(_listner);
                },
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            } catch (e) {
              snackBar(
                  "${AppStrings.unableToLoad},${kIsWeb ? AppStrings.pleaseEnableCorsInWeb : ''}  \n$e");
            }
          },
          child: Text(AppStrings.loadVideo),
        ),
      ],
    );
  }

  Row _jumpToInputDuration() {
    return Row(
      children: [
        // Input textfield for duration
        Expanded(
          flex: 2,
          child: TextField(
            controller: durationTextFieldCtr,
            decoration: InputDecoration(
              labelText: '${AppStrings.enterDuration} (${AppStrings.hhmmss})',
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        // Some Spacing
        const SizedBox(width: 10),

        // Skip video Button
        ElevatedButton(
          onPressed: () async {
            if (durationTextFieldCtr.text.isEmpty) {
              snackBar(AppStrings.pleaseEnterYoutubeDuration);
              return;
            }
            try {
              snackBar('${AppStrings.loading}....');
              FocusScope.of(context).unfocus();
              controller
                  .videoSeekTo(stringToDuration(durationTextFieldCtr.text));
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            } catch (e) {
              snackBar(
                  "${AppStrings.unableToLoad},${kIsWeb ? AppStrings.pleaseEnableCorsInWeb : ''}  \n$e");
            }
          },
          child: Text(AppStrings.skipVideo),
        ),
      ],
    );
  }

  void snackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }
}
