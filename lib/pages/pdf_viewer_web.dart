import 'dart:typed_data';
import 'dart:html' as html;

// MODIFIED: 导入 dart:ui_web 而不是 dart:ui
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

// 存储已注册的视图ID，避免重复注册
final Set<String> _registeredViewIds = <String>{};

// 存储URL引用，用于清理
final Map<String, String> _urlReferences = <String, String>{};

// 在 Web 平台，我们注册一个 IFrame。
void registerPlatformView(String viewId, Uint8List pdfBytes) {
  // 如果已经注册过这个viewId，先清理
  if (_registeredViewIds.contains(viewId)) {
    print('ViewId $viewId already registered, skipping...');
    return;
  }

  try {
    // MODIFIED: 使用 ui_web.platformViewRegistry
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // 存储URL引用以便后续清理
      _urlReferences[viewId.toString()] = url;
      
      final iframe = html.IFrameElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
      
      print('Registered PDF viewer for viewId: $viewId with URL: $url');
      return iframe;
    });
    
    _registeredViewIds.add(viewId);
    print('Successfully registered viewId: $viewId');
  } catch (e) {
    print('Error registering viewId $viewId: $e');
  }
}

// 清理函数
void unregisterPlatformView(String viewId) {
  if (_registeredViewIds.contains(viewId)) {
    _registeredViewIds.remove(viewId);
    
    // 清理URL引用
    final url = _urlReferences.remove(viewId);
    if (url != null) {
      html.Url.revokeObjectUrl(url);
      print('Cleaned up URL for viewId: $viewId');
    }
    
    print('Unregistered viewId: $viewId');
  }
}

// 清理所有注册的视图
void cleanupAllPdfViewers() {
  for (final url in _urlReferences.values) {
    html.Url.revokeObjectUrl(url);
  }
  _urlReferences.clear();
  _registeredViewIds.clear();
  print('Cleaned up all PDF viewers');
}

// 在 Web 平台，我们使用 HtmlElementView 来显示这个 IFrame。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  print('Building PDF viewer with viewId: $viewId');
  return HtmlElementView(viewType: viewId);
}
