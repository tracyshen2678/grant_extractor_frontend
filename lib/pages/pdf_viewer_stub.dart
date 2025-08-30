// lib/pages/pdf_viewer_stub.dart

import 'dart:typed_data';
import 'package:flutter/widgets.dart';

// 这个方法用于注册 Web 视图，在非 Web 平台它什么都不做。
void registerPlatformView(String viewId, Uint8List pdfBytes) {}

// 这个方法用于构建 PDF 查看器，如果被错误调用，它会抛出异常。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  throw UnsupportedError('Cannot create a PDF viewer for this platform.');
}
