import 'dart:async';

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/model/ads.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

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
  CarouselSliderController buttonCarouselController =
      CarouselSliderController();
  late Future<List<Widget>> futureAdsList;
  bool isAdsFetched = false;
  int adsCounter = 0;
  List currentImageAspectRatio = [];

  Timer? _timer;
  int currentAdsDuration = 10;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (currentAdsDuration == 0) {
          buttonCarouselController.nextPage();

          var url = Uri.https('api.glassbox.id',
              '/v1/advertisements/${widget.ads[adsCounter].id}/complete');
          final token = await _storage.readAll(
            aOptions: getAndroidOptions(),
          );
          await http.post(url,
              headers: {'Authorization': 'Bearer ${token['access_token']}'});
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

  Future<FileInfo?> getCachedAsset(String url) async {
    final cachedAsset = await _cacheManager.getFileFromCache(url);
    if (cachedAsset == null) {
      debugPrint('GLASSBOX: no assets in cache: $url');
      debugPrint('GLASSBOX: saving assets in cache...');
      unawaited(_cacheManager.downloadFile(url));
      return null;
    }

    bool isCacheExpired = DateTime.now().isAfter(cachedAsset.validTill);

    if (isCacheExpired) {
      await _cacheManager.removeFile(url);
      return null;
    }

    debugPrint('GLASSBOX: $url is from cache');
    return cachedAsset;
  }

  Future<List<Widget>> getAdsList() async {
    List<Widget> mediaList = [];
    for (var element in widget.ads) {
      final cachedAsset = await getCachedAsset(element.content);
      if (element.type == 'IMAGE') {
        if (cachedAsset == null) {
          mediaList.add(Image.network(
            element.content,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
            fit: BoxFit.cover,
          ));
          final image = NetworkImage(element.content);
          final completer = Completer<ImageInfo>();

          // Create image stream and listener
          final ImageStream stream = image.resolve(ImageConfiguration.empty);
          final ImageStreamListener listener =
              ImageStreamListener((ImageInfo info, bool _) {
            completer.complete(info);
          });

          // Add listener and remove it once done
          stream.addListener(listener);
          final imageInfo = await completer.future;
          stream.removeListener(listener);

          // Get image dimensions
          final imageWidth = imageInfo.image.width.toDouble();
          final imageHeight = imageInfo.image.height.toDouble();
          currentImageAspectRatio.add(imageWidth / imageHeight);
        } else {
          mediaList.add(Image.file(
            cachedAsset.file,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
            fit: BoxFit.cover,
          ));
          final image = FileImage(cachedAsset.file);
          final completer = Completer<ImageInfo>();

          // Create image stream and listener
          final ImageStream stream = image.resolve(ImageConfiguration.empty);
          final ImageStreamListener listener =
              ImageStreamListener((ImageInfo info, bool _) {
            completer.complete(info);
          });

          // Add listener and remove it once done
          stream.addListener(listener);
          final imageInfo = await completer.future;
          stream.removeListener(listener);

          // Get image dimensions
          final imageWidth = imageInfo.image.width.toDouble();
          final imageHeight = imageInfo.image.height.toDouble();
          currentImageAspectRatio.add(imageWidth / imageHeight);
        }
        controllerList.add(null);
      } else {
        VideoPlayerController controller =
            VideoPlayerController.networkUrl(Uri.parse(element.content));

        if (cachedAsset != null) {
          controller = VideoPlayerController.file(cachedAsset.file);
        }

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
        currentImageAspectRatio.add(16 / 9);
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
                    aspectRatio: currentImageAspectRatio[adsCounter],
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
