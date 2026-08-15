import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
const _ch = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
String _gen() => List.generate(6,(_)=>_ch[Random.secure().nextInt(_ch.length)]).join();
class _R {
  final _i=<String,Map<String,dynamic>>{};
  final _m=<String,Set<String>>{};
  void add(String c,String l,{bool u=false})=>_i[c]={"l":l,"u":u};
  void addM(String l,String u)=>_m.putIfAbsent(l,()=>{}).add(u);
  Future<String?> redeem(String c,String uid) async {
    final k=c.toUpperCase().trim(); final v=_i[k];
    if(v==null)throw Exception("Invalid invite code.");
    if(v["u"]==true)throw Exception("already been used");
    final l=v["l"] as String;
    if(_m[l]?.contains(uid)==true)throw Exception("already a member");
    _m.putIfAbsent(l,()=>{}).add(uid); v["u"]=true; return l;
  }
  bool isMem(String l,String u)=>_m[l]?.contains(u)??false;
  bool isUsed(String c)=>_i[c]?["u"]==true;
}
void main() {
  test("INV-01", ()=>expect(_gen().length,6));
  test("INV-02", (){for(int i=0;i<10;i++){for(final c in _gen().split("")){expect(_ch.contains(c),isTrue);}}});
  test("INV-03", (){for(int i=0;i<10;i++){final c=_gen();for(final b in ["I","O","0","1"]){expect(c.contains(b),isFalse);}}});
  test("INV-04", ()=>expect(List.generate(10,(_)=>_gen()).toSet().length,greaterThan(1)));
  test("INV-05", (){final c=_gen();expect(c,c.toUpperCase());});
  late _R r; setUp(()=>r=_R());
  test("INV-06", ()async{await expectLater(()async=>await r.redeem("X","u"),throwsA(isA<Exception>().having((e)=>e.toString(),"m",contains("Invalid"))));});
  test("INV-07", ()async{r.add("A","l",u:true);await expectLater(()async=>await r.redeem("A","u"),throwsA(isA<Exception>().having((e)=>e.toString(),"m",contains("already been used"))));});
  test("INV-08", ()async{r.add("B","l");r.addM("l","u");await expectLater(()async=>await r.redeem("B","u"),throwsA(isA<Exception>().having((e)=>e.toString(),"m",contains("already a member"))));});
  test("INV-09", ()async{r.add("C","l42");expect(await r.redeem("C","u"),"l42");});
  test("INV-10", ()async{r.add("D","l99");await r.redeem("D","u4");expect(r.isMem("l99","u4"),isTrue);});
  test("INV-11", ()async{r.add("E","l77");await r.redeem("E","u5");expect(r.isUsed("E"),isTrue);});
  test("INV-12", ()async{r.add("ABCDEF","l3");expect(await r.redeem("abcdef","u"),"l3");});
  test("INV-13", ()async{r.add("TRIM11","l4");expect(await r.redeem("  TRIM11  ","u"),"l4");});
  test("INV-14", ()async{r.add("I1","l5");r.add("I2","l5");await r.redeem("I1","u8");await r.redeem("I2","u9");expect(r.isMem("l5","u8"),isTrue);expect(r.isMem("l5","u9"),isTrue);});
}
