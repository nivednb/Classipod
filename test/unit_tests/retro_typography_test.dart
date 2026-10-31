import 'package:classipod/core/theme/ipod_typography.dart';
import 'package:classipod/features/settings/models/app_theme.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('retro font applies only to the first-generation theme', (
    tester,
  ) async {
    TextStyle? rendered;
    Future<void> showTheme(AppTheme theme) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: theme.toCupertinoTheme(),
          home: Builder(
            builder: (context) {
              rendered = IpodTypography.forContext(
                context,
                IpodTypography.menu,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    }

    await showTheme(AppTheme.firstGeneration);
    expect(rendered?.fontFamily, 'PixelifySans');
    expect(rendered?.fontFamilyFallback, contains('Helvetica'));
    await showTheme(AppTheme.dark);
    expect(rendered?.fontFamily, 'Helvetica');
  });
}
