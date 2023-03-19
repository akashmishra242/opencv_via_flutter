import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DepthMapScreen extends StatefulWidget {
  final String url;

  const DepthMapScreen({Key? key, required this.url}) : super(key: key);

  @override
  _DepthMapScreenState createState() => _DepthMapScreenState();
}

class _DepthMapScreenState extends State<DepthMapScreen> {
  File? _firstImage;
  File? _secondImage;
  Uint8List? _depthMap;
  bool _isLoading = false;
  int _numDisparities = 16;
  int _blockSize = 15;

  Future<void> _getImage(ImageSource source, int imageIndex) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (imageIndex == 1) {
        _firstImage = File(pickedFile!.path);
      } else {
        _secondImage = File(pickedFile!.path);
      }
    });
  }

  Future<void> _callApi() async {
    setState(() {
      _isLoading = true;
    });

    final url = widget.url;
    final headers = {'Content-Type': 'multipart/form-data'};
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);

    final firstImageData = await _firstImage!.readAsBytes();
    final secondImageData = await _secondImage!.readAsBytes();

    request.fields['numDisparities'] = _numDisparities.toString();
    request.fields['blockSize'] = _blockSize.toString();

    request.files.add(http.MultipartFile.fromBytes('image1', firstImageData,
        filename: 'first_image.jpg'));
    request.files.add(http.MultipartFile.fromBytes('image2', secondImageData,
        filename: 'second_image.jpg'));

    final response = await request.send();
    final responseData = await response.stream.toBytes();

    setState(() {
      _depthMap = Uint8List.fromList(responseData);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depth Map'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _firstImage != null
                        ? Image.file(
                            _firstImage!,
                            width: MediaQuery.of(context).size.width * 0.5 - 10,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image,
                            size: 120,
                          ),
                    ElevatedButton(
                      onPressed: () => _getImage(ImageSource.gallery, 1),
                      child: const Text('Select from gallery '),
                    ),
                    ElevatedButton(
                      onPressed: () => _getImage(ImageSource.camera, 1),
                      child: const Text('Capture'),
                    ),
                  ],
                ),
                Column(
                  children: [
                    _secondImage != null
                        ? Image.file(
                            _secondImage!,
                            width: MediaQuery.of(context).size.width * 0.5 - 10,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image,
                            size: 120,
                          ),
                    ElevatedButton(
                      onPressed: () => _getImage(ImageSource.gallery, 2),
                      child: const Text('Select from gallery'),
                    ),
                    ElevatedButton(
                      onPressed: () => _getImage(ImageSource.camera, 2),
                      child: const Text('Capture'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Num Disparities: $_numDisparities',
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              value: _numDisparities.toDouble(),
              min: 16,
              max: 256,
              divisions: 15,
              onChanged: (double value) {
                setState(() {
                  _numDisparities = value.toInt();
                });
              },
            ),
            Text(
              'Block Size: $_blockSize',
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              value: _blockSize.toDouble(),
              min: 5,
              max: 255,
              divisions: 125,
              onChanged: (double value) {
                setState(() {
                  _blockSize = value.toInt();
                });
              },
            ),
            ElevatedButton(
              onPressed: _firstImage != null && _secondImage != null
                  ? _isLoading
                      ? null
                      : _callApi
                  : null,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Depth Map'),
            ),
            if (_depthMap != null) ...[
              const SizedBox(height: 16),
              Image.memory(
                _depthMap!,
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
