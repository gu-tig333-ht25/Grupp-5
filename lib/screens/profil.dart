import 'package:flutter/material.dart';


class ProfilePage extends StatelessWidget {
 final bool isDarkMode;
 final Function(bool) onThemeChanged;


 const ProfilePage({
   super.key,
   required this.isDarkMode,
   required this.onThemeChanged,
 });


 @override
 Widget build(BuildContext context) {
   // Navigering för bottenmeny
   void onTabTapped(int i) {
     switch (i) {
       case 0: Navigator.pushReplacementNamed(context, '/'); break;      // Hem
       case 1: Navigator.pushReplacementNamed(context, '/logga'); break; // Logga
       case 2: Navigator.pushReplacementNamed(context, '/karta'); break; // Karta
       case 3: Navigator.pushReplacementNamed(context, '/stat'); break;  // Statistik
       case 4: /* redan på Profil */ break;
     }
   }


   // Info-popup
   void showAppInfo() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Om MoodMap'),
         content: const Text(
           'MoodMap hjälper dig att reflektera över hur plats och miljö påverkar ditt välmående. '
           'Genom att logga ditt humör på olika platser får du en personlig karta över ditt mående '
           'och kan se mönster över tid.',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Stäng'),
           ),
         ],
       ),
     );
   }


   return Scaffold(
     appBar: AppBar(
       title: const Text('Profil'),
       centerTitle: true,
       elevation: 0,
     ),


     body: SingleChildScrollView(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.center,
         children: [
           // Profil
           CircleAvatar(
             radius: 50,
             backgroundColor: Colors.purpleAccent.shade100,
             child: const Icon(Icons.person, size: 60, color: Colors.white),
           ),
           const SizedBox(height: 16),
           const Text(
             'Alex Andersson',
             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 4),
           Text('alex.andersson@email.se',
               style: TextStyle(color: Colors.grey[600])),
           const SizedBox(height: 32),


           Align(
             alignment: Alignment.centerLeft,
             child: Text(
               'Inställningar',
               style: Theme.of(context)
                   .textTheme
                   .titleMedium
                   ?.copyWith(fontWeight: FontWeight.bold),
             ),
           ),
           const SizedBox(height: 16),


           // 🌞/🌙 och ℹ️ Information bredvid varandra (lika stora)
           Row(
             children: [
               // 🔦 Tema-switch (lika stor som info-rutan)
               Expanded(
                 child: Container(
                   height: 70,
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.surfaceVariant,
                     borderRadius: BorderRadius.circular(16),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Icon(Icons.wb_sunny_outlined, size: 26),
                       Switch(
                         value: isDarkMode,
                         activeColor: Colors.deepPurpleAccent,
                         inactiveThumbColor: Colors.amber,
                         onChanged: onThemeChanged,
                       ),
                       const Icon(Icons.nightlight_outlined, size: 26),
                     ],
                   ),
                 ),
               ),
               const SizedBox(width: 12),


               // 🛈 Info-ruta (klickbar & lika stor)
               Expanded(
                 child: InkWell(
                   borderRadius: BorderRadius.circular(16),
                   onTap: showAppInfo,
                   child: Container(
                     height: 70,
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surfaceVariant,
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.info_outline,
                             color: Colors.deepPurpleAccent, size: 26),
                         const SizedBox(width: 8),
                         Text(
                           'Information',
                           style: Theme.of(context)
                               .textTheme
                               .bodyMedium
                               ?.copyWith(fontWeight: FontWeight.w500),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
             ],
           ),


           const SizedBox(height: 24),


           // Krisinfo-ruta
           const SupportHelpCard(),
           const SizedBox(height: 24),
         ],
       ),
     ),


     // Bottenmeny
     bottomNavigationBar: BottomNavigationBar(
       currentIndex: 4, // Profil aktiv
       onTap: onTabTapped,
       type: BottomNavigationBarType.fixed,
       selectedItemColor: Colors.purple,
       unselectedItemColor: Colors.grey,
       items: const [
         BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Hem'),
         BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Logga'),
         BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Karta'),
         BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Statistik'),
         BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
       ],
     ),
   );
 }
}


// ---------- Krisinfo-kort (icke-klickbart) ----------
class SupportHelpCard extends StatelessWidget {
 const SupportHelpCard({super.key});


 @override
 Widget build(BuildContext context) {
   final textTheme = Theme.of(context).textTheme;


   Widget item(String title, String number) {
     return AbsorbPointer(
       absorbing: true,
       child: Container(
         margin: const EdgeInsets.symmetric(vertical: 6),
         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
         decoration: BoxDecoration(
           color: Theme.of(context).colorScheme.surface,
           borderRadius: BorderRadius.circular(14),
           boxShadow: [
             BoxShadow(
               blurRadius: 8,
               offset: const Offset(0, 4),
               color: Colors.black.withOpacity(0.06),
             ),
           ],
         ),
         child: Row(
           children: [
             const Icon(Icons.phone_outlined),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(title,
                       style: textTheme.bodyLarge?.copyWith(
                         fontWeight: FontWeight.w600,
                       )),
                   const SizedBox(height: 2),
                   Text(number,
                       style: textTheme.bodyMedium?.copyWith(
                         color: Colors.grey,
                       )),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
   }


   return Container(
     width: double.infinity,
     padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
     decoration: BoxDecoration(
       borderRadius: BorderRadius.circular(18),
       gradient: LinearGradient(
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
         colors: [
           Colors.lightBlue.shade50,
           Colors.cyan.shade50,
         ],
       ),
       boxShadow: [
         BoxShadow(
           blurRadius: 16,
           offset: const Offset(0, 8),
           color: Colors.black.withOpacity(0.07),
         ),
       ],
     ),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text('Stöd för mental hälsa',
             style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
         const SizedBox(height: 6),
         Text(
           'Om du är i kris eller behöver stöd finns dessa resurser tillgängliga dygnet runt:',
           style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
         ),
         const SizedBox(height: 12),
         item('Självmordslinjen', '90101'),
         item('Mind', '020-850 600'),
         item('BRIS', '116 111'),
       ],
     ),
   );
 }
}
