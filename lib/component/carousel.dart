import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/model/ads.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

import '../manager/custom_cache_manager.dart';
class Carousel extends StatefulWidget {
  final List<AdsModel> ads;
  const Carousel({super.key, required this.ads});

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final BaseCacheManager _cacheManager = DefaultCacheManager();
  final _storage = const FlutterSecureStorage();
  List controllerList = [];
  CarouselController buttonCarouselController = CarouselController();
  late Future<List<Widget>> futureAdsList;
  bool isAdsFetched = false;
  int adsCounter = 0;

  Timer? _timer;
  int currentAdsDuration = 10;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) async {
        if (currentAdsDuration == 0) {
          buttonCarouselController.nextPage();
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

  Future<File?> getCachedAsset(String url) async {
    final cacheManager = CustomCacheManager(
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    );
    FileInfo? cachedFile = await cacheManager.getFileFromCache(url);

    if (cachedFile == null) {
      try {
        File file = await cacheManager.getSingleFile(url);
        return file;
      } catch (e) {
        print("Error downloading or caching file: $e");
        return null;
      }
    }
    return cachedFile.file;
  }

  Future<List<Widget>> getAdsList() async {
    List<Widget> mediaList = [];

    for (var element in widget.ads) {
      final cachedAsset = await getCachedAsset(element.content);

      if (element.type == 'IMAGE') {
        ImageProvider imageProvider;
        if (cachedAsset == null) {
          imageProvider = NetworkImage(element.content);
        } else {
          imageProvider = FileImage(cachedAsset);
        }

        // Use Image to determine its intrinsic aspect ratio
        mediaList.add(
          LayoutBuilder(
            builder: (context, constraints) {
              return FutureBuilder<Size>(
                future: _getImageSize(imageProvider), // Get the image size
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Get the aspect ratio of the image (width / height)
                    double aspectRatio = snapshot.data!.width / snapshot.data!.height;
                    return AspectRatio(
                      aspectRatio: aspectRatio, // Use default aspect ratio
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                      ),
                    );
                  } else {
                    // Show a loading placeholder if image size is not yet available
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          ),
        );

        controllerList.add(null);
      } else {
        VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(element.content));

        if (cachedAsset != null) {
          controller = VideoPlayerController.file(cachedAsset);
        }

        mediaList.add(Stack(
          children: [
            Container(color: Colors.black),
            Center(
              child: AspectRatio(
                aspectRatio: 16.0 / 9.0,
                child: VideoPlayer(controller),
              ),
            )
          ],
        ));
        controller.setLooping(true);
        controllerList.add(controller);
      }
    }

    return mediaList;
  }

  // Function to get the size of an image
  Future<Size> _getImageSize(ImageProvider imageProvider) async {
    final Completer<Size> completer = Completer();
    final ImageStreamListener listener = ImageStreamListener((ImageInfo info, bool _) {
      var myImageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      completer.complete(myImageSize);
    });

    imageProvider.resolve(const ImageConfiguration()).addListener(listener);
    return completer.future;
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
                  if (adsCounter + 1 < widget.ads.length) {
                    adsCounter++;
                  } else {
                    adsCounter = 0;
                  }
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
              viewportFraction: 1.0,
            ),
          );
        } else if (snapshot.data != null && snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No available ads',
              style: TextStyle(fontSize: 20.sp),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

