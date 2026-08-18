import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bottom sheet that runs a Cloudflare Turnstile challenge inside a WebView.
/// Pops with the token string on success, or null if the user cancels.
class TurnstileSheet extends StatefulWidget {
  const TurnstileSheet({super.key});

  @override
  State<TurnstileSheet> createState() => _TurnstileSheetState();
}

class _TurnstileSheetState extends State<TurnstileSheet> {
  InAppWebViewController? _webViewController;
  bool _pageReady = false;
  bool _error = false;
  bool _tokenReceived = false;

  static String _buildHtml(String siteKey) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      background: #ffffff;
    }
  </style>
</head>
<body>
  <div
    class="cf-turnstile"
    data-sitekey="$siteKey"
    data-callback="onTurnstileSuccess"
    data-theme="light"
    data-size="normal">
  </div>
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
  <script>
    function onTurnstileSuccess(token) {
      window.flutter_inappwebview.callHandler('TurnstileToken', token);
    }
  </script>
</body>
</html>
''';

  void _retry() {
    setState(() {
      _pageReady = false;
      _error = false;
      _tokenReceived = false;
    });
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Column(
                children: [
                  const Text(
                    'Security check',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One quick verification before we create your account.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      'Could not load the security check.\nPlease check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    InAppWebView(
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        allowsInlineMediaPlayback: true,
                        transparentBackground: false,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                        controller.addJavaScriptHandler(
                          handlerName: 'TurnstileToken',
                          callback: (args) {
                            if (_tokenReceived) return;
                            _tokenReceived = true;
                            final token = args.isNotEmpty
                                ? args[0].toString().trim()
                                : '';
                            if (token.isNotEmpty && mounted) {
                              Navigator.of(context).pop(token);
                            }
                          },
                        );
                        controller.loadData(
                          data: _buildHtml(AppConstants.turnstileSiteKey),
                          mimeType: 'text/html',
                          encoding: 'utf-8',
                          baseUrl: WebUri(AppConstants.turnstileBaseUrl),
                          historyUrl: WebUri(AppConstants.turnstileBaseUrl),
                        );
                      },
                      onLoadStop: (controller, url) {
                        if (mounted) setState(() => _pageReady = true);
                      },
                      onReceivedError: (controller, request, error) {
                        // Only treat main-frame failures as fatal.
                        // Sub-resource errors (Cloudflare challenge sub-requests,
                        // favicon 404s, etc.) are expected and non-blocking.
                        if ((request.isForMainFrame ?? false) && mounted) {
                          setState(() => _error = true);
                        }
                      },
                    ),
                    if (!_pageReady)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
