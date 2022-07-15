import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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

  String _status = 'aguardando selecionar arquivo.';
  String dropdownvalue = '20Mb';
  var items = [
    '5Mb',
    '10Mb',
    '15Mb',
    '20Mb',
    '30Mb',
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
            Text(
              'Status: $_status',
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
      _status = 'pronto para cortar...';
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
    bool working = true;
    int fileIndex = 1;
    int limitSize = 20971520;
    double startTime = 0.0;
    double totalDurationVideo = 0.0; //tempo total do video aberto
    String outFileName = '';

    switch (dropdownvalue) {
      case '5Mb':
        limitSize = 5242880;
        break;
      case '10Mb':
        limitSize = 10485760;
        break;
      case '15Mb':
        limitSize = 15728640;
        break;
      case '20Mb':
        limitSize = 20971520;
        break;
      case '30Mb':
        limitSize = 31457280;
        break;
    }
    String openFileDir = _filePath!.substring(0, _filePath!.lastIndexOf("\\"));
    String openFileName = _filePath!
        .substring(_filePath!.lastIndexOf("\\"), _filePath!.lastIndexOf("."));
    // pega caminho absoluto ate o executavel do app
    String mainPath = Platform.resolvedExecutable;
    //remover o nome do app co caminho
    mainPath = mainPath.substring(0, mainPath.lastIndexOf("\\"));
    //adiciona o caminho para chegar nos assets
    Directory directoryExe =
        Directory("$mainPath\\data\\flutter_assets\\assets");

    //PEGAR O TEMPO TOTAL DO VIDEO
    var totalDurationVideoProcess = await Process.run(
      'ffprobe',
      [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        //'-sexagesimal',
        _filePath!,
      ],
      workingDirectory: directoryExe.path,
      runInShell: true,
    );
    double? value = double.tryParse(totalDurationVideoProcess.stdout);
    if (value != null) {
      totalDurationVideo = value;
    }
    print('cortar!-----------$totalDurationVideo---------------------------');

    //print(directoryExe.path);
    //print('Dir do video aberto: $openFileDir');
    //print('Arquivo de saida: $outFileName');
    //cria diretorio com nome do arquivo aberto

    //String comando =
    //   'ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal C:\\teste\\2020-11-07_01-31-39.mkv';

    Directory('$openFileDir$openFileName').create(); //criar diretorio
    while (working == true) {
      //gera novo nome de saida
      outFileName = '$openFileDir$openFileName\\out_$fileIndex.$_fileExtension';
      _status = 'cortando... $outFileName';
      setState(() {});
      try {
        var process = await Process.run(
          'ffmpeg',
          [
            '-ss',
            startTime.toString(),
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

        var exitCode = process.exitCode;
        print('exit code: $exitCode');
        if (exitCode != 0) {
          print('Erro!');
          _status = 'Erro: exit code $exitCode';
          setState(() {});
          return;
        }
      } catch (e) {
        print(e);
      }
      //pegar a duração do video recem cortado...
      var getFileTimeprocess = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          //'-sexagesimal',
          outFileName,
        ],
        workingDirectory: directoryExe.path,
        runInShell: true,
      );
      print('Ultimo Start: $startTime');
      double? value = double.tryParse(getFileTimeprocess.stdout);
      if (value != null) {
        startTime = startTime + value;
      }

      print('tempo processado: $startTime');

      if ((totalDurationVideo - startTime) < 1) {
        _status = 'Cortes completados com sucesso!';
        setState(() {});
        working = false;
      }
      //tem mais cortes...

      fileIndex += 1; //para proxima interação
    }
    return;
  }
}
