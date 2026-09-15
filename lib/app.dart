import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/locale_provider.dart';
import 'package:snooker_club/core/routes/app_router.dart';
import 'package:snooker_club/core/theme/app_theme.dart';
import 'package:snooker_club/l10n/app_localizations.dart';

/// Root application widget.
class SnookerClubApp extends ConsumerWidget {
  const SnookerClubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final clubAsync = ref.watch(clubProfileProvider);

    final clubName = clubAsync.value?.clubName ?? 'S&B Manager';
    final appTitle = AppConfig.isPreview ? '[PREVIEW] $clubName' : clubName;

    Widget app = MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppConfig.isPreview ? AppTheme.previewLight : AppTheme.light,
      darkTheme: AppConfig.isPreview ? AppTheme.previewDark : AppTheme.dark,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        
        // Fix stretching of screens in desktop mode
        final isDesktop = MediaQuery.sizeOf(context).width > 800;
        if (isDesktop) {
          content = Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400), // using 1400 so Dashboard still looks good
                child: ClipRect(child: content),
              ),
            ),
          );
        }

        if (AppConfig.isPreview) {
          return Banner(
            message: 'PREVIEW',
            location: BannerLocation.topEnd,
            color: Colors.deepOrange,
            child: content,
          );
        }
        return content;
      },
    );

    return app;
  }
}
