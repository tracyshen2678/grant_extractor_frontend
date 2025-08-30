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
  print('Attempting to register viewId: $viewId');
  
  // 总是先清理可能存在的旧视图
  unregisterPlatformView(viewId);
  
  try {
    // MODIFIED: 使用 ui_web.platformViewRegistry
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int factoryViewId) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // 存储URL引用以便后续清理
      _urlReferences[viewId] = url;
      
      final iframe = html.IFrameElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.display = 'block'; // 确保显示
      
      print('Created iframe for viewId: $viewId with URL: $url');
      return iframe;
    });
    
    _registeredViewIds.add(viewId);
    print('Successfully registered viewId: $viewId');
  } catch (e) {
    print('Error registering viewId $viewId: $e');
    // 如果注册失败，可能是因为viewId已存在，尝试使用新的ID
    if (e.toString().contains('already registered')) {
      final newViewId = '${viewId}_retry_${DateTime.now().millisecondsSinceEpoch}';
      print('Retrying with new viewId: $newViewId');
      registerPlatformView(newViewId, pdfBytes);
    }
  }
}

// 清理函数
void unregisterPlatformView(String viewId) {
  if (_registeredViewIds.contains(viewId)) {
    _registeredViewIds.remove(viewId);
    print('Unregistered viewId: $viewId');
  }
  
  // 清理URL引用
  final url = _urlReferences.remove(viewId);
  if (url != null) {
    try {
      html.Url.revokeObjectUrl(url);
      print('Cleaned up URL for viewId: $viewId');
    } catch (e) {
      print('Error cleaning up URL: $e');
    }
  }
}

// 清理所有注册的视图
void cleanupAllPdfViewers() {
  for (final url in _urlReferences.values) {
    try {
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error cleaning up URL: $e');
    }
  }
  _urlReferences.clear();
  _registeredViewIds.clear();
  print('Cleaned up all PDF viewers');
}

// 在 Web 平台，我们使用 HtmlElementView 来显示这个 IFrame。
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  print('Building PDF viewer with viewId: $viewId');
  
  // 检查viewId是否已注册
  if (!_registeredViewIds.contains(viewId)) {
    print('ViewId $viewId not registered, registering now...');
    registerPlatformView(viewId, pdfBytes);
  }
  
  return HtmlElementView(
    viewType: viewId,
    key: ValueKey('html-view-$viewId'),
  );
}
