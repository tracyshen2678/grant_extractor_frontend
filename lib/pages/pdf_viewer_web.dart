import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

// 存储当前显示的PDF数据，用于比较
Uint8List? _currentPdfBytes;
String? _currentViewId;
html.IFrameElement? _currentIframe;

// 直接创建并管理iframe，不使用platformViewRegistry
Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  print('Building PDF viewer with viewId: $viewId');
  print('PDF bytes length: ${pdfBytes.length}');
  
  // 检查是否是相同的PDF
  if (_currentPdfBytes != null && 
      _currentPdfBytes!.length == pdfBytes.length &&
      _currentViewId == viewId) {
    bool isSame = true;
    for (int i = 0; i < pdfBytes.length; i++) {
      if (_currentPdfBytes![i] != pdfBytes[i]) {
        isSame = false;
        break;
      }
    }
    if (isSame) {
      print('Same PDF detected, reusing existing viewer');
      return _buildExistingViewer();
    }
  }
  
  print('New PDF detected, creating new viewer');
  return _buildNewViewer(viewId, pdfBytes);
}

Widget _buildNewViewer(String viewId, Uint8List pdfBytes) {
  // 清理旧的iframe
  _cleanup();
  
  // 创建新的唯一viewType
  final uniqueViewType = 'pdf-viewer-${DateTime.now().microsecondsSinceEpoch}';
  
  try {
    ui_web.platformViewRegistry.registerViewFactory(uniqueViewType, (int factoryViewId) {
      // 清理旧的iframe（如果存在）
      _cleanup();
      
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      _currentIframe = html.IFrameElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.display = 'block';
      
      print('Created new iframe with URL: $url');
      
      // 添加加载事件监听
      _currentIframe!.onLoad.listen((_) {
        print('PDF loaded successfully in iframe');
      });
      
      // 添加错误事件监听
      _currentIframe!.onError.listen((_) {
        print('Error loading PDF in iframe');
      });
      
      return _currentIframe!;
    });
    
    // 更新当前状态
    _currentPdfBytes = Uint8List.fromList(pdfBytes);
    _currentViewId = viewId;
    
    print('Successfully registered new viewer with type: $uniqueViewType');
    
    return HtmlElementView(
      viewType: uniqueViewType,
      key: ValueKey(uniqueViewType),
    );
  } catch (e) {
    print('Error creating PDF viewer: $e');
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading PDF: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 强制重新创建
                _cleanup();
                _currentPdfBytes = null;
                _currentViewId = null;
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildExistingViewer() {
  if (_currentIframe != null) {
    // 即使是相同的PDF，我们也重新创建URL以确保刷新
    final blob = html.Blob([_currentPdfBytes!], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    _currentIframe!.src = url;
    print('Refreshed existing iframe with new URL: $url');
  }
  
  final uniqueViewType = 'pdf-viewer-${DateTime.now().microsecondsSinceEpoch}';
  
  ui_web.platformViewRegistry.registerViewFactory(uniqueViewType, (int factoryViewId) {
    return _currentIframe ?? html.DivElement()..text = 'No PDF loaded';
  });
  
  return HtmlElementView(
    viewType: uniqueViewType,
    key: ValueKey(uniqueViewType),
  );
}

void _cleanup() {
  if (_currentIframe != null) {
    try {
      // 清理iframe的URL
      final currentSrc = _currentIframe!.src;
      if (currentSrc != null && currentSrc.startsWith('blob:')) {
        html.Url.revokeObjectUrl(currentSrc);
        print('Cleaned up blob URL: $currentSrc');
      }
      
      // 移除iframe
      _currentIframe!.remove();
      _currentIframe = null;
      print('Cleaned up iframe');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}

// 这些函数保持为空以保持API兼容性
void registerPlatformView(String viewId, Uint8List pdfBytes) {
  // Web平台现在在buildPdfViewer中直接处理注册
}

void unregisterPlatformView(String viewId) {
  _cleanup();
}

void cleanupAllPdfViewers() {
  _cleanup();
  _currentPdfBytes = null;
  _currentViewId = null;
}
