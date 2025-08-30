import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

// 简化的实现：不使用platformViewRegistry，直接显示PDF信息和下载链接
void registerPlatformView(String viewId, Uint8List pdfBytes) {
  // 空实现
}

void unregisterPlatformView(String viewId) {
  // 空实现
}

void cleanupAllPdfViewers() {
  // 空实现
}

Widget buildPdfViewer(String viewId, Uint8List pdfBytes) {
  print('=== Building Simple PDF Viewer ===');
  print('ViewId: $viewId');
  print('PDF size: ${pdfBytes.length} bytes');
  
  return Container(
    key: ValueKey('simple-pdf-${pdfBytes.hashCode}'),
    color: Colors.grey[100],
    child: Column(
      children: [
        // PDF信息头部
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'PDF Document',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Size: ${_formatBytes(pdfBytes.length)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        
        // 操作按钮
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PDF Viewer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The PDF has been processed for analysis.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: () => _downloadPdf(pdfBytes, viewId),
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: () => _openPdfInNewTab(pdfBytes),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in New Tab'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'PDF uploaded and ready for analysis',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

void _downloadPdf(Uint8List pdfBytes, String fileName) {
  try {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf'
      ..style.display = 'none';
    
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    
    html.Url.revokeObjectUrl(url);
    
    print('PDF download initiated');
  } catch (e) {
    print('Error downloading PDF: $e');
  }
}

void _openPdfInNewTab(Uint8List pdfBytes) {
  try {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.window.open(url, '_blank');
    
    // 延迟清理URL
    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
    
    print('PDF opened in new tab');
  } catch (e) {
    print('Error opening PDF: $e');
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
