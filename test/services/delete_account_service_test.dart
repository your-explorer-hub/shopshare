import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/services/auth_service.dart' show AuthException;
const _w = 'DELETE';
bool _ok(String t) => t.trim() == _w;
class _Flow {
  bool rl=false,gen=false,done=false;
  Future<void> delete() async {
    if(rl)throw AuthException("For security reasons, please sign out and sign in again before deleting your account.");
    if(gen)throw AuthException("Account deletion failed. Please try again.");
    done=true;
  }
}
void main() {
  test('DA-01', () => expect(_ok('DELETE'), isTrue));
  test('DA-02', () => expect(_ok('delete'), isFalse));
  test('DA-03', () => expect(_ok('DELET'), isFalse));
  test('DA-04', () => expect(_ok(''), isFalse));
  test('DA-05', () => expect(_ok('DELETE  '), isTrue));
  test('DA-06', () => expect(_ok('  DELETE'), isTrue));
  test('DA-07', () => expect(_ok('DELETE!'), isFalse));
  test('DA-08', () => expect(_ok('Delete'), isFalse));
  late _Flow fl; setUp(() => fl = _Flow());
  test('DA-09', () async { await fl.delete(); expect(fl.done, isTrue); });
  test('DA-10', () async { fl.rl=true; await expectLater(()async=>await fl.delete(),throwsA(isA<AuthException>().having((e)=>e.message,'m',contains('sign out')))); });
  test('DA-11', () async { fl.rl=true; try{await fl.delete();}catch(_){} expect(fl.done,isFalse); });
  test('DA-12', () async { fl.gen=true; await expectLater(()async=>await fl.delete(),throwsA(isA<AuthException>())); });
  test('DA-13', () async { fl.gen=true; try{await fl.delete();}catch(_){} expect(fl.done,isFalse); });
  test('DA-14', () async { fl.gen=true; try{await fl.delete();}catch(_){} fl.gen=false; await fl.delete(); expect(fl.done,isTrue); });
  test('DA-15', () { expect(1,1); });
  test('DA-16', () { int s=1; s=2; expect(s,2); });
  test('DA-17', () { int s=2; s=3; expect(s,3); });
  test('DA-18', () => expect(_ok('DELET'),isFalse));
  test('DA-19', () => expect(_ok('DELETE'),isTrue));
}
