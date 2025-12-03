import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'widgets/window/mini_window.dart';
import 'providers/window_provider.dart';
import 'utils/theme.dart';

/// 应用根Widget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowStateProvider);
    final unreadCount = ref.watch(unreadBadgeCountProvider);

    return MaterialApp(
      title: '芯服务',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: windowState.mode == WindowMode.mini
          ? MiniWindow(
              unreadCount: unreadCount,
              onDoubleTap: () {
                ref.read(windowStateProvider.notifier).switchToNormalMode();
              },
            )
          : const HomeScreen(),
    );
  }
}
