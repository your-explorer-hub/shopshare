import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/providers/notification_provider.dart';
Future<NotificationProvider> _b() async {
  final p = NotificationProvider();
  await Future.delayed(const Duration(milliseconds: 50));
  return p;
}
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('NOTIF-01', () async => expect((await _b()).isMuted, isFalse));
  test('NOTIF-02', () async => expect((await _b()).statusLabel, 'Always allow'));
  test('NOTIF-03', () async => expect((await _b()).muteUntil, isNull));
  test('NOTIF-04', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); expect(p.isMuted,isTrue); });
  test('NOTIF-05', () async { final b=DateTime.now(); final p=await _b(); p.muteFor(const Duration(hours:8)); expect(p.muteUntil!.isAfter(b),isTrue); });
  test('NOTIF-06', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); expect(p.statusLabel,contains('h')); });
  test('NOTIF-07', () async { final p=await _b(); p.muteFor(const Duration(days:2)); expect(p.statusLabel,contains('d')); });
  test('NOTIF-08', () async { final p=await _b(); int n=0; p.addListener(()=>n++); p.muteFor(const Duration(hours:1)); expect(n,greaterThan(0)); });
  test('NOTIF-09', () async { final p=await _b(); p.muteForDays(1); expect(p.isMuted,isTrue); });
  test('NOTIF-10', () async { final p=await _b(); p.muteForDays(3); expect(p.statusLabel,contains('d')); });
  test('NOTIF-11', () async { final p=await _b(); int n=0; p.addListener(()=>n++); p.muteForDays(2); expect(n,greaterThan(0)); });
  test('NOTIF-12', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); p.setAlwaysAllow(); expect(p.isMuted,isFalse); });
  test('NOTIF-13', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); p.setAlwaysAllow(); expect(p.muteUntil,isNull); });
  test('NOTIF-14', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); p.setAlwaysAllow(); expect(p.statusLabel,'Always allow'); });
  test('NOTIF-15', () async { final p=await _b(); p.muteFor(const Duration(hours:8)); int n=0; p.addListener(()=>n++); p.setAlwaysAllow(); expect(n,greaterThan(0)); });
  test('NOTIF-16', () async { final p=await _b(); p.muteFor(const Duration(milliseconds:-1)); expect(p.isMuted,isFalse); });
  test('NOTIF-17', () async { final p=await _b(); p.muteFor(const Duration(milliseconds:-1)); await Future.delayed(const Duration(milliseconds:50)); expect(p.statusLabel,'Always allow'); });
  test('NOTIF-18', () async { (await _b()).muteForDays(1); await Future.delayed(const Duration(milliseconds:100)); expect((await _b()).isMuted,isTrue); });
  test('NOTIF-19', () async { final p=await _b(); p.muteForDays(1); await Future.delayed(const Duration(milliseconds:50)); p.setAlwaysAllow(); await Future.delayed(const Duration(milliseconds:100)); expect((await _b()).isMuted,isFalse); });
}
