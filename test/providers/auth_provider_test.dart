import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/user_profile.dart';
import 'package:shopping_app/services/auth_service.dart' show AuthException;
import 'package:shopping_app/utils/subscription_limits.dart';

enum _S { unauth, auth }

UserProfile _p({String id = 'u1', String name = 'U', String? g}) => UserProfile(
    id: id, email: '$id@t.com', displayName: name, gender: g,
    createdAt: DateTime(2024), subscriptionTier: SubscriptionTier.free);

class _Svc {
  bool cg=false,tai=false,tgi=false,trd=false,tad=false,tao=false,tu=false;
  UserProfile? ir, ur;
  Future<UserProfile?> signIn() async { if(cg)return null; if(tai)throw AuthException('Sign-in failed. Please try again.'); if(tgi)throw Exception('x'); return ir??_p(); }
  Future<void> delete() async { if(trd)throw AuthException('For security reasons, please sign out and sign in again before deleting your account.'); if(tad)throw AuthException('Account deletion failed. Please try again.'); }
  Future<void> out() async { if(tao)throw AuthException('Sign-out failed. Please try again.'); }
  Future<UserProfile> upd({required String id,String? n,String? g}) async { if(tu)throw Exception('e'); return ur??_p(id:id,name:n??'Up',g:g); }
}

class _P extends ChangeNotifier {
  final _Svc _s; _S _st=_S.unauth; UserProfile? _up; bool _lo=false; String? _em; _P(this._s);
  _S get status=>_st; UserProfile? get userProfile=>_up; bool get isLoading=>_lo; String? get errorMessage=>_em; bool get isAuthenticated=>_st==_S.auth;
  Future<bool> signIn() async { _ld(true);_cl(); try { final x=await _s.signIn(); if(x!=null){_up=x;_st=_S.auth;notifyListeners();return true;} return false; } on AuthException catch(e){_em=e.message;notifyListeners();return false;} catch(_){_em='An unexpected error occurred. Please try again.';notifyListeners();return false;} finally{_ld(false);} }
  Future<void> delete() async { _ld(true);_cl(); try{await _s.delete();_up=null;_st=_S.unauth;notifyListeners();} on AuthException catch(e){_em=e.message;notifyListeners();rethrow;} catch(_){_em='Account deletion failed. Please try again.';notifyListeners();rethrow;} finally{_ld(false);} }
  Future<void> signOut() async { _ld(true);_cl(); try{await _s.out();_up=null;_st=_S.unauth;notifyListeners();} on AuthException catch(e){_em=e.message;notifyListeners();} finally{_ld(false);} }
  Future<bool> update({String? n,String? g}) async { if(_up==null)return false; _ld(true);_cl(); try{_up=await _s.upd(id:_up!.id,n:n,g:g);notifyListeners();return true;} catch(_){_em='Failed to update profile.';notifyListeners();return false;} finally{_ld(false);} }
  void clear(){_cl();notifyListeners();}
  void _ld(bool v){_lo=v;notifyListeners();} void _cl()=>_em=null;
}

