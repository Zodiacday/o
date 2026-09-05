import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../models/session_item.dart';
import '../models/preview_connection.dart';
import '../services/history_service.dart';
import '../services/native_camera_service.dart';
import '../widgets/floating_navbar.dart';
import '../widgets/manual_url_modal.dart';
import '../widgets/rename_dialog.dart';
import 'app_viewer_screen.dart';
import 'settings_screen.dart';
import 'tabs/history_tab.dart';
import 'tabs/presets_tab.dart';
import 'tabs/scans_tab.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  List<SessionItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openScanner() async {
    final connection = await NativeCameraService.scanWithNativeCamera(context);

    if (connection != null && mounted) {
      _launchApp(connection.url, title: connection.projectName);
    }
  }

  Future<void> _launchApp(String url, {String? title}) async {
    await HistoryService.saveSession(url, title: title);
    await _loadHistory();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppViewerScreen(url: url, title: title),
      ),
    );

    _loadHistory();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    final connection = PreviewConnection.tryParse(text ?? '');
    if (connection != null) {
      HapticFeedback.mediumImpact();
      _launchApp(connection.url, title: connection.projectName);
    } else {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.flat,
          title: Text(
            text != null && text.isNotEmpty
                ? 'Invalid Web URL'
                : 'Clipboard is Empty',
          ),
          description: Text(
            text != null && text.isNotEmpty
                ? 'Clipboard does not contain a valid http/https link'
                : 'Copy a URL from your terminal or browser first',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
        );
      }
    }
  }

  void _showManualUrlModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManualUrlModal(onConnect: _launchApp),
    );
  }

  void _showRenameDialog(SessionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => RenameDialog(
        item: item,
        onSaved: (newName) async {
          await HistoryService.updateTitle(item.id, newName);
          _loadHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Pure Dark Background (Zero Glow)

          // 2. Main Screen Layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header: Left-aligned PreviewPort mark
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/previewport-logo-transparent.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Preview',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Port',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00E5FF),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'LIVE FLUTTER PREVIEW',
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Content Stack
                Expanded(
                  child: IndexedStack(
                    index: _currentNavIndex,
                    children: [
                      ScansTab(
                        history: _history,
                        isLoading: _isLoading,
                        onOpenScanner: _openScanner,
                        onLaunchApp: _launchApp,
                        onLongPressItem: _showRenameDialog,
                      ),
                      HistoryTab(
                        history: _history,
                        onLaunchApp: _launchApp,
                        onLongPressItem: _showRenameDialog,
                      ),
                      PresetsTab(
                        onPasteClipboard: _pasteFromClipboard,
                        onOpenManualModal: _showManualUrlModal,
                      ),
                      const SettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Frosted Capsule Bottom Navigation Bar (Centered Compact Capsule)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FloatingNavBar(
                  currentIndex: _currentNavIndex,
                  onTabSelected: (index) =>
                      setState(() => _currentNavIndex = index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
