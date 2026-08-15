import 'package:flutter_test/flutter_test.dart';
class _E { final String uid, email, msg; _E(this.uid, this.email, this.msg); }
class _Repo {
  final _l = <_E>[]; bool fail = false;
  Future<void> submit(String uid, String email, String msg) async {
    if(fail)throw Exception("err"); if(uid.isEmpty)throw Exception("empty"); if(msg.isEmpty)throw Exception("empty msg");
    _l.add(_E(uid,email,msg));
  }
  int get count=>_l.length; List<_E> get entries=>List.unmodifiable(_l);
}
class _Form {
  final _Repo _r; bool ok=false,busy=false; String? err,suc; _Form(this._r);
  Future<void> submit(String uid,String email,String msg) async {
    final m=msg.trim(); if(m.isEmpty||uid.isEmpty)return;
    busy=true; err=null;
    try{ await _r.submit(uid,email,m); suc="Thank you! Your feedback has been submitted."; ok=true; }
    catch(_){ err="Failed to submit. Please try again."; }
    finally{ busy=false; }
  }
}
void main() {
  late _Repo r; late _Form fm;
  setUp(() { r = _Repo(); fm = _Form(r); });
  test('FB-01', () async { await r.submit('u1','e','Hi'); expect(r.count,1); expect(r.entries.first.msg,'Hi'); });
  test('FB-02', () async { await r.submit('uid-x','e','Hi'); expect(r.entries.first.uid,'uid-x'); });
  test('FB-03', () async { await r.submit('u1','em@e.com','Hi'); expect(r.entries.first.email,'em@e.com'); });
  test('FB-04', () async { await r.submit('u','e','1'); await r.submit('u','e','2'); expect(r.count,2); });
  test('FB-05', () async { r.fail=true; await expectLater(()async=>await r.submit('u','e','m'),throwsA(isA<Exception>())); });
  test('FB-06', () async { await expectLater(()async=>await r.submit('','e','m'),throwsA(isA<Exception>())); });
  test('FB-07', () async { await expectLater(()async=>await r.submit('u','e',''),throwsA(isA<Exception>())); });
  test('FB-08', () async { await fm.submit('u1','e','Nice'); expect(fm.ok,isTrue); });
  test('FB-09', () async { await fm.submit('u1','e','Works'); expect(fm.suc,contains('Thank you')); });
  test('FB-10', () async { await fm.submit('u1','e','   '); expect(fm.ok,isFalse); expect(r.count,0); });
  test('FB-11', () async { await fm.submit('','e','Hello'); expect(fm.ok,isFalse); });
  test('FB-12', () async { r.fail=true; await fm.submit('u1','e','T'); expect(fm.err,'Failed to submit. Please try again.'); });
  test('FB-13', () async { await fm.submit('u1','e','D'); expect(fm.busy,isFalse); });
  test('FB-14', () async { r.fail=true; await fm.submit('u1','e','F'); expect(fm.busy,isFalse); });
  test('FB-15', () async { await fm.submit('u1','e',' spaces '); expect(r.entries.first.msg,'spaces'); });
}
