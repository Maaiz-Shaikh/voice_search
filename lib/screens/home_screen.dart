import 'dart:developer';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api.dart';
import '../main.dart';
import '../utils/app_links.dart';
import '../utils/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // controllers
  final youtubeTextFieldCtr = TextEditingController(
    text: AppLinks.firstYoutubeLink,
  );
  final searchTextFieldCtr = TextEditingController(
    text: '',
  );

  // objects
  SpeechToText speechToText = SpeechToText();

  // variables
  String searchedWord = '';
  late PodPlayerController controller;
  bool? isVideoPlaying;
  List<String> timestamps = [];
  bool alwaysShowProgressBar = true;
  bool isListening = false;

  // methods
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

  // Listen to changes in video
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
    final videoTitle = Padding(
      padding: kIsWeb
          ? const EdgeInsets.symmetric(vertical: 25, horizontal: 15)
          : const EdgeInsets.only(left: 15),
      child: Text(
        AppStrings.videoTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Scaffold(
      // AppBar with logo and word + voice based video content search
      appBar: AppBar(
        actions: [
          // SearchBar for word search
          searchBar(
            hintText: "${AppStrings.searchWord}...",
            icon: const Icon(Icons.search),
            onPressed: () async {
              searchedWord = "";
              if (searchTextFieldCtr.text.isEmpty) {
                timestamps = [];
                snackBar(AppStrings.pleaseEnterSearchWord);
                return;
              }

              try {
                snackBar('${AppStrings.loading}....');
                FocusScope.of(context).unfocus();

                String youtubeVideoCode =
                    extractVideoCode(youtubeTextFieldCtr.text);

                String searchWord = searchTextFieldCtr.text;

                // Call the fetch_data() function to request data from the Flask backend
                timestamps = await fetchData(youtubeVideoCode, searchWord);
              } catch (e) {
                snackBar(
                    "${AppStrings.unableToLoad}, ${kIsWeb ? AppStrings.pleaseEnableCorsInWeb : ''} \n$e");
              }
            },
            textEditingController: searchTextFieldCtr,
          ),

          // Some spacing
          const SizedBox(
            width: 10,
          ),

          // Mic for word search
          AvatarGlow(
            glowColor: Provider.of<ThemeModel>(context).isDark
                ? Colors.white
                : Colors.black,
            endRadius: 60.0,
            animate: isListening,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            repeatPauseDuration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTapDown: (details) async {
                searchTextFieldCtr.text = "";
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
                backgroundColor: Provider.of<ThemeModel>(context).isDark
                    ? Colors.white
                    : Colors.grey[300],
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Some spacing
          const SizedBox(
            width: 10,
          ),

          // Dark Light Switch
          IconButton(
            onPressed: () =>
                Provider.of<ThemeModel>(context, listen: false).toggleTheme(),
            icon: Icon(
              Provider.of<ThemeModel>(context).isDark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
              color: Provider.of<ThemeModel>(context).isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          // GestureDetector(
          //   onTap: () =>
          //       Provider.of<ThemeModel>(context, listen: false).toggleTheme(),
          //   child: Container(
          //     padding: EdgeInsets.all(5),
          //     decoration: BoxDecoration(
          //       color: Provider.of<ThemeModel>(context).isDark
          //           ? Colors.yellow
          //           : Colors.blue,
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.nightlight_round,
          //           color: Provider.of<ThemeModel>(context).isDark
          //               ? Colors.black
          //               : Colors.white,
          //         ),
          //         SizedBox(width: 5),
          //         Icon(
          //           Icons.wb_sunny,
          //           color: Provider.of<ThemeModel>(context).isDark
          //               ? Colors.black
          //               : Colors.white,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // Some spacing
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.1,
          )
        ],

        // AppBar title
        title: Text(AppStrings.videoContentSearch),
      ),

      // Body with video-player, load video input field and timestamp space
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
        // Row with section-1(video-player and load video input field) and section-2(timestamp space)
        child: Row(
          children: [
            // Section-1(video-player and load video input field)
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Video-Player
                  Expanded(
                    flex: 8,
                    child: PodVideoPlayer(
                      alwaysShowProgressBar: alwaysShowProgressBar,
                      controller: controller,
                      matchFrameAspectRatioToVideo: true,
                      matchVideoAspectRatioToFrame: true,
                      videoTitle: videoTitle,
                    ),
                  ),

                  // Load video input field
                  Expanded(
                    child: searchBar(
                      hintText: "${AppStrings.enterVideoUrl}...",
                      icon: const Icon(Icons.cached),
                      textEditingController: youtubeTextFieldCtr,
                      onPressed: () async {
                        if (youtubeTextFieldCtr.text.isEmpty) {
                          snackBar(AppStrings.pleaseEnterYoutubeUrl);
                          return;
                        }
                        try {
                          snackBar('${AppStrings.loading}....');
                          FocusScope.of(context).unfocus();
                          await controller.changeVideo(
                            playVideoFrom:
                                PlayVideoFrom.youtube(youtubeTextFieldCtr.text),
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
                    ),
                  ),
                ],
              ),
            ),

            // Some spacing
            const SizedBox(
              width: 10,
            ),

            // Section-2(timestamp space)
            Expanded(
              flex: 3,
              child: timestamps.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.searchVideoContent,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Text(
                          searchTextFieldCtr.text.isEmpty
                              ? "${AppStrings.searchFor} \"$searchedWord\""
                              : "${AppStrings.searchFor} \"${searchTextFieldCtr.text}\"",
                          style: const TextStyle(
                            fontSize: 20,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.80,
                          child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: timestamps.length,
                            itemBuilder: (context, index) {
                              return timeStampWidget(
                                  timestamps[index].split(',')[0], index + 1);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget timeStampWidget(String time, int index) {
    return Column(children: [
      ListTile(
        onTap: () {
          controller.videoSeekTo(stringToDuration(time));
        },
        trailing: const Icon(Icons.fast_forward),
        subtitle: Text('${AppStrings.instance} $index'),
        title: Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        hoverColor: Provider.of<ThemeModel>(context).isDark
            ? Colors.grey[500]
            : Colors.grey[300],
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(
            Icons.watch_later_outlined,
            color: Colors.black,
          ),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
    ]);
  }

  Widget searchBar({
    required String hintText,
    required Widget icon,
    required void Function() onPressed,
    required TextEditingController textEditingController,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width:
          MediaQuery.of(context).size.width * 0.5, // Adjust the width as needed
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: icon,
            onPressed: onPressed,
          ),
        ],
      ),
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
