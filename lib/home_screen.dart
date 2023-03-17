import 'package:flutter/material.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart' as cv;

import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Uint8List img1Bytes;
  late Uint8List img2Bytes;

  @override
  void initState() {
    super.initState();
    loadImageBytes();
  }

  Future<void> loadImageBytes() async {
    final img1Data = await rootBundle.load('assets/imgL.png');
    final img2Data = await rootBundle.load('assets/imgR.png');
    setState(() {
      img1Bytes = img1Data.buffer.asUint8List();
      img2Bytes = img2Data.buffer.asUint8List();
    });
  }

  Future<List<Uint8List?>> computeDepthMap() async {
    if (img1Bytes != null && img2Bytes != null) {
      final gray1 = await cv.Cv2.cvtColor(
        pathFrom: CVPathFrom.ASSETS,
        pathString: 'assets/imgL.png',
        outputType: cv.Cv2.COLOR_BGR2GRAY,
      );

      final gray2 = await cv.Cv2.cvtColor(
        pathFrom: CVPathFrom.ASSETS,
        pathString: 'assets/imgR.png',
        outputType: cv.Cv2.COLOR_BGR2GRAY,
      );
      final _byte = await cv.Cv2.applyColorMap(
        pathFrom: CVPathFrom.URL,
        pathString:
            'https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/16fe9f114930481.6044f05fca574.jpeg?raw=true',
        colorMap: cv.Cv2.COLORMAP_JET,
      );
      return [gray1, gray2, _byte];

      // final sgbm = cv.StereoSGBM(
      //   minDisparity: 0,
      //   numDisparities: 64,
      //   blockSize: 5,
      //   preFilterCap: 63,
      //   uniquenessRatio: 10,
      //   speckleWindowSize: 100,
      //   speckleRange: 32,
      //   disp12MaxDiff: 1,
      //   mode: cv.StereoSGBM.MODE_SGBM,
      // );

      // final disparity = await sgbm.compute(gray1, gray2);
      // return disparity.data.buffer.asUint8List();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Depth Map Example'),
      ),
      body: FutureBuilder<List<Uint8List?>>(
        future: computeDepthMap(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    Text('Image ${index + 1}'),
                    Image.memory(snapshot.data![index]!),
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
