
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Add platform Firebase config before running.
  runApp(const AapniChaiApp());
}

class AapniChaiApp extends StatelessWidget {
  const AapniChaiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AAPNI CHAI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff245642)),
      useMaterial3: true, scaffoldBackgroundColor: const Color(0xfff6f7f4)),
    home: const Gate(),
  );
}

class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();
    return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child:CircularProgressIndicator()));
        final role = snap.data?.data()?['role'] ?? 'staff';
        return HomePage(isOwner: role == 'owner');
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email=TextEditingController(), pass=TextEditingController();
  String? error; bool busy=false;
  Future<void> login() async {
    setState(()=>busy=true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email:email.text.trim(),password:pass.text);
      if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const Gate()));
    } catch(e){setState(()=>error='Login nahi hua. Email/password aur Firebase setup check karein.');}
    if(mounted)setState(()=>busy=false);
  }
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:ConstrainedBox(
    constraints:const BoxConstraints(maxWidth:420),child:Card(margin:const EdgeInsets.all(24),child:Padding(
      padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.local_cafe,size:54,color:Color(0xff245642)),
        const Text('AAPNI CHAI',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
        const Text('Smart Hisab Management'),
        const SizedBox(height:22),
        TextField(controller:email,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email))),
        TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock))),
        if(error!=null) Text(error!,style:const TextStyle(color:Colors.red)),
        const SizedBox(height:16),FilledButton(onPressed:busy?null:login,child:Text(busy?'Please wait':'Login')),
      ]),
    )))));
}

class HomePage extends StatefulWidget {
  final bool isOwner;
  const HomePage({super.key,required this.isOwner});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0;
  @override Widget build(BuildContext context){
    final pages=[Dashboard(isOwner:widget.isOwner),ShopList(isOwner:widget.isOwner)];
    return Scaffold(appBar:AppBar(title:const Text('☕ AAPNI CHAI'),actions:[
      IconButton(onPressed:()async{await FirebaseAuth.instance.signOut();if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const Gate()));},icon:const Icon(Icons.logout))
    ]),
    body:pages[tab],
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
      destinations:const [NavigationDestination(icon:Icon(Icons.dashboard),label:'Dashboard'),NavigationDestination(icon:Icon(Icons.store),label:'Shopkeepers')]));
  }
}

class Dashboard extends StatelessWidget {
  final bool isOwner;
  const Dashboard({super.key,required this.isOwner});
  @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:FirebaseFirestore.instance.collection('deliveries').snapshots(),
    builder:(context,snap){
      final docs=snap.data?.docs??[];
      final today=DateFormat('yyyy-MM-dd').format(DateTime.now());
      double sales=0; int glasses=0;
      for(final d in docs){final x=d.data();if(x['date']==today){sales+=(x['amount']??0).toDouble();glasses+=(x['glasses']??0) as int;}}
      return ListView(padding:const EdgeInsets.all(16),children:[
        Text(isOwner?'Owner Dashboard':'Staff View',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:12),
        Row(children:[Expanded(child:Metric(title:'Aaj ki sale',value:'₹${sales.toStringAsFixed(2)}',icon:Icons.currency_rupee)),const SizedBox(width:10),Expanded(child:Metric(title:'Aaj ke glass',value:'$glasses',icon:Icons.local_cafe))]),
        const SizedBox(height:10),
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('shopkeepers').snapshots(),builder:(c,s){
          return Metric(title:'Total shopkeepers',value:'${s.data?.docs.length??0}',icon:Icons.people);
        }),
        const SizedBox(height:18),const Text('Aaj ki delivery entries',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        ...docs.where((d)=>d.data()['date']==today).map((d){final x=d.data();return Card(child:ListTile(title:Text(x['shopName']??'Shopkeeper'),subtitle:Text('${x['time']??''} • ${x['glasses']??0} glass'),trailing:Text('₹${x['amount']??0}')));}),
        if(!isOwner) const Padding(padding:EdgeInsets.all(8),child:Text('Staff login: read-only access.')),
      ]);
    });
}
class Metric extends StatelessWidget{
 final String title,value; final IconData icon;
 const Metric({super.key,required this.title,required this.value,required this.icon});
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Icon(icon,color:const Color(0xff245642)),const SizedBox(height:8),Text(title,style:const TextStyle(color:Colors.black54)),Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold))
 ])));
}

class ShopList extends StatelessWidget {
 final bool isOwner;
 const ShopList({super.key,required this.isOwner});
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.transparent,
  floatingActionButton:isOwner?FloatingActionButton.extended(onPressed:()=>showDialog(context:context,builder:(_)=>const AddShopDialog()),icon:const Icon(Icons.add),label:const Text('Add Shopkeeper')):null,
  body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('shopkeepers').orderBy('name').snapshots(),builder:(context,snap){
   if(!snap.hasData)return const Center(child:CircularProgressIndicator());
  return ListView(
  children: snap.data!.docs.map((d) {
    final x = d.data();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(x['name'] ?? ''),
        subtitle: Text(
          '${x['phone'] ?? ''} • ${x['address'] ?? ''}\n'
          'Rate: ₹${x['rate'] ?? 0}/glass',
        ),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopDetail(
              id: d.id,
              data: x,
              isOwner: isOwner,
            ),
          ),
        ),
      ),
    );
  }).toList(),
);
  }));
}

