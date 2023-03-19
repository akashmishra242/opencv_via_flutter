import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import 'select_or_capture_image_to_show_depth_map.dart';

class ShowDepthMap extends StatefulWidget {
  final String url;

  const ShowDepthMap({super.key, required this.url});

  @override
  _ShowDepthMapState createState() => _ShowDepthMapState();
}

class _ShowDepthMapState extends State<ShowDepthMap> {
  final String _firstImagePath = 'assets/imgL.png';
  final String _secondImagePath = 'assets/imgR.png';
  Uint8List? _imageData;
  bool _isLoading = false;

  Future<Uint8List> _loadImage(String imagePath) async {
    final ByteData assetByteData = await rootBundle.load(imagePath);
    return assetByteData.buffer.asUint8List();
  }

  Future<void> _callApi() async {
    setState(() {
      _isLoading = true;
    });
    final url = widget.url;
    final headers = {'Content-Type': 'multipart/form-data'};
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);
    final firstImageData = await _loadImage(_firstImagePath);
    final secondImageData = await _loadImage(_secondImagePath);
    request.files.add(http.MultipartFile.fromBytes('image1', firstImageData,
        filename: 'imgL.png'));
    request.files.add(http.MultipartFile.fromBytes('image2', secondImageData,
        filename: 'imgR.png'));
    final response = await request.send();
    final responseData = await response.stream.toBytes();
    setState(() {
      _imageData = Uint8List.fromList(responseData);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depth Map'),
        actions: [
          const Center(
              child: Text(
            'Go to custom depth map screen',
            textScaleFactor: 0.8,
          )),
          IconButton(
            icon: const Icon(Icons.navigate_next_sharp),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DepthMapScreen(
                      url:
                          'https://opencv-depth-map-api.onrender.com/depth-map'),
                )),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/imgL.png',
              width: MediaQuery.of(context).size.width * 0.75,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/imgR.png',
              width: MediaQuery.of(context).size.width * 0.75,
            ),
            const SizedBox(height: 16),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _imageData == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Please select two images'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _callApi,
                              child: const Text('Generate Depth Map'),
                            ),
                          ],
                        )
                      : Image.memory(_imageData!),
            ),
          ],
        ),
      ),
    );
  }
}
