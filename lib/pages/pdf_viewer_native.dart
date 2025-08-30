// lib/pages/pdf_viewer_native.dart

import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// 在原生平台，我们不需要注册任何东西。
void registerPlatformView(String viewId, Uint8List pdfBytes) {}

// 在原生平台，我们使用 SfPdfViewer.memory。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  return SfPdfViewer.memory(pdfBytes);
}
