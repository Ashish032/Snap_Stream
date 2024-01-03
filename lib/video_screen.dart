import 'dart:io';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late VideoPlayerController _videoController;
  late List<File> _videos = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
    );

    await _cameraController.initialize();
    setState(() {});
  }

  void _recordVideo() async {
    if (!_cameraController.value.isRecordingVideo) {
      final DateTime now = DateTime.now();
      final String formattedDate =
          "${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}";
      final String videoPath =
          path.join((await getTemporaryDirectory()).path, '$formattedDate.mp4');

      await _cameraController.startVideoRecording();
    } else {
      final XFile video = await _cameraController.stopVideoRecording();
      setState(() {
        _videos.add(File(video.path));
      });
    }
  }

  Future<void> _pickAndUploadVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      File videoFile = File(result.files.single.path!);

      try {
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;

        if (user != null) {
          final String uid = user.uid;

          // Reference to the Firebase Storage bucket
          final firebase_storage.Reference storageRef = firebase_storage
              .FirebaseStorage.instance
              .ref()
              .child('gs://capture-and-upload-56bcb.appspot.com');

          // Upload the video file
          await storageRef.putFile(videoFile);

          // Get the download URL
          String downloadURL = await storageRef.getDownloadURL();

          // Now you can use 'downloadURL' to reference the uploaded video in your app
          print('Video uploaded. Download URL: $downloadURL');
        } else {
          // Handle user not authenticated
          print('User not authenticated');
        }
      } catch (error) {
        // Handle any exceptions that occur during the upload
        print('Error uploading video: $error');
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video App'),
      ),
      body: Column(
        children: [
          _cameraController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                )
              : Container(),
          Expanded(
            child: ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Video ${index + 1}'),
                  onTap: () {
                    _videoController =
                        VideoPlayerController.file(_videos[index])
                          ..initialize().then((_) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: AspectRatio(
                                    aspectRatio:
                                        _videoController.value.aspectRatio,
                                    child: VideoPlayer(_videoController),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _recordVideo,
            child: Icon(_cameraController.value.isRecordingVideo
                ? Icons.stop
                : Icons.fiber_manual_record),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _pickAndUploadVideo,
            child: const Icon(Icons.file_upload),
          ),
        ],
      ),
    );
  }
}
