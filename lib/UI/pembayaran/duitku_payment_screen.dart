import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DuitkuPaymentScreen extends StatefulWidget {
  final String paymentUrl;

  const DuitkuPaymentScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<DuitkuPaymentScreen> createState() => _DuitkuPaymentScreenState();
}

class _DuitkuPaymentScreenState extends State<DuitkuPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onWebResourceError: (WebResourceError error) {
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://bantuin.app/payment-return')) {
              Navigator.of(context).pop('success'); 
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF192F65),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}