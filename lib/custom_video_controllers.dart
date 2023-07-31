// dart package
import 'dart:developer';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 3-rd party package
import 'package:pod_player/pod_player.dart';
import 'package:speech_to_text/speech_to_text.dart';
import './utils/app_links.dart';
import './utils/app_strings.dart';
import 'api.dart';

class CustomVideoControllers extends StatefulWidget {
  const CustomVideoControllers({Key? key}) : super(key: key);

  @override
  State<CustomVideoControllers> createState() => _CustomVideoControllersState();
}

class _CustomVideoControllersState extends State<CustomVideoControllers> {
  SpeechToText speechToText = SpeechToText();
  String searchedWord = '';
  late PodPlayerController controller;
  bool? isVideoPlaying;
  List<String> timestamps = [];

  final youtubeTextFieldCtr = TextEditingController(
    text: AppLinks.firstYoutubeLink,
  );

  final durationTextFieldCtr = TextEditingController(
    text: AppStrings.initialDuration,
  );

  final searchTextFieldCtr = TextEditingController(
    text: '',
  );

  bool alwaysShowProgressBar = true;

  bool isListening = false;

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
    youtubeTextFieldCtr.dispose();
    durationTextFieldCtr.dispose();
    searchTextFieldCtr.dispose();
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

  // YT code from YT Link
  String extractVideoCode(String youtubeLink) {
    // Define the regular expression pattern to match the video code
    RegExp regExp = RegExp(r'(?:(?<=v=)|(?<=be/))[a-zA-Z0-9_-]+');

    // Use the firstMatch method to find the first match in the link
    Match? match = regExp.firstMatch(youtubeLink);

    // Check if a match was found and return the video code
    if (match != null) {
      return match.group(0) as String;
    } else {
      // Return an empty string or handle the case when no match is found
      return '';
    }
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

                    // // Some Spacing
                    // sizeH20,

                    Text(searchedWord),
                    // Time stamp list

                    if (timestamps != [])
                      Column(
                        children: [
                          // Some Spacing
                          sizeH20,

                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: timestamps.length,
                              itemBuilder: (context, index) {
                                return timeStampWidget(
                                    timestamps[index].split(',')[0]);
                              },
                            ),
                          ),

                          // Some Spacing
                          sizeH20,
                        ],
                      ),

                    // // Some Spacing
                    // sizeH20,

                    // Youtube URL Video
                    _loadVideoFromYoutube(),

                    // // Some Spacing
                    // sizeH20,

                    // Jump to input duration of Video
                    // _jumpToInputDuration(),

                    // Some Spacing
                    sizeH20,

                    // Jump to input duration of Video
                    _jumpToSearchWord(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: isListening,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        repeatPauseDuration: const Duration(milliseconds: 100),
        child: GestureDetector(
          onTapDown: (details) async {
            if (!isListening) {
              var available = await speechToText.initialize();
              if (available) {
                setState(() {
                  timestamps = [];
                  isListening = true;
                  speechToText.listen(
                    onResult: (result) async {
                      setState(() {
                        searchedWord = result.recognizedWords;
                      });
                      String youtubeVideoCode =
                          extractVideoCode(youtubeTextFieldCtr.text);

                      // Call the fetch_data() function to request data from the Flask backend
                      timestamps =
                          await fetchData(youtubeVideoCode, searchedWord);
                    },
                  );
                });
              }
            }
          },
          onTapUp: (details) async {
            setState(() {
              isListening = false;
            });

            speechToText.stop();
          },
          child: CircleAvatar(
            radius: 35,
            child: Icon(isListening ? Icons.mic : Icons.mic_none),
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

  Row _jumpToSearchWord() {
    return Row(
      children: [
        // Input textfield for search word
        Expanded(
          flex: 2,
          child: TextField(
            controller: searchTextFieldCtr,
            decoration: InputDecoration(
              labelText: AppStrings.searchWord,
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        // Some Spacing
        const SizedBox(width: 10),

        // Search Button
        ElevatedButton(
          onPressed: () async {
            if (searchTextFieldCtr.text.isEmpty) {
              snackBar(AppStrings.pleaseEnterSearchWord);
              return;
            }

            try {
              snackBar('${AppStrings.loading}....');
              FocusScope.of(context).unfocus();

              // String youtubeVideoCode = 'SPFQX82X03Q';
              String youtubeVideoCode =
                  extractVideoCode(youtubeTextFieldCtr.text);
              String searchWord = searchTextFieldCtr.text;

              // Call the fetch_data() function to request data from the Flask backend
              timestamps = await fetchData(youtubeVideoCode, searchWord);

              // Process the timestamps list (e.g., show it in a dialog)
              // showDialog(
              //   context: context,
              //   builder: (context) {
              //     return AlertDialog(
              //       title: Text('Timestamps for "$searchWord"'),
              //       content: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           for (String timestamp in timestamps) Text(timestamp),
              //         ],
              //       ),
              //       actions: [
              //         ElevatedButton(
              //           onPressed: () => Navigator.pop(context),
              //           child: const Text('OK'),
              //         ),
              //       ],
              //     );
              //   },
              // );

              // ScaffoldMessenger.of(context).hideCurrentSnackBar();
            } catch (e) {
              snackBar(
                  "${AppStrings.unableToLoad}, ${kIsWeb ? AppStrings.pleaseEnableCorsInWeb : ''} \n$e");
            }
          },
          child: Text(AppStrings.search),
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

  Widget timeStampWidget(String time) {
    return Row(children: [
      GestureDetector(
        onTap: () => controller.videoSeekTo(stringToDuration(time)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(time)),
        ),
      ),
      const SizedBox(
        width: 10,
      ),
    ]);
  }
}
