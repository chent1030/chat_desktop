import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart'
    show windowManager, TitleBarStyle;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'services/config_service.dart';
import 'utils/app_fonts.dart';

// 悬浮窗入口
Future<void> miniWindowMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 读取字体配置（不影响悬浮窗启动，失败则用默认字体）
  try {
    await ConfigService.instance.initialize();
    _miniWindowFontFamily = AppFonts.familyForKey(
      ConfigService.instance.fontKey,
    );
  } catch (_) {}

  // 注册窗口间消息
  DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
    if (call.method == 'update_unread_count') {
      unreadCountController.add(call.arguments as int);
    } else if (call.method == 'update_unread_tasks') {
      final raw = call.arguments as List;
      final tasks = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      unreadTasksController.add(tasks);
    }
  });

  runApp(const MiniWindowApp());

  // Windows 子窗口：尽量设置为无边框、透明、置顶并隐藏任务栏
  if (Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
      await Window.initialize();
      await Window.setEffect(effect: WindowEffect.transparent);
    } catch (_) {}
    try {
      // 延迟以确保子窗口句柄可用
      await Future.delayed(const Duration(milliseconds: 80));
      await windowManager.setAsFrameless();
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setResizable(false);
      await windowManager.setHasShadow(false);
    } catch (_) {}

    // 使用 bitsdojo_window 进一步确保无边框并配置初始尺寸/显示
    try {
      doWhenWindowReady(() {
        const initialSize = Size(120, 120);
        appWindow.minSize = initialSize;
        appWindow.size = initialSize;
        appWindow.alignment = Alignment.center;
        appWindow.show();
      });
    } catch (_) {}

    // 再次尝试数次，确保系统栏被移除（在某些机器上首次调用不生效）
    int tries = 0;
    Timer.periodic(const Duration(milliseconds: 180), (t) async {
      tries++;
      try {
        await windowManager.setAsFrameless();
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
            windowButtonVisibility: false);
        await windowManager.setHasShadow(false);
        await windowManager.setResizable(false);
      } catch (_) {}
      if (tries >= 10) t.cancel();
    });
  }
}

// 跨 Widget 的数据流
final unreadCountController = StreamController<int>.broadcast();
final unreadTasksController =
    StreamController<List<Map<String, dynamic>>>.broadcast();

String? _miniWindowFontFamily;

class MiniWindowApp extends StatelessWidget {
  const MiniWindowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: Platform.isWindows ? _miniWindowFontFamily : null,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          surface: Colors.transparent,
          background: Colors.transparent,
        ),
      ),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: MiniWindowHome(),
      ),
    );
  }
}

class MiniWindowHome extends StatefulWidget {
  const MiniWindowHome({super.key});
  @override
  State<MiniWindowHome> createState() => _MiniWindowHomeState();
}

class _MiniWindowHomeState extends State<MiniWindowHome> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _unreadTasks = [];
  bool _isHovering = false;

  final Size _baseSize = const Size(120, 120);
  final double _bubbleWidth = 280;
  bool _expanded = false;
  Timer? _resizeDebounce;
  Timer? _hoverTimer;

  StreamSubscription? _cSub;
  StreamSubscription? _tSub;

  @override
  void initState() {
    super.initState();
    _cSub = unreadCountController.stream
        .listen((v) => setState(() => _unreadCount = v));
    _tSub = unreadTasksController.stream
        .listen((v) => setState(() => _unreadTasks = v));
  }

  @override
  void dispose() {
    _cSub?.cancel();
    _tSub?.cancel();
    _resizeDebounce?.cancel();
    _hoverTimer?.cancel();
    super.dispose();
  }

  Future<void> _resizeForHover(bool expand) async {
    if (!Platform.isWindows) return;
    if (_expanded == expand) return;
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 80), () async {
      try {
        final pos = await windowManager.getPosition();
        final newSize = expand
            ? Size(_baseSize.width + 10 + _bubbleWidth, _baseSize.height)
            : _baseSize;
        await windowManager.setSize(newSize);
        await windowManager.setPosition(pos);
        if (mounted) setState(() => _expanded = expand);
      } catch (_) {}
    });
  }

  Future<void> _onDoubleTap() async {
    await DesktopMultiWindow.invokeMethod(0, 'restore_main_window');
  }

  @override
  Widget build(BuildContext context) {
    final lottieAsset =
        _unreadCount > 0 ? 'dynamic_logo.gif' : 'unread_logo.gif';
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        onEnter: (_) {
          _hoverTimer?.cancel();
          _hoverTimer = Timer(const Duration(milliseconds: 120), () {
            if (mounted) {
              setState(() => _isHovering = true);
              if (_unreadTasks.isNotEmpty) _resizeForHover(true);
            }
          });
        },
        onExit: (_) {
          _hoverTimer?.cancel();
          _hoverTimer = Timer(const Duration(milliseconds: 160), () {
            if (mounted) {
              setState(() => _isHovering = false);
              _resizeForHover(false);
            }
          });
        },
        child: Platform.isWindows
            ? WindowTitleBarBox(
                child: MoveWindow(
                  child: Stack(
                      clipBehavior: Clip.none,
                      children: _stackChildren(lottieAsset)),
                ),
              )
            : Stack(
                clipBehavior: Clip.none, children: _stackChildren(lottieAsset)),
      ),
    );
  }

  List<Widget> _stackChildren(String lottieAsset) {
    final anim = SizedBox(
      width: 120,
      height: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: _onDoubleTap,
        child: Center(
          child: ClipOval(
            child: Image.asset(
              lottieAsset,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );

    // 拖拽由上层 WindowTitleBarBox/MoveWindow 控制，这里直接返回动画组件
    final animDraggable = anim;

    final bubble = Positioned(
      left: 130,
      top: 0,
      child: AnimatedOpacity(
        opacity: _isHovering ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _isHovering ? 1.0 : 0.96,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                constraints:
                    BoxConstraints(maxWidth: _bubbleWidth, maxHeight: 400),
                // 全透明背景，仅保留高斯模糊以提升可读性
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '未读待办 (' + _unreadCount.toString() + ')',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, color: Color.fromARGB(60, 255, 255, 255)),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount:
                            _unreadTasks.length > 5 ? 5 : _unreadTasks.length,
                        separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color.fromARGB(40, 255, 255, 255)),
                        itemBuilder: (context, index) {
                          final task = _unreadTasks[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            leading: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle)),
                            title: Text(task['title'] ?? '无标题',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            onTap: () async {
                              try {
                                await DesktopMultiWindow.invokeMethod(
                                    0, 'open_task', {
                                  'id': task['id']?.toString(),
                                });
                              } catch (_) {}
                            },
                            subtitle: task['description'] != null
                                ? Text(task['description'],
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)
                                : null,
                          );
                        },
                      ),
                    ),
                    if (_unreadTasks.length > 5)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                            child: Text('还有更多…',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white70))),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return [
      animDraggable,
      if (_isHovering && _unreadTasks.isNotEmpty) bubble,
    ];
  }
}
