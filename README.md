# DocWord

Editor de documentos gratuito da **RHBM TecnoWork**, desenvolvido em Flutter.

## Versão 0.2 — Rich Text

A versão 0.2 substitui o campo de texto simples por um motor de edição rich text baseado em Flutter Quill.

### Recursos atuais

- Formatação por seleção de texto.
- Negrito, itálico, sublinhado, tachado e outros controles rich text da toolbar.
- Alinhamento e listas estruturadas.
- Undo/redo pelo motor do editor.
- Atalhos de documento:
  - `Ctrl+N`: novo documento.
  - `Ctrl+O`: abrir documento.
  - `Ctrl+S`: salvar documento.
- Formato nativo `.docword`, armazenando o documento em Delta JSON.
- Abrir e salvar documentos `.docword`.
- Exportação para `.txt`.
- Indicador de alterações não salvas.
- Renomear documento clicando no nome no topo.
- Contador de palavras e caracteres.
- Zoom de 70% a 140%.
- Interface desktop com identidade própria da RHBM TecnoWork.

## Executar

```bash
flutter pub get
flutter run -d windows
```

## Verificação

```bash
flutter analyze
flutter test
```

Veja `docs/ROADMAP.md` para as próximas etapas.
