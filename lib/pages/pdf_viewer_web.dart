// lib/pages/pdf_viewer_web.dart

import 'dart:typed_data';
import 'dart:html' as html;

// MODIFIED: 导入 dart:ui_web 而不是 dart:ui
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

// 在 Web 平台，我们注册一个 IFrame。
void registerPlatformView(String viewId, Uint8List pdfBytes) {
  // MODIFIED: 使用 ui_web.platformViewRegistry
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    return html.IFrameElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';
  });
}

// 在 Web 平台，我们使用 HtmlElementView 来显示这个 IFrame。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  return HtmlElementView(viewType: viewId);
}
