import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/features/settings/models/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first-generation theme restores by name and uses LCD colors', () {
    final theme = AppTheme.fromName('firstGeneration');
    expect(theme, AppTheme.firstGeneration);
    expect(
      theme.toCupertinoTheme().scaffoldBackgroundColor,
      AppPalette.firstGenerationBackground,
    );
    expect(
      theme.toCupertinoTheme().primaryColor,
      AppPalette.firstGenerationInk,
    );
  });

  test('older saved theme names remain valid', () {
    expect(AppTheme.fromName('light'), AppTheme.light);
    expect(AppTheme.fromName('dark'), AppTheme.dark);
  });
}