class AddShopDialog extends StatefulWidget {const AddShopDialog({super.key});@override State<AddShopDialog> createState()=>_AddShopDialogState();}
class _AddShopDialogState extends State<AddShopDialog>{
 final name=TextEditingController(),phone=TextEditingController(),address=TextEditingController(),rate=TextEditingController(),opening=TextEditingController(text:'0');
 Future<void> save()async{
  await FirebaseFirestore.instance.collection('shopkeepers').add({'name':name.text.trim(),'phone':phone.text.trim(),'address':address.text.trim(),'rate':double.tryParse(rate.text)??0,'openingBalance':double.tryParse(opening.text)??0,'active':true,'createdAt':FieldValue.serverTimestamp()});
  if(mounted)Navigator.pop(context);
 }
 @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Naya Shopkeeper'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
  field(name,'Shopkeeper name'),field(phone,'Mobile number',keyboard:TextInputType.phone),field(address,'Address'),field(rate,'Rate per glass (₹)',keyboard:TextInputType.number),field(opening,'Opening balance (₹)',keyboard:TextInputType.number)
 ])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:save,child:const Text('Save'))]);
}
Widget field(TextEditingController c,String label,{TextInputType keyboard=TextInputType.text})=>TextField(controller:c,keyboardType:keyboard,decoration:InputDecoration(labelText:label));

class ShopDetail extends StatelessWidget{
 final String id;final Map<String,dynamic> data;final bool isOwner;
 const ShopDetail({super.key,required this.id,required this.data,required this.isOwner});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(data['name']??'Shopkeeper')),
 body:ListView(padding:const EdgeInsets.all(16),children:[
  Metric(title:'Rate per glass',value:'₹${data['rate']??0}',icon:Icons.local_cafe),
  ListTile(title:const Text('Mobile'),subtitle:Text(data['phone']??'')),
  ListTile(title:const Text('Address'),subtitle:Text(data['address']??'')),
  if(isOwner) Wrap(spacing:8,children:[
   FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AddEntry(shopId:id,shopName:data['name']??'',rate:(data['rate']??0).toDouble(),payment:false))),icon:const Icon(Icons.add),label:const Text('Delivery entry')),
   OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AddEntry(shopId:id,shopName:data['name']??'',rate:0,payment:true))),icon:const Icon(Icons.payments),label:const Text('Payment entry')),
  ]),
  const SizedBox(height:16),const Text('Ledger entries',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('ledger').where('shopId',isEqualTo:id).orderBy('createdAt',descending:true).snapshots(),builder:(c,s){
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return Column(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(title:Text(x['type']=='delivery'?'${x['glasses']} glass delivery':'Payment received'),subtitle:Text('${x['date']} • ${x['time']}'),trailing:Text('₹${x['amount']}')));}).toList());
  })
 ]));
}

class AddEntry extends StatefulWidget{
 final String shopId,shopName;final double rate;final bool payment;
 const AddEntry({super.key,required this.shopId,required this.shopName,required this.rate,required this.payment});
 @override State<AddEntry> createState()=>_AddEntryState();
}
class _AddEntryState extends State<AddEntry>{
 final qty=TextEditingController(),amount=TextEditingController(),note=TextEditingController();
 bool busy=false;
 Future<void> save()async{
  setState(()=>busy=true);
  final now=DateTime.now();final isPay=widget.payment;
  final a=isPay?(double.tryParse(amount.text)??0):(int.tryParse(qty.text)??0)*widget.rate;
  final common={'shopId':widget.shopId,'shopName':widget.shopName,'amount':a,'date':DateFormat('yyyy-MM-dd').format(now),'time':DateFormat('hh:mm a').format(now),'note':note.text,'createdAt':FieldValue.serverTimestamp()};
  await FirebaseFirestore.instance.collection('ledger').add({...common,'type':isPay?'payment':'delivery','glasses':isPay?0:(int.tryParse(qty.text)??0)});
  if(!isPay) await FirebaseFirestore.instance.collection('deliveries').add({...common,'glasses':int.tryParse(qty.text)??0});
  if(mounted)Navigator.pop(context);
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.payment?'Payment entry':'Chai delivery')),
 body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
  Text(widget.shopName,style:Theme.of(context).textTheme.titleLarge),
  if(widget.payment)TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Payment amount ₹'))
  else TextField(controller:qty,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Glass quantity • Rate ₹${widget.rate}')),
  TextField(controller:note,decoration:const InputDecoration(labelText:'Note (optional)')),
  const SizedBox(height:16),FilledButton(onPressed:busy?null:save,child:const Text('Save entry'))
 ])));
}
