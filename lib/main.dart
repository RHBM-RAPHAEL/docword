import 'package:flutter/material.dart';

void main() => runApp(const DocWordApp());

class DocWordApp extends StatelessWidget {
  const DocWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocWord | RHBM TecnoWork',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A5C9E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080D16),
        fontFamily: 'Arial',
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _editorFocus = FocusNode();
  double _fontSize = 14;
  String _fontFamily = 'Arial';
  double _zoom = 1;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  TextAlign _align = TextAlign.left;
  String _documentName = 'Documento sem título';

  int get _words {
    final value = _controller.text.trim();
    if (value.isEmpty) return 0;
    return value.split(RegExp(r'\s+')).length;
  }

  void _newDocument() {
    setState(() {
      _controller.clear();
      _documentName = 'Documento sem título';
      _fontSize = 14;
      _fontFamily = 'Arial';
      _bold = false;
      _italic = false;
      _underline = false;
      _align = TextAlign.left;
    });
    _editorFocus.requestFocus();
  }

  void _comingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action será conectado ao sistema de arquivos na próxima versão.')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          _buildTabs(),
          _buildToolbar(),
          Expanded(child: _buildWorkspace()),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF050913), Color(0xFF0A1830), Color(0xFF082A46)]),
        border: Border(bottom: BorderSide(color: Color(0xFF00D9FF), width: 1)),
        boxShadow: [BoxShadow(color: Color(0x3300D9FF), blurRadius: 14)],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF),
              border: Border.all(color: const Color(0xFF72F1FF), width: 1),
              boxShadow: const [BoxShadow(color: Color(0x6600D9FF), blurRadius: 12)],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('D', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 11),
          const Text('DocWord', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Text('RHBM TECNOWORK', style: TextStyle(color: Color(0xFF8DDCF5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 22),
          Expanded(
            child: Text(_documentName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          IconButton(onPressed: () => _comingSoon('Salvar'), tooltip: 'Salvar', icon: const Icon(Icons.save_outlined, color: Colors.white)),
          IconButton(onPressed: () => _comingSoon('Compartilhar'), tooltip: 'Compartilhar', icon: const Icon(Icons.ios_share_outlined, color: Colors.white)),
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
          _tab('Inserir'),
          _tab('Layout'),
          _tab('Revisão'),
          const Spacer(),
          const Icon(Icons.cloud_done_outlined, size: 18, color: Color(0xFF00D9FF)),
          const SizedBox(width: 6),
          const Text('Local', style: TextStyle(fontSize: 12, color: Color(0xFF8FA8BD))),
        ],
      ),
    );
  }

  Widget _tab(String text, {bool selected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _comingSoon(text),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: selected ? const Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 3)) : null,
        ),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF70F0FF) : const Color(0xFFB7C7D9))),
      ),
    );
  }

  void _showFileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.note_add_outlined), title: const Text('Novo documento'), onTap: () { Navigator.pop(context); _newDocument(); }),
          ListTile(leading: const Icon(Icons.folder_open), title: const Text('Abrir'), onTap: () { Navigator.pop(context); _comingSoon('Abrir'); }),
          ListTile(leading: const Icon(Icons.save_outlined), title: const Text('Salvar'), onTap: () { Navigator.pop(context); _comingSoon('Salvar'); }),
          ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Exportar como PDF'), onTap: () { Navigator.pop(context); _comingSoon('Exportar PDF'); }),
        ]),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1726),
        border: Border(bottom: BorderSide(color: Color(0xFF17334B))),
        boxShadow: [BoxShadow(color: Color(0x3300D9FF), blurRadius: 8)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
          _toolIcon(Icons.undo, 'Desfazer', () => _comingSoon('Desfazer')),
          _toolIcon(Icons.redo, 'Refazer', () => _comingSoon('Refazer')),
          _divider(),
          SizedBox(
            width: 200,
            height: 40,
            child: DropdownButtonFormField<String>(
              initialValue: _fontFamily,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF31516B))), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF31516B))), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              items: const ['Arial', 'Calibri', 'Times New Roman'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _fontFamily = v);
                _editorFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 90,
            height: 40,
            child: DropdownButtonFormField<double>(
              initialValue: _fontSize,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF31516B))), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF31516B))), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              items: <double>[10, 11, 12, 14, 16, 18, 20, 24, 28, 32].map((e) => DropdownMenuItem(value: e, child: Text('${e.toInt()}'))).toList(),
              onChanged: (v) {
                setState(() => _fontSize = v ?? 14);
                _editorFocus.requestFocus();
              },
            ),
          ),
          _divider(),
          _toggle(Icons.format_bold, 'Negrito', _bold, () => setState(() => _bold = !_bold)),
          _toggle(Icons.format_italic, 'Itálico', _italic, () => setState(() => _italic = !_italic)),
          _toggle(Icons.format_underline, 'Sublinhado', _underline, () => setState(() => _underline = !_underline)),
          _divider(),
          _alignButton(Icons.format_align_left, TextAlign.left),
          _alignButton(Icons.format_align_center, TextAlign.center),
          _alignButton(Icons.format_align_right, TextAlign.right),
          _alignButton(Icons.format_align_justify, TextAlign.justify),
          _divider(),
          _toolIcon(Icons.format_list_bulleted, 'Marcadores', () => _insertPrefix('• ')),
          _toolIcon(Icons.format_list_numbered, 'Numeração', () => _insertPrefix('1. ')),
          ],
        ),
      ),
    );
  }

  void _insertPrefix(String prefix) {
    final selection = _controller.selection;
    final pos = selection.isValid ? selection.start : _controller.text.length;
    _controller.text = _controller.text.replaceRange(pos, pos, prefix);
    _controller.selection = TextSelection.collapsed(offset: pos + prefix.length);
    setState(() {});
    _editorFocus.requestFocus();
  }

  Widget _toolIcon(IconData icon, String tooltip, VoidCallback onTap) => IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon, size: 20, color: const Color(0xFFB9D8EA)));

  Widget _toggle(IconData icon, String tooltip, bool active, VoidCallback onTap) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: active ? const Color(0xFF123B52) : Colors.transparent, borderRadius: BorderRadius.circular(5)),
    child: IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon, size: 20, color: active ? const Color(0xFF00E5FF) : const Color(0xFFB9D8EA))),
  );

  Widget _alignButton(IconData icon, TextAlign value) => _toggle(icon, 'Alinhamento', _align == value, () => setState(() => _align = value));

  Widget _divider() => Container(width: 1, height: 34, color: const Color(0xFF29445B), margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _buildWorkspace() {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = (constraints.maxWidth - 48).clamp(280.0, double.infinity);
      final pageWidth = (794.0 * _zoom).clamp(280.0, availableWidth);
      final pageHeight = 1123.0 * _zoom;
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF15263A), Color(0xFF090F19)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: Center(
            child: Container(
              width: pageWidth,
              height: pageHeight,
              padding: EdgeInsets.fromLTRB(76 * _zoom, 72 * _zoom, 76 * _zoom, 72 * _zoom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF28475D)),
                boxShadow: const [
                  BoxShadow(color: Color(0x5500D9FF), blurRadius: 18, spreadRadius: -8),
                  BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _editorFocus,
                maxLines: null,
                expands: true,
                textAlign: _align,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: _fontSize * _zoom,
                  fontFamily: _fontFamily,
                  height: 1.5,
                  fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
                  decoration: _underline ? TextDecoration.underline : TextDecoration.none,
                  color: const Color(0xFF202124),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Comece a escrever...',
                  hintStyle: TextStyle(color: Color(0xFFB0B7BF)),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatusBar() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF060B13),
        border: Border(top: BorderSide(color: Color(0xFF123A51))),
      ),
      child: Row(
        children: [
          const Text('Página 1 de 1', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 20),
          Text('$_words palavras', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const Spacer(),
          const Icon(Icons.remove, color: Colors.white70, size: 17),
          SizedBox(
            width: 130,
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Color(0xFF00D9FF),
                inactiveTrackColor: Color(0xFF29445B),
                thumbColor: Color(0xFF6EF2FF),
                overlayColor: Color(0x2200D9FF),
              ),
              child: Slider(
              value: _zoom,
              min: .7,
              max: 1.3,
              divisions: 6,
              onChanged: (v) => setState(() => _zoom = v),
              ),
            ),
          ),
          const Icon(Icons.add, color: Colors.white70, size: 17),
          const SizedBox(width: 8),
          Text('${(_zoom * 100).round()}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