void main() {
  late _Svc s; late _P p;
  setUp((){s=_Svc();p=_P(s);});
  group('initial state',(){
    test('INIT-01',()=>expect(p.userProfile,isNull));
    test('INIT-02',()=>expect(p.isAuthenticated,isFalse));
    test('INIT-03',()=>expect(p.isLoading,isFalse));
    test('INIT-04',()=>expect(p.errorMessage,isNull));
    test('INIT-05',()=>expect(p.status,_S.unauth));
  });
  group('signIn',(){
    test('SIGN-01',()async{s.ir=_p(id:'g',name:'G');final r=await p.signIn();expect(r,isTrue);expect(p.isAuthenticated,isTrue);expect(p.userProfile!.id,'g');expect(p.errorMessage,isNull);expect(p.isLoading,isFalse);});
    test('SIGN-02',()async{s.cg=true;expect(await p.signIn(),isFalse);expect(p.isAuthenticated,isFalse);expect(p.isLoading,isFalse);});
    test('SIGN-03',()async{s.tai=true;expect(await p.signIn(),isFalse);expect(p.errorMessage,contains('Sign-in failed'));expect(p.isLoading,isFalse);});
    test('SIGN-04',()async{s.tgi=true;expect(await p.signIn(),isFalse);expect(p.errorMessage,contains('unexpected'));expect(p.isLoading,isFalse);});
    test('SIGN-05',()async{final snaps=<bool>[];p.addListener(()=>snaps.add(p.isLoading));await p.signIn();expect(snaps.contains(true),isTrue);expect(snaps.last,isFalse);});
    test('SIGN-06',()async{s.tai=true;await p.signIn();expect(p.errorMessage,isNotNull);s.tai=false;await p.signIn();expect(p.errorMessage,isNull);});
    test('SIGN-07',()async{s.ir=_p(id:'a');await p.signIn();expect(p.userProfile!.id,'a');s.ir=_p(id:'b');await p.signIn();expect(p.userProfile!.id,'b');});
  });
  group('deleteAccount',(){
    setUp(()async{s.ir=_p(id:'d');await p.signIn();});
    test('DEL-01',()async{await p.delete();expect(p.userProfile,isNull);expect(p.isAuthenticated,isFalse);expect(p.status,_S.unauth);expect(p.errorMessage,isNull);expect(p.isLoading,isFalse);});
    test('DEL-02',()async{int n=0;p.addListener(()=>n++);await p.delete();expect(n,greaterThan(0));});
    test('DEL-03',()async{final snaps=<bool>[];p.addListener(()=>snaps.add(p.isLoading));await p.delete();expect(snaps.contains(true),isTrue);expect(snaps.last,isFalse);});
    test('DEL-04',()async{s.trd=true;await expectLater(()async=>await p.delete(),throwsA(isA<AuthException>().having((e)=>e.message,'m',contains('sign out'))));expect(p.errorMessage,contains('sign out'));expect(p.isLoading,isFalse);});
    test('DEL-05',()async{s.tad=true;await expectLater(()async=>await p.delete(),throwsA(isA<AuthException>()));expect(p.errorMessage,contains('deletion failed'));expect(p.isLoading,isFalse);});
    test('DEL-06',()async{s.tad=true;try{await p.delete();}catch(_){}expect(p.userProfile,isNotNull);expect(p.userProfile!.id,'d');});
  });
  group('signOut',(){
    setUp(()async{s.ir=_p(id:'so');await p.signIn();});
    test('SO-01',()async{await p.signOut();expect(p.userProfile,isNull);expect(p.status,_S.unauth);expect(p.errorMessage,isNull);expect(p.isLoading,isFalse);});
    test('SO-02',()async{final snaps=<bool>[];p.addListener(()=>snaps.add(p.isLoading));await p.signOut();expect(snaps.contains(true),isTrue);expect(snaps.last,isFalse);});
    test('SO-03',()async{s.tao=true;await p.signOut();expect(p.errorMessage,contains('Sign-out failed'));expect(p.isLoading,isFalse);});
    test('SO-04',()async{await p.signOut();expect(p.userProfile,isNull);});
  });
  group('updateProfile',(){
    test('UPD-01',()async{expect(await p.update(n:'X'),isFalse);});
    test('UPD-02',()async{s.ir=_p(id:'u');s.ur=_p(id:'u',name:'New',g:'male');await p.signIn();final ok=await p.update(n:'New',g:'male');expect(ok,isTrue);expect(p.userProfile!.displayName,'New');expect(p.userProfile!.gender,'male');expect(p.isLoading,isFalse);});
    test('UPD-03',()async{s.ir=_p(id:'f');await p.signIn();s.tu=true;final ok=await p.update(n:'X');expect(ok,isFalse);expect(p.errorMessage,contains('update profile'));expect(p.isLoading,isFalse);});
    test('UPD-04',()async{s.ir=_p(id:'l');await p.signIn();final snaps=<bool>[];p.addListener(()=>snaps.add(p.isLoading));await p.update(n:'Y');expect(snaps.contains(true),isTrue);expect(snaps.last,isFalse);});
  });
  group('clearError',(){
    test('CLR-01',()async{s.tai=true;await p.signIn();expect(p.errorMessage,isNotNull);int n=0;p.addListener(()=>n++);p.clear();expect(p.errorMessage,isNull);expect(n,greaterThan(0));});
    test('CLR-02',(){expect(()=>p.clear(),returnsNormally);expect(p.errorMessage,isNull);});
  });
}
