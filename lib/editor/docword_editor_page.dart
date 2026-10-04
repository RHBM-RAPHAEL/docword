import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../services/docword_file_service.dart';

class DocWordEditorPage extends StatefulWidget {
  const DocWordEditorPage({super.key});

  @override
  State<DocWordEditorPage> createState() => _DocWordEditorPageState();
}

class _DocWordEditorPageState extends State<DocWordEditorPage> {
  late final QuillController _controller;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final DocWordFileService _fileService = DocWordFileService();

  String _documentName = 'Documento sem título';
  String _lastSavedSnapshot = '';
  bool _isDirty = false;
  bool _isBusy = false;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _lastSavedSnapshot = _documentSnapshot;
    _controller.addListener(_handleDocumentChanged);
  }

  String get _documentSnapshot =>
      jsonEncode(_controller.document.toDelta().toJson());

  String get _plainText {
    final text = _controller.document.toPlainText();
    return text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
  }

  int get _wordCount {
    final value = _plainText.trim();
    if (value.isEmpty) return 0;
    return value.split(RegExp(r'\s+')).length;
  }

  int get _characterCount => _plainText.length;

  void _handleDocumentChanged() {
    final dirty = _documentSnapshot != _lastSavedSnapshot;
    if (!mounted || dirty == _isDirty) return;
    setState(() => _isDirty = dirty);
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
          'Existem alterações que ainda não foram salvas. Deseja descartá-las?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _newDocument() async {
    if (!await _confirmDiscardIfNeeded()) return;

    _controller.removeListener(_handleDocumentChanged);
    _controller.document = Document();
    _controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    _controller.addListener(_handleDocumentChanged);

    setState(() {
      _documentName = 'Documento sem título';
      _lastSavedSnapshot = _documentSnapshot;
      _isDirty = false;
      _zoom = 1.0;
    });

    _editorFocus.requestFocus();
  }

  Future<void> _openDocument() async {
    if (!await _confirmDiscardIfNeeded()) return;

    await _runBusy(() async {
      final data = await _fileService.openDocWord();
      if (data == null || !mounted) return;

      _controller.removeListener(_handleDocumentChanged);
      _controller.document = Document.fromJson(data.delta);
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      _controller.addListener(_handleDocumentChanged);

      setState(() {
        _documentName = data.title;
        _lastSavedSnapshot = _documentSnapshot;
        _isDirty = false;
      });

      _editorFocus.requestFocus();
      _showMessage('Documento aberto.');
    });
  }

  Future<void> _saveDocument() async {
    await _runBusy(() async {
      final uri = await _fileService.saveDocWord(
        title: _documentName,
        delta: _controller.document.toDelta().toJson(),
      );

      if (uri == null || !mounted) return;

      final savedName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      final titleFromFile = savedName.replaceFirst(
        RegExp(r'\.docword$', caseSensitive: false),
        '',
      );

      setState(() {
        if (titleFromFile.trim().isNotEmpty) {
          _documentName = titleFromFile.trim();
        }
        _lastSavedSnapshot = _documentSnapshot;
        _isDirty = false;
      });

      _showMessage('Documento salvo com sucesso.');
      _editorFocus.requestFocus();
    });
  }

  Future<void> _exportTxt() async {
    await _runBusy(() async {
      final uri = await _fileService.exportPlainText(
        title: _documentName,
        text: _plainText,
      );
      if (uri != null && mounted) {
        _showMessage('Texto exportado com sucesso.');
      }
    });
  }

  Future<void> _renameDocument() async {
    final textController = TextEditingController(text: _documentName);

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome do documento'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    textController.dispose();

    if (value == null || value.trim().isEmpty || !mounted) return;
    setState(() => _documentName = value.trim());
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Não foi possível concluir a operação: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _editorFocus.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            () => _saveDocument(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            () => _openDocument(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            () => _newDocument(),
      },
      child: Scaffold(
        body: Column(
          children: [
            _buildTopBar(),
            _buildTabs(),
            _buildToolbar(),
            Expanded(child: _buildWorkspace()),
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF050913),
            Color(0xFF0A1830),
            Color(0xFF082A46),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF00D9FF), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x3300D9FF), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF),
              border: Border.all(
                color: const Color(0xFF72F1FF),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x6600D9FF), blurRadius: 12),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Text(
            'DocWord',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'RHBM TECNOWORK',
            style: TextStyle(
              color: Color(0xFF8DDCF5),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: InkWell(
              onTap: _renameDocument,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${_isDirty ? '• ' : ''}$_documentName',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isDirty
                        ? const Color(0xFF70F0FF)
                        : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            onPressed: _isBusy ? null : _saveDocument,
            tooltip: 'Salvar (Ctrl+S)',
            icon: const Icon(Icons.save_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: _exportTxt,
            tooltip: 'Exportar TXT',
            icon: const Icon(Icons.text_snippet_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 42,
      color: const Color(0xFF0B1220),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tab('Arquivo', onTap: _showFileMenu),
          _tab('Início', selected: true),
          _tab('Inserir', onTap: () => _showMessage('Inserir será ampliado na próxima etapa.')),
          _tab('Layout', onTap: () => _showMessage('Layout será ampliado na próxima etapa.')),
          _tab('Revisão', onTap: () => _showMessage('Revisão será ampliada na próxima etapa.')),
          const Spacer(),
          const Icon(
            Icons.description_outlined,
            size: 18,
            color: Color(0xFF00D9FF),
          ),
          const SizedBox(width: 6),
          const Text(
            'Rich Text',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8FA8BD),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String text, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: selected
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFF00E5FF),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? const Color(0xFF70F0FF)
                : const Color(0xFFB7C7D9),
          ),
        ),
      ),
    );
  }

  void _showFileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Novo documento'),
              subtitle: const Text('Ctrl+N'),
              onTap: () {
                Navigator.pop(context);
                _newDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Abrir .docword'),
              subtitle: const Text('Ctrl+O'),
              onTap: () {
                Navigator.pop(context);
                _openDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Salvar .docword'),
              subtitle: const Text('Ctrl+S'),
              onTap: () {
                Navigator.pop(context);
                _saveDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Exportar como TXT'),
              onTap: () {
                Navigator.pop(context);
                _exportTxt();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1726),
        border: Border(
          bottom: BorderSide(color: Color(0xFF17334B)),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x3300D9FF), blurRadius: 8),
        ],
      ),
      child: ClipRect(
        child: QuillSimpleToolbar(
          controller: _controller,
          config: QuillSimpleToolbarConfig(
            buttonOptions: QuillSimpleToolbarButtonOptions(
              base: QuillToolbarBaseButtonOptions(
                afterButtonPressed: () {
                  _editorFocus.requestFocus();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            (constraints.maxWidth - 48).clamp(300.0, double.infinity);
        final pageWidth = (794.0 * _zoom).clamp(300.0, availableWidth);
        final pageHeight = 1123.0 * _zoom;

        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                Color(0xFF15263A),
                Color(0xFF090F19),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: 30,
              horizontal: 24,
            ),
            child: Center(
              child: Container(
                width: pageWidth,
                height: pageHeight,
                padding: EdgeInsets.fromLTRB(
                  76 * _zoom,
                  72 * _zoom,
                  76 * _zoom,
                  72 * _zoom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF28475D),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x5500D9FF),
                      blurRadius: 18,
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(_zoom),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    child: QuillEditor(
                      focusNode: _editorFocus,
                      scrollController: _editorScrollController,
                      controller: _controller,
                      config: const QuillEditorConfig(
                        placeholder: 'Comece a escrever...',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF060B13),
        border: Border(
          top: BorderSide(color: Color(0xFF123A51)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'A4 • Rich Text',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '$_wordCount palavras',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_characterCount caracteres',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _zoom <= .7
                ? null
                : () => setState(() => _zoom = (_zoom - .1).clamp(.7, 1.4)),
            tooltip: 'Diminuir zoom',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 17),
          ),
          SizedBox(
            width: 130,
            child: Slider(
              value: _zoom,
              min: .7,
              max: 1.4,
              divisions: 7,
              onChanged: (value) => setState(() => _zoom = value),
            ),
          ),
          IconButton(
            onPressed: _zoom >= 1.4
                ? null
                : () => setState(() => _zoom = (_zoom + .1).clamp(.7, 1.4)),
            tooltip: 'Aumentar zoom',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 17),
          ),
          const SizedBox(width: 6),
          Text(
            '${(_zoom * 100).round()}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
