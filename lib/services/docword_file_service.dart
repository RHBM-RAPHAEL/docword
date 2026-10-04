import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class DocWordDocumentData {
  const DocWordDocumentData({
    required this.title,
    required this.delta,
  });

  final String title;
  final List<dynamic> delta;
}

class DocWordFileService {
  static const String formatName = 'docword';
  static const int formatVersion = 1;

  Future<Uri?> saveDocWord({
    required String title,
    required List<dynamic> delta,
  }) {
    final payload = jsonEncode({
      'format': formatName,
      'version': formatVersion,
      'title': title,
      'savedAt': DateTime.now().toIso8601String(),
      'delta': delta,
    });

    return FilePicker.saveFile(
      dialogTitle: 'Salvar documento DocWord',
      fileName: _fileName(title, 'docword'),
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
  }

  Future<DocWordDocumentData?> openDocWord() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['docword'],
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo DocWord inválido.');
    }

    if (decoded['format'] != formatName) {
      throw const FormatException('Formato de documento não reconhecido.');
    }

    final delta = decoded['delta'];
    if (delta is! List) {
      throw const FormatException('Conteúdo do documento inválido.');
    }

    final rawTitle = decoded['title'];
    final title = rawTitle is String && rawTitle.trim().isNotEmpty
        ? rawTitle.trim()
        : _titleFromFileName(file.name);

    return DocWordDocumentData(
      title: title,
      delta: List<dynamic>.from(delta),
    );
  }

  Future<Uri?> exportPlainText({
    required String title,
    required String text,
  }) {
    return FilePicker.saveFile(
      dialogTitle: 'Exportar texto',
      fileName: _fileName(title, 'txt'),
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
  }

  String _fileName(String title, String extension) {
    final sanitized = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');

    final base = sanitized.isEmpty ? 'Documento' : sanitized;
    return '$base.$extension';
  }

  String _titleFromFileName(String name) {
    return name.replaceFirst(RegExp(r'\.docword$', caseSensitive: false), '');
  }
}
