import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iris_app/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iris_app/main.dart'; // FadeInAnimation için
import 'package:iris_app/screens/survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Kullanıcı";
  int recoveryDay = 1;
  int totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Kullanıcı";
      
      List<String>? logs = prefs.getStringList('logs');
      totalRecords = logs?.length ?? 0; 

      String? dateStr = prefs.getString('surgeryDate');
      if (dateStr != null) {
        DateTime surgeryDate = DateTime.parse(dateStr);
        DateTime now = DateTime.now();
        DateTime dateOnlySurgery = DateTime(surgeryDate.year, surgeryDate.month, surgeryDate.day);
        DateTime dateOnlyNow = DateTime(now.year, now.month, now.day);
        
        recoveryDay = dateOnlyNow.difference(dateOnlySurgery).inDays + 1;
        if (recoveryDay < 1) recoveryDay = 1;
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF6BAA75);
    final Color primaryDark = const Color(0xFF2D3436);
    final Color lightGray = const Color(0xFF6C757D);
    final Color cardBorder = Colors.black.withOpacity(0.10);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                FadeInAnimation(
                  delay: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, $userName',
                            style: TextStyle(color: primaryDark, fontSize: 24, fontFamily: 'Arial', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bugün iyileşmenizin $recoveryDay. günü.',
                            style: TextStyle(color: primaryGreen, fontSize: 16, fontFamily: 'Arial'),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0x33171717), blurRadius: 15, offset: const Offset(0, 10), spreadRadius: -3)],
                          ),
                          child: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. Anket Kartı
                FadeInAnimation(
                  delay: 200,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.15),
                      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bugün Nasılsınız?', style: TextStyle(color: primaryDark, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Günlük durumunuzu kaydederek iyileşme sürecinizi takip edin.', style: TextStyle(color: lightGray, fontSize: 14)),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SurveyScreen()),
                              );
                              if (result == true) {
                                _loadUserData(); 
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: const Text('Günlük Kaydınızı Başlatın', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Hastaneler Kartı
                FadeInAnimation(
                  delay: 300,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.15),
                      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Row(children: [const Icon(Icons.local_hospital, color: Color(0xFF2D3436), size: 20), const SizedBox(width: 8), Text('Yakınınızdaki Hastaneler', style: TextStyle(color: primaryDark, fontSize: 16, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        Text('Acil durumda ulaşabileceğiniz sağlık merkezleri', style: TextStyle(color: lightGray, fontSize: 14)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF5DADE2)), backgroundColor: const Color(0xFF5DADE2).withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Haritaya Git', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. İlerleme Kartı
                FadeInAnimation(
                  delay: 400,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder, width: 1.15), boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.trending_up, color: Color(0xFF2D3436), size: 20), const SizedBox(width: 8), Text('İlerlemeniz', style: TextStyle(color: primaryDark, fontSize: 16, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        Text('Grafiklerinizi ve detaylı analizinizi görmek için dokunun.', style: TextStyle(color: lightGray, fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. İstatistikler
                FadeInAnimation(
                  delay: 500,
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard(title: '$recoveryDay', subtitle: 'İyileşme Günü', icon: Icons.calendar_today, iconColor: primaryGreen, bgIconColor: primaryGreen.withOpacity(0.1))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(title: '$totalRecords', subtitle: 'Toplam Kayıt', icon: Icons.edit_document, iconColor: const Color(0xFF5DADE2), bgIconColor: const Color(0xFF5DADE2).withOpacity(0.1))),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DÜZELTİLEN KISIM BURASI ---
  Widget _buildStatCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required Color bgIconColor}) {
    return Container(
      // HATA DÜZELTME: Sabit 'height: 166' yerine 'minHeight' kullandık.
      // Böylece içerik sığmazsa kart aşağı doğru uzayabilir.
      constraints: const BoxConstraints(minHeight: 150), 
      // Padding'i biraz azalttık (24 -> 16) ki içeriğe yer kalsın
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.10), width: 1.15),
        boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgIconColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          // Sayı çok büyükse sığdırmak için ölçekle
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(color: iconColor, fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2, // Gerekirse 2 satıra geçsin
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6C757D), fontSize: 14),
          )
        ],
      ),
    );
  }
}