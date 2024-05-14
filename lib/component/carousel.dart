import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassbox/model/ads.dart';
import 'package:video_player/video_player.dart';

class Carousel extends StatefulWidget {
  final List<AdsModel> ads;
  const Carousel({super.key, required this.ads});

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  List controllerList = [];
  CarouselController buttonCarouselController = CarouselController();
  late Future<List<Widget>> futureAdsList;
  bool isAdsFetched = false;

  Timer? _timer;
  int currentAdsDuration = 10;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (currentAdsDuration == 0) {
          setState(() {
            buttonCarouselController.nextPage();
          });
        } else {
          setState(() {
            currentAdsDuration--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futureAdsList = getAdsList();
  }

  @override
  void deactivate() {
    _timer?.cancel();
    controllerList.forEach((element) {
      if (element != null) {
        element.dispose();
      }
    });
    super.deactivate();
  }

  Future<List<Widget>> getAdsList() async {
    List<Widget> mediaList = [];
    for (var element in widget.ads) {
      if (element.type == 'IMAGE') {
        mediaList.add(Image.network(
          element.content,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          fit: BoxFit.cover,
        ));
        controllerList.add(null);
      } else {
        VideoPlayerController controller =
            VideoPlayerController.networkUrl(Uri.parse(element.content));

        mediaList.add(Stack(
          children: [
            Container(
              color: Colors.black,
            ),
            Center(
                child: AspectRatio(
                    aspectRatio: 16.0 / 9.0, child: VideoPlayer(controller)))
          ],
        ));
        controller.setLooping(true);
        controllerList.add(controller);
      }
    }

    return mediaList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: futureAdsList,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final adsList = snapshot.data;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isAdsFetched) {
                startTimer();
                setState(() {
                  isAdsFetched = true;
                });
              }
            });

            return CarouselSlider(
                carouselController: buttonCarouselController,
                disableGesture: true,
                items: adsList!.map((item) {
                  return item;
                }).toList(),
                options: CarouselOptions(
                    clipBehavior: Clip.antiAlias,
                    autoPlayCurve: Curves.easeInOutSine,
                    onPageChanged: (index, reason) {
                      setState(() {
                        currentAdsDuration = widget.ads[index].duration;
                      });
                      if (widget.ads[index].type == 'VIDEO') {
                        controllerList[index].initialize();
                        controllerList[index].play();
                      } else {
                        controllerList.forEach((element) {
                          if (element != null) {
                            element.pause();
                            element.seekTo(Duration.zero);
                          }
                        });
                      }
                    },
                    viewportFraction: 1.0));
          } else if (snapshot.data != null && snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              'No available ads',
              style: TextStyle(fontSize: 20.sp),
            ));
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const Center(child: CircularProgressIndicator());
        });
  }
}
