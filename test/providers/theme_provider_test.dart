import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/providers/theme_provider.dart';
Future<ThemeProvider> _b() async { final p=ThemeProvider(); await Future.delayed(const Duration(milliseconds:50)); return p; }
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('THEME-01: default is system', () async => expect((await _b()).choice, AppThemeChoice.system));
  test('THEME-02: default label System default', () async => expect((await _b()).label, 'System default'));
  test('THEME-04: soothing label', () async { final p=await _b(); await p.setChoice(AppThemeChoice.soothing); expect(p.choice,AppThemeChoice.soothing); expect(p.label,'Soothing'); });
  test('THEME-05: vibrantDark label', () async { final p=await _b(); await p.setChoice(AppThemeChoice.vibrantDark); expect(p.choice,AppThemeChoice.vibrantDark); expect(p.label,'Vibrant Dark'); });
  test('THEME-06: back to system', () async { final p=await _b(); await p.setChoice(AppThemeChoice.soothing); await p.setChoice(AppThemeChoice.system); expect(p.label,'System default'); });
  test('THEME-07: setChoice notifies', () async { final p=await _b(); int n=0; p.addListener(()=>n++); await p.setChoice(AppThemeChoice.soothing); expect(n,greaterThan(0)); });
  test('THEME-08: all labels valid', () async { final p=await _b(); await p.setChoice(AppThemeChoice.soothing); expect(p.label,'Soothing'); await p.setChoice(AppThemeChoice.vibrantDark); expect(p.label,'Vibrant Dark'); await p.setChoice(AppThemeChoice.system); expect(p.label,'System default'); });
  test('THEME-09: idempotent double setChoice', () async { final p=await _b(); await p.setChoice(AppThemeChoice.vibrantDark); await p.setChoice(AppThemeChoice.vibrantDark); expect(p.choice,AppThemeChoice.vibrantDark); });
  test('THEME-10: vibrantDark persists', () async { final p=await _b(); await p.setChoice(AppThemeChoice.vibrantDark); await Future.delayed(const Duration(milliseconds:50)); expect((await _b()).choice,AppThemeChoice.vibrantDark); });
  test('THEME-11: soothing persists', () async { final p=await _b(); await p.setChoice(AppThemeChoice.soothing); await Future.delayed(const Duration(milliseconds:50)); expect((await _b()).choice,AppThemeChoice.soothing); });
}
