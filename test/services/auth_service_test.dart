import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/services/auth_service.dart';
String _m(String c) { switch(c) { case 'user-not-found': return 'No account found with this email.'; case 'wrong-password': return 'Incorrect password. Please try again.'; case 'email-already-in-use': return 'An account already exists with this email.'; case 'invalid-email': return 'Please enter a valid email address.'; case 'user-disabled': return 'This account has been disabled.'; case 'too-many-requests': return 'Too many attempts. Please try again later.'; case 'network-request-failed': return 'Network error. Please check your connection.'; case 'requires-recent-login': return 'Please sign in again to perform this action.'; default: return 'Authentication error. Please try again.'; } }
void main() {
  test('AUTHEX-01', () => expect(const AuthException('B').message,'B'));
  test('AUTHEX-02', () { final s=const AuthException('MyError').toString(); expect(s,'MyError'); });
  test('AUTHEX-03', () => expect(const AuthException('x'),isA<Exception>()));
  test('AUTHEX-04', () => expect((){throw const AuthException('t');},throwsA(isA<AuthException>())));
  test('AUTHEX-05', () { String? c; try{throw const AuthException('p');}on AuthException catch(e){c=e.message;} expect(c,'p'); });
  test('MSG-01', () => expect(_m('user-not-found'),'No account found with this email.'));
  test('MSG-02', () => expect(_m('wrong-password'),'Incorrect password. Please try again.'));
  test('MSG-03', () => expect(_m('email-already-in-use'),'An account already exists with this email.'));
  test('MSG-04', () => expect(_m('invalid-email'),'Please enter a valid email address.'));
  test('MSG-05', () => expect(_m('user-disabled'),'This account has been disabled.'));
  test('MSG-06', () => expect(_m('too-many-requests'),'Too many attempts. Please try again later.'));
  test('MSG-07', () => expect(_m('network-request-failed'),'Network error. Please check your connection.'));
  test('MSG-08', () => expect(_m('requires-recent-login'),'Please sign in again to perform this action.'));
  test('MSG-09', () => expect(_m('xyz'),'Authentication error. Please try again.'));
  test('MSG-10', () => expect(_m(''),'Authentication error. Please try again.'));
}