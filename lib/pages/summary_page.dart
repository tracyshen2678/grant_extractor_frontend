import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
// 只在原生平台导入 dart:io
import 'dart:io' if (dart.library.html) 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 这是最关键的条件导入！
// 它会根据平台自动选择加载哪个文件。
import 'pdf_viewer_stub.dart'
    if (dart.library.io) 'pdf_viewer_native.dart'
    if (dart.library.html) 'pdf_viewer_web.dart';

class SummaryPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String pdfName;

  const SummaryPage({super.key, required this.pdfBytes, required this.pdfName});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String synopsis = '';
  List<String> keywords = [];
  Map<String, dynamic> extractedData = {};
  double score = 50;
  double stars = 3;
  String comments = '';
  bool _isLoading = true;
  int selectedIndex = 0;

  final String _viewId = 'pdf-viewer-iframe';

  @override
  void initState() {
    super.initState();
    // 调用来自条件导入的函数。
    // 在 Web 平台，它会执行注册；在原生平台，它是一个空函数。
    registerPlatformView(_viewId, widget.pdfBytes);
    _uploadAndParsePDF();
  }

  String _getBaseUrl() {
    return 'https://grant-extractor-api.onrender.com'; // 确保这是唯一返回值（临时测试用）
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('review_history');
    _showMessage('Review history cleared!');
  }

  Future<void> _uploadAndParsePDF() async {
    print('=== Debugging Info ===');
    print('Connecting to: ${_getBaseUrl()}/api/v1/extract/');
    print('PDF file name: ${widget.pdfName}');
    print('PDF file size: ${widget.pdfBytes.length} bytes');

    try {
      // 1. 从本地获取 JWT Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // 假设token存储在'shared_preferences'中

      if (token == null) {
        _showError('请先登录');
        return;
      }

      final baseUrl = _getBaseUrl();
      final fullUrl = '$baseUrl/api/v1/extract/';
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      // 2. 添加Authorization Header
      request.headers['Authorization'] = 'Bearer $token';

      // 3. 添加PDF文件
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          widget.pdfBytes,
          filename: widget.pdfName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 120),
      );

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(resBody);
        setState(() {
          synopsis = jsonData['synopsis'] ?? '';
          keywords = List<String>.from(jsonData['keywords'] ?? []);
          extractedData = jsonData['extracted_data'] ?? {};
        });
      } else {
        final errorBody = await response.stream.bytesToString();
        _showError('解析失败: ${response.statusCode}\n$errorBody');
      }
    } on TimeoutException catch (e) {
      _showError('连接超时: 请检查网络连接');
    } catch (e) {
      _showError('发生错误。请检查网络连接后重试。\n详情: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Application Summary Preview"),
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 600)
            Container(
              width: 200,
              color: Colors.grey[100],
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.summarize),
                    title: const Text('Summary'),
                    selected: selectedIndex == 0,
                    onTap: () => setState(() => selectedIndex = 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.checklist),
                    title: const Text('Criteria'),
                    selected: selectedIndex == 1,
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    // 调用来自条件导入的函数来构建 Widget
                    child: buildPdfViewer(_viewId, widget.pdfBytes),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child:
                      selectedIndex == 0
                          ? _buildDetailedSummary()
                          : const Center(
                            child: Text("Criteria Page (Coming Soon)"),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- All the _build* and helper methods below are unchanged ---

  Widget _buildDetailedSummary() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("Synopsis"),
        _buildSectionContent(synopsis),
        const SizedBox(height: 16),
        _buildSectionTitle("Keywords"),
        if (_isLoading)
          const Text(
            "Analyzing...",
            style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
          )
        else
          Wrap(
            spacing: 6,
            children: keywords.map((k) => Chip(label: Text(k))).toList(),
          ),
        const SizedBox(height: 16),
        _buildSectionTitle("Applicant Information"),
        _buildInfoRow("Name", extractedData['applicant_name']),
        _buildInfoRow("Applicant Type", extractedData['applicant_type']),
        _buildInfoRow(
          "Requested Amount",
          extractedData['requested_amount'] != null
              ? "€${extractedData['requested_amount']}"
              : null,
        ),
        _buildInfoRow("Work Basis", extractedData['work_basis']),
        const SizedBox(height: 16),
        _buildSectionTitle("Project Details"),
        _buildInfoRow("Project Duration", extractedData['project_duration']),
        _buildInfoRow(
          "Start Date",
          _formatDate(extractedData['project_start_date']),
        ),
        _buildInfoRow(
          "End Date",
          _formatDate(extractedData['project_end_date']),
        ),
        _buildInfoRow("Artistic Field", extractedData['main_artistic_field']),
        _buildInfoRow("Main Goal/Output", extractedData['main_goal_or_output']),
        _buildInfoRow("Location", extractedData['location']),
        _buildInfoRow("Target Audience", extractedData['target_audience']),
        _buildInfoRow("Workspace", extractedData['workspace']),
        const SizedBox(height: 16),
        _buildSectionTitle("Community Engagement"),
        _buildListSection(
          "Engagement Methods",
          extractedData['community_engagement_methods'],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle("Funding & Partners"),
        _buildCoFundingSection(),
        _buildListSection("Partners", extractedData['partners']),
        const SizedBox(height: 16),
        _buildSectionTitle("Supporting Documents"),
        _buildSupportingDocuments(),
        const SizedBox(height: 16),
        _buildSectionTitle("Reviewer Assessment"),
        TextField(
          maxLines: 3,
          onChanged: (val) => comments = val,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Comments",
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle("Score"),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            "Score for AI's extraction accuracy against the source document.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Slider(
          value: score,
          min: 0,
          max: 100,
          divisions: 100,
          label: score.toInt().toString(),
          onChanged: (value) => setState(() => score = value),
        ),
        const SizedBox(height: 8),
        _buildSectionTitle("Stars"),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            "Star rating for the app's user experience.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        RatingBar.builder(
          initialRating: stars,
          minRating: 1,
          maxRating: 5,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemBuilder:
              (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) => stars = rating,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saveReview,
              child: const Text("Save Review"),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _showHistory,
              child: const Text("View History"),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _clearHistory,
              child: const Text(
                "Clear History",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    if (_isLoading) {
      return const Text(
        "Analyzing...",
        style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
      );
    }
    return Text(
      content.isEmpty ? "No data available" : content,
      style: TextStyle(color: content.isEmpty ? Colors.grey : null),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    Widget valueWidget;
    if (_isLoading) {
      valueWidget = const Text(
        "Analyzing...",
        style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
      );
    } else {
      valueWidget = Text(
        value?.toString() ?? "No data available",
        style: TextStyle(color: value == null ? Colors.grey : null),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic>? items) {
    Widget content;
    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          "Analyzing...",
          style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
        ),
      );
    } else if (items != null && items.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• "),
                        Expanded(child: Text(item.toString())),
                      ],
                    ),
                  ),
                )
                .toList(),
      );
    } else {
      content = const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text("No data available", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title:", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  Widget _buildCoFundingSection() {
    if (_isLoading) {
      return _buildInfoRow("Co-funding", null);
    }

    final coFunding = extractedData['co_funding'];
    if (coFunding == null) {
      return _buildInfoRow("Co-funding", null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Co-funding:",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Amount: €${coFunding['total_amount'] ?? 'Unknown'}"),
              const SizedBox(height: 4),
              const Text(
                "Funding Sources:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (coFunding['sources'] != null)
                ...coFunding['sources'].map<Widget>(
                  (source) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text("• ${source['source']}: €${source['amount']}"),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportingDocuments() {
    if (_isLoading) {
      return _buildInfoRow("Supporting Docs", null);
    }

    final docs = extractedData['supporting_documents'];
    if (docs == null) {
      return const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Text("No data available", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocumentStatus("CV", docs['cv_attached']),
        _buildDocumentStatus("Portfolio", docs['portfolio_provided']),
        if (docs['portfolio_url'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
            child: Text("Portfolio Link: ${docs['portfolio_url']}"),
          ),
        _buildDocumentStatus(
          "Letters of Intent",
          docs['letters_of_intent_attached'],
        ),
        _buildDocumentStatus(
          "Partner Agreements",
          docs['partner_agreements_attached'],
        ),
      ],
    );
  }

  Widget _buildDocumentStatus(String name, bool? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        "$name: ${status == true ? 'Provided' : 'Not Provided'}",
        style: TextStyle(
          color:
              status == true
                  ? Colors.green
                  : const Color.fromARGB(255, 215, 25, 11),
        ),
      ),
    );
  }

  String _formatDate(Map<String, dynamic>? dateMap) {
    if (_isLoading) return "Analyzing...";
    if (dateMap == null) return "No data available";
    return "${dateMap['month']}/${dateMap['year']}";
  }

  Future<void> _saveReview() async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'applicant_name': extractedData['applicant_name'] ?? 'Unknown Applicant',
      'synopsis': synopsis,
      'keywords': keywords,
      'extracted_data': extractedData,
      'score': score,
      'stars': stars,
      'comments': comments,
      'time': DateTime.now().toIso8601String(),
    };
    final history = prefs.getStringList('review_history') ?? [];
    history.add(jsonEncode(entry));
    await prefs.setStringList('review_history', history);
    _showMessage('Review and comments saved');
  }

  void _showHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('review_history') ?? [];
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Review History'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = jsonDecode(history[index]);
                  final time = DateTime.parse(item['time']);
                  final mainGoal =
                      item['extracted_data']?['main_goal_or_output'] as String?;

                  return Card(
                    child: ListTile(
                      title: Text(
                        item['applicant_name'] ?? 'Unknown Applicant',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mainGoal != null && mainGoal.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                bottom: 2.0,
                              ),
                              child: Text(
                                'Project: $mainGoal',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text('⭐ ${item['stars']} Score: ${item['score']}'),
                          if (item['comments'] != null &&
                              item['comments'].isNotEmpty)
                            Text('Comments: ${item['comments']}'),
                          Text(
                            'Time: ${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
