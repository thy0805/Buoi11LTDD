import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THYZONE Cloud Storage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const StorageScreen(),
    );
  }
}

class UploadItem {
  final String name;
  final String path;
  double progress = 0.0;
  String status = "Running";
  CancelToken? cancelToken;

  UploadItem({required this.name, required this.path, this.cancelToken});
}

class CloudinaryFile {
  final String name;
  final String url;

  CloudinaryFile({required this.name, required this.url});

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
  };

  factory CloudinaryFile.fromJson(Map<String, dynamic> json) => CloudinaryFile(
    name: json['name'] as String,
    url: json['url'] as String,
  );
}

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final List<UploadItem> _activeUploads = [];
  List<CloudinaryFile> _uploadedFiles = [];
  bool _loadingFiles = false;
  final _logger = Logger();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchUploadedFiles();
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/cloudinary_files.json');
  }

  void _fetchUploadedFiles() async {
    setState(() {
      _loadingFiles = true;
    });
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        setState(() {
          _uploadedFiles = jsonList.map((e) => CloudinaryFile.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _logger.e("Error loading files: $e");
    } finally {
      setState(() {
        _loadingFiles = false;
      });
    }
  }

  void _saveUploadedFiles() async {
    try {
      final file = await _getLocalFile();
      final jsonList = _uploadedFiles.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      _logger.e("Error saving files: $e");
    }
  }

  void _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.single.path == null) return;
      
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      
      final cancelToken = CancelToken();
      final item = UploadItem(name: fileName, path: filePath, cancelToken: cancelToken);
      
      setState(() {
        _activeUploads.add(item);
      });
      
      _startUpload(item);
    } catch (e) {
      _logger.e("Pick file error: $e");
    }
  }

  void _startUpload(UploadItem item) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(item.path, filename: item.name),
        'upload_preset': 'ml_default',
      });
      
      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/dhhhclbra/auto/upload',
        data: formData,
        cancelToken: item.cancelToken,
        onSendProgress: (sent, total) {
          if (total != -1) {
            setState(() {
              item.progress = sent / total;
              item.status = "Running";
            });
          }
        },
      );
      
      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String;
        setState(() {
          item.status = "Success";
          _activeUploads.remove(item);
          _uploadedFiles.add(CloudinaryFile(name: item.name, url: secureUrl));
        });
        _saveUploadedFiles();
      } else {
        setState(() {
          item.status = "Failed";
          _activeUploads.remove(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tải lên thất bại: Status code ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      setState(() {
        item.status = "Failed";
        _activeUploads.remove(item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tải lên thất bại: $e")),
      );
    }
  }

  void _pauseUpload(UploadItem item) {
    if (item.status == "Running") {
      item.cancelToken?.cancel("paused");
      setState(() {
        item.status = "Paused";
      });
    }
  }

  void _resumeUpload(UploadItem item) {
    if (item.status == "Paused") {
      final cancelToken = CancelToken();
      item.cancelToken = cancelToken;
      setState(() {
        item.status = "Running";
      });
      _startUpload(item);
    }
  }

  void _cancelUpload(UploadItem item) {
    item.cancelToken?.cancel("cancelled");
    setState(() {
      _activeUploads.remove(item);
    });
  }

  void _deleteFile(CloudinaryFile fileItem) {
    setState(() {
      _uploadedFiles.remove(fileItem);
    });
    _saveUploadedFiles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã xóa file thành công")),
    );
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  void _showImagePreview(BuildContext context, CloudinaryFile fileItem) {
    final isImage = _isImageFile(fileItem.name) || _isImageFile(fileItem.url);
    if (!isImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File này không phải là định dạng ảnh hiển thị được")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(fileItem.name, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                fileItem.url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("THYZONE Cloudinary Storage"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUploadedFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _pickAndUploadFile,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.deepPurple.withOpacity(0.05),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.deepPurple),
                    SizedBox(height: 8),
                    Text(
                      "Nhấn vào đây để tải file lên Cloudinary",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_activeUploads.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "TIẾN TRÌNH TẢI LÊN",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activeUploads.length,
                itemBuilder: (context, index) {
                  final item = _activeUploads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: item.progress.isNaN ? 0.0 : item.progress,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text("${(item.progress * 100).toStringAsFixed(0)}%"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Trạng thái: ${item.status}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Row(
                                children: [
                                  if (item.status == "Running")
                                    IconButton(
                                      icon: const Icon(Icons.pause, color: Colors.orange),
                                      onPressed: () => _pauseUpload(item),
                                    )
                                  else if (item.status == "Paused")
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                                      onPressed: () => _resumeUpload(item),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _cancelUpload(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "DANH SÁCH FILE ĐÃ TẢI LÊN",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _loadingFiles
                ? const Center(child: CircularProgressIndicator())
                : _uploadedFiles.isEmpty
                    ? const Center(child: Text("Chưa có file nào được tải lên"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _uploadedFiles.length,
                        itemBuilder: (context, index) {
                          final fileItem = _uploadedFiles[index];
                          final isImg = _isImageFile(fileItem.name) || _isImageFile(fileItem.url);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _showImagePreview(context, fileItem),
                              leading: isImg
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        fileItem.url,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                                      ),
                                    )
                                  : const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                              title: Text(
                                fileItem.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                fileItem.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFile(fileItem),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
