import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process/process.dart';

void main() {
  runApp(const CortaVideoApp());
}

class CortaVideoApp extends StatelessWidget {
  const CortaVideoApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'CortaVideoApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _filePath = 'Nenhum arquivo selecionado';
  String? _fileExtension = '';
  String? _tamanho = '0';
  String dropdownvalue = '20 Mb';
  var items = [
    '5 Mb',
    '10 Mb',
    '15 Mb',
    '20 Mb',
    '25 Mb',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Escolha o Vídeo'),
            ),
            Text(
              '$_filePath',
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              'Tamanho: $_tamanho bytes',
            ),
            DropdownButton(
              value: dropdownvalue, // Initial Value
              icon: const Icon(Icons.keyboard_arrow_down), // Down Arrow Icon
              // Array list of items
              items: items.map((String items) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items),
                );
              }).toList(),
              // After selecting the desired option,it will
              // change button value to selected value
              onChanged: (String? newValue) {
                setState(() {
                  dropdownvalue = newValue!;
                });
              },
            ),
            ElevatedButton(
              onPressed: _cortaVideo,
              child: const Text('Cortar Vídeo'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      PlatformFile file = result.files.first;
      _filePath = file.path;
      _fileExtension = file.extension;
      _tamanho = file.size.toString();
      print(file.name);
      print(file.bytes);
      print(file.size);
      print(file.extension);
      print(file.path);
    } else {
      print('Janela fechada. Não escolheu arquivo');
    }
    setState(() {});
  }

  void _cortaVideo() async {
    int fileIndex = 1;
    int limitSize = 20971520;

    switch (dropdownvalue) {
      case '20Mb':
        limitSize = 20971520;
        break;
    }
    print('cortar!-----------------------------------------');
    String openFileDir = _filePath!.substring(0, _filePath!.lastIndexOf("\\"));
    String openFileName = _filePath!
        .substring(_filePath!.lastIndexOf("\\"), _filePath!.lastIndexOf("."));

    final Directory result = await getApplicationSupportDirectory();
    // returns the abolute path of the executable file of your app:
    String mainPath = Platform.resolvedExecutable;
    // remove from that path the name of the executable file of your app:
    mainPath = mainPath.substring(0, mainPath.lastIndexOf("\\"));
    Directory directoryExe =
        Directory("$mainPath\\data\\flutter_assets\\assets");
    print(directoryExe.path);
    print('Dir do video aberto: $openFileDir');
    String outFileName =
        '$openFileDir$openFileName\\out_$fileIndex.$_fileExtension';
    print('Arquivo de saida: $outFileName');
    //cria diretorio com nome do arquivo aberto
    var outDir = Directory('$openFileDir$openFileName').create();

    try {
      var process = await Process.run(
        'ffmpeg',
        [
          '-i',
          _filePath!,
          '-c',
          'copy',
          '-fs',
          limitSize.toString(),
          outFileName,
        ],
        workingDirectory: directoryExe.path,
        runInShell: true,
      );
      print('foiii----');
      var exitCode = await process.exitCode;
      print('exit code: $exitCode');
    } catch (e) {
      print(e);
    }

    return;
  }
}
