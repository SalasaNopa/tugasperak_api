import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple File Sharing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SimpleFileSharingPage(),
    );
  }
}

class SimpleFileSharingPage extends StatefulWidget {
  @override
  _SimpleFileSharingPageState createState() => _SimpleFileSharingPageState();
}

class _SimpleFileSharingPageState extends State<SimpleFileSharingPage> {
  String? _downloadLink;
  bool _isUploading = false;
  String? _fileSize; 
  String? _fileName; 

  Future<void> _uploadFile() async {
    // Pilih file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      // Dapatkan nama file
      setState(() {
        _fileName = result.files.single.name;
        _isUploading = true;
      });

      // Dapatkan ukuran file
      int sizeInBytes = await file.length();
      String formattedSize = _formatBytes(sizeInBytes); 

      // Unggah file ke server
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://file.io'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonResponse = jsonDecode(responseData.body);
        setState(() {
          _downloadLink = jsonResponse['link']; // Tampilkan link hasil unggahan
          _fileSize = formattedSize; // Simpan ukuran file
          _isUploading = false;
        });
      } else {
        print('File upload failed');
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Fungsi untuk menyalin link ke clipboard
  void _copyToClipboard() {
    if (_downloadLink != null) {
      Clipboard.setData(ClipboardData(text: _downloadLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download link copied to clipboard!')),
      );
    }
  }

  // Fungsi untuk memformat ukuran file
  String _formatBytes(int bytes, {int decimalPlaces = 2}) {
    List<String> units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimalPlaces)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[800],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Judul utama
              Text(
                'Super simple file sharing!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 30),
              // Bagian setelah upload file
              if (_downloadLink != null)
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'File Name: $_fileName', 
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'File Size: $_fileSize',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Your file is ready to share!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 5),
                        // Teks untuk menyalin link
                        Text(
                          'Copy the download link below',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SelectableText(
                                _downloadLink ?? '', 
                                style: TextStyle(color: Colors.deepPurple[800]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _copyToClipboard,
                              child: Icon(Icons.copy, size: 18),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(8),
                                shape: CircleBorder(),
                                backgroundColor: Colors.deepPurple[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFile,
                icon: Icon(Icons.upload_file, color: Colors.deepPurple[800]),
                label: _isUploading
                    ? Text('Uploading...', style: TextStyle(color: Colors.deepPurple[800]))
                    : Text('Upload Files', style: TextStyle(color: Colors.deepPurple[800])),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
