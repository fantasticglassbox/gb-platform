import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:glassbox/manager/cache_manager.dart';
import 'package:glassbox/model/ads.dart';
import 'package:video_player/video_player.dart';

class Carousel extends StatefulWidget {
  final List<AdsModel> ads; // List of media items (both images and videos)

  const Carousel({Key? key, required this.ads}) : super(key: key);

  @override
  _MediaCarouselState createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<Carousel> {
  int currentIndex = 0;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();

    _downloadAndCacheMedia();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  // Method to cache media files before starting the carousel
  Future<void> _downloadAndCacheMedia() async {
    for (var mediaItem in widget.ads) {
      mediaItem.cachedFile ??= await _cacheMedia(mediaItem.content);
    }
    _playCurrentMedia(); // Start playing after caching is complete
  }

  Future<File?> _cacheMedia(String url) async {
    final GbCacheManager gbCacheManager = GbCacheManager();
    try {
      return await gbCacheManager.getCachedFile(url);
    } catch (e) {
      Navigator.pushNamed(context, '/connectivity');
    }
    return null;
  }

  void _playCurrentMedia() {
    if(widget.ads.isEmpty) {
      return;
    }
    final currentMedia = widget.ads[currentIndex];
    if (currentMedia.type == 'VIDEO') {
      _playVideo(currentMedia.cachedFile?.path ?? currentMedia.content);
    } else {
      _showImageForDuration(
          currentMedia.cachedFile?.path ?? currentMedia.content,
          currentMedia.duration);
    }
  }

  Future<void> _playVideo(String videoUrl) async {
    _disposeVideoPlayer(); // Dispose of previous controllers and clear timers

    final localPath = await _cacheMedia(
        videoUrl); // Ensure we're working with the local file path

    if (localPath == null || !localPath.existsSync()) {
      print('Local video file does not exist: $videoUrl');
      _nextMedia(); // Skip to next media if the file is not found
      return;
    }

    _videoPlayerController = VideoPlayerController.file(localPath);

    try {
      await _videoPlayerController!.initialize();
      if (_videoPlayerController!.value.hasError) {
        print(
            'Initialization error: ${_videoPlayerController!.value.errorDescription}');
        _nextMedia();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        showControls: false,
        showControlsOnInitialize: false,
        showOptions: false,
      );

      if (mounted) {
        setState(() {});
      }

      // Listen for video completion or errors
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.position ==
            _videoPlayerController!.value.duration) {
          _nextMedia();
        } else if (_videoPlayerController!.value.hasError) {
          print(
              'Playback error: ${_videoPlayerController!.value.errorDescription}');
          _nextMedia();
        }
      });
    } catch (error) {
      print('Error during video initialization: $error');
      _nextMedia();
    }

    print('Attempting to play video from: $videoUrl');
  }

  void _disposeVideoPlayer() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _imageTimer?.cancel(); // Cancel any image timers if they exist
    _videoPlayerController = null; // Clear the reference
    _chewieController = null; // Clear the reference
  }

  void _showImageForDuration(String imageUrl, int duration) {
    _disposeVideoPlayer(); // Dispose of any previous video controllers

    // Start a timer to show the image for the specified duration
    _imageTimer = Timer(Duration(seconds: duration), () {
      _nextMedia(); // Move to the next media after the timer expires
    });

    setState(() {});
  }

  void _nextMedia() {
    setState(() {
      // Increment current index and loop back to the start if at the end
      currentIndex = (currentIndex + 1) % widget.ads.length;
    });
    _playCurrentMedia(); // Play the next media
  }

  @override
  Widget build(BuildContext context) {
    // Check if ads list is empty
    if (widget.ads.isEmpty) {
      return Center(
        child: const Text('No ads available', style: TextStyle(fontSize: 24)),
      );
    }

    final currentMedia = widget.ads[currentIndex];
    print(
        'playing media ${currentMedia.content} ${currentMedia.cachedFile?.path}');
    return Center(
      child: currentMedia.type == 'VIDEO'
          ? (_chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _chewieController!
                      .videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              : const CircularProgressIndicator())
          : (currentMedia.cachedFile != null
              ? Image.file(
                  currentMedia.cachedFile!,
                  fit: BoxFit.cover, // Change fit to control how the image fits
                  width: MediaQuery.of(context)
                      .size
                      .width, // Ensure the image takes up the full width
                  height: MediaQuery.of(context)
                      .size
                      .height, // Ensure the image takes up the full height
                )
              : Image.network(
                  currentMedia.content,
                  fit: BoxFit.cover, // Change fit to control how the image fits
                  width: MediaQuery.of(context)
                      .size
                      .width, // Ensure the image takes up the full width
                  height: MediaQuery.of(context)
                      .size
                      .height, // Ensure the image takes up the full height
                )),
    );
  }
}
