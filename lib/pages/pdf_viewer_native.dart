import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// 在原生平台，我们不需要注册任何东西。
void registerPlatformView(String viewId, Uint8List pdfBytes) {}

// 清理函数（原生平台不需要做任何事）
void unregisterPlatformView(String viewId) {}

// 清理所有PDF查看器（原生平台不需要做任何事）
void cleanupAllPdfViewers() {}

// 在原生平台，我们使用 SfPdfViewer.memory。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  print('Building native PDF viewer with viewId: $viewId');
  // 使用Key确保每次都创建新的实例
  return SfPdfViewer.memory(
    pdfBytes,
    key: ValueKey('$viewId-${pdfBytes.hashCode}'),
  );
}
