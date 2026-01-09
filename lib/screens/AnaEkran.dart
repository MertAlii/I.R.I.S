import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'HastaneHaritaEkrani.dart';
import 'AnketEkranı.dart';
import 'ÖzetEkranı.dart';
import 'YapayZekaEkranı.dart';
import 'AyarlarEkranı.dart';

class AnaEkran extends ConsumerStatefulWidget {
  @override
  _AnaEkranState createState() => _AnaEkranState();
}

class _AnaEkranState extends ConsumerState<AnaEkran> {
  String _userName = '';
  int _recoveryDay = 0;
  int _surveyCount = 0;
  bool _isDailySurveyDone = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = ref.read(storageServiceProvider);
    
    try {
      final userData = storage.getUserData();
      final surveyDone = await storage.isDailySurveyDone();
      final count = await storage.getSurveyCount();
      
      if (mounted) {
        if (userData != null) {
          // Normalize dates to start of day for accurate day counting
          final surgeryDate = userData['surgeryDate'];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final sDate = DateTime(surgeryDate.year, surgeryDate.month, surgeryDate.day);
          final diff = today.difference(sDate).inDays;
          
          setState(() {
            _userName = userData['name'] ?? 'Kullanıcı';
            _recoveryDay = diff + 1; // +1 because day of surgery is Day 1
            _isDailySurveyDone = surveyDone;
            _surveyCount = count;
            _isLoading = false;
          });
        } else {
            setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSurveyTap() async {
    if (_isDailySurveyDone) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Bugün kaydınız mevcut'),
          content: const Text(
            'Bugünkü anketinizi zaten tamamladınız. Ne yapmak istersiniz?',
            style: TextStyle(color: Color(0xFF2D3436)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(context, MaterialPageRoute(builder: (context) => OzetEkrani()));
              },
              child: const Text('Özeti Gör', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                // Allow new survey
                await Navigator.push(context, MaterialPageRoute(builder: (context) => AnketEkran()));
                _loadUserData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6BAA75),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Yeni Anket Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => AnketEkran()));
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white, // Or user preferred bg
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                // height: 989, // Height removed to be adaptive
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                     BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 8),
                      spreadRadius: -6,
                    ),
                     BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 25,
                      offset: Offset(0, 20),
                      spreadRadius: -5,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 32, top: 38, bottom: 40),
                      child: Column( 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Merhaba, $_userName',
                                          style: const TextStyle(
                                            color: Color(0xFF2D3436),
                                            fontSize: 24,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w400,
                                            height: 1.50,
                                          ),
                                        ),
                                        Text(
                                          'Bugün Ameliyattın $_recoveryDay. Günü',
                                          style: const TextStyle(
                                            color: Color(0xFF6BAA75),
                                            fontSize: 16,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w400,
                                            height: 1.50,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Settings/Profile Button
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to Settings
                                         Navigator.push(context, MaterialPageRoute(builder: (context) => AyarlarEkran())); 
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFF6BAA75),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          shadows: const [
                                            BoxShadow(
                                              color: Color(0x33171717),
                                              blurRadius: 6,
                                              offset: Offset(0, 4),
                                              spreadRadius: -4,
                                            ),
                                            BoxShadow(
                                              color: Color(0x33171717),
                                              blurRadius: 15,
                                              offset: Offset(0, 10),
                                              spreadRadius: -3,
                                            )
                                          ],
                                        ),
                                        child: const Icon(Icons.settings, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          // Survey Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1.15,
                                  color: Colors.black.withValues(alpha: 0.10),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadows: const [
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                  spreadRadius: -4,
                                ),
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 15,
                                  offset: Offset(0, 10),
                                  spreadRadius: -3,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isDailySurveyDone ? 'Bugün Tamamlandı' : 'Bugün Nasılsınız?',
                                  style: const TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _isDailySurveyDone 
                                    ? 'Kayıtlarınız başarıyla alındı. Durumunuzu incelemek için butona tıklayın.'
                                    : 'Günlük durumunuzu kaydederek iyileşme sürecinizi takip edin ve kişiselleştirilmiş öneriler alın.',
                                  style: const TextStyle(
                                    color: Color(0xFF6C757D),
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _handleSurveyTap,
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: ShapeDecoration(
                                      color: _isDailySurveyDone ? Colors.grey : const Color(0xFF6BAA75),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      shadows: const [
                                         BoxShadow(
                                          color: Color(0x19000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                          spreadRadius: -2,
                                        ),
                                         BoxShadow(
                                          color: Color(0x19000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 4),
                                          spreadRadius: -1,
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        _isDailySurveyDone ? 'İncele' : 'Günlük Kaydınızı Başlatın',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Hospital Card
                          Container(
                            width: double.infinity,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1.15,
                                  color: Colors.black.withValues(alpha: 0.10),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadows: const [
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                  spreadRadius: -2,
                                ),
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                  spreadRadius: -1,
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5DADE2))), // Placeholder icon
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Yakınınızdaki Hastaneler',
                                            style: TextStyle(
                                              color: Color(0xFF2D3436),
                                              fontSize: 16,
                                              fontFamily: 'Arial',
                                              fontWeight: FontWeight.w400,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Acil durumda ulaşabileceğiniz sağlık merkezleri',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HastaneHaritaEkrani())),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: ShapeDecoration(
                                      color: const Color(0x195DADE2),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Haritaya Git',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // AI Assistant Card (Custom Added based on Figma Style)
                           Container(
                            width: double.infinity,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1.15,
                                  color: Colors.black.withValues(alpha: 0.10),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadows: const [
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                  spreadRadius: -2,
                                ),
                                 BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                  spreadRadius: -1,
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE67E22))), // Placeholder icon
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Yapay Zeka Asistanı',
                                            style: TextStyle(
                                              color: Color(0xFF2D3436),
                                              fontSize: 16,
                                              fontFamily: 'Arial',
                                              fontWeight: FontWeight.w400,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Sorularınızı sorun ve yapay zekadan destek alın.',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => YapayZekaEkran())),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: ShapeDecoration(
                                      color: const Color(0x19E67E22), 
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Yapay Zekaya Sor',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),


                          // Progress Card
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OzetEkrani())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1.15,
                                    color: Colors.black.withValues(alpha: 0.10),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                shadows: const [
                                   BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                    spreadRadius: -2,
                                  ),
                                   BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                    spreadRadius: -1,
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Row(
                                    children: [
                                      Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF9B59B6))), // Placeholder icon
                                      const SizedBox(width: 8),
                                      const Text(
                                        'İlerlemeniz',
                                        style: TextStyle(
                                          color: Color(0xFF2D3436),
                                          fontSize: 16,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Grafiklerinizi ve detaylı analizinizi görmek için dokunun.',
                                    style: TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 16,
                                      fontFamily: 'Arial',
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total Records
                              Expanded(child: _buildStatCard(
                                value: _surveyCount.toString(),
                                label: "Toplam Kayıt",
                                color: const Color(0xFF5DADE2),
                                bgHex: 0x195DADE2,
                              )),
                              const SizedBox(width: 16),
                              // Recovery Day
                               Expanded(child: _buildStatCard(
                                value: _recoveryDay.toString(),
                                label: "İyileşme Günü",
                                color: const Color(0xFF6BAA75),
                                bgHex: 0x196BAA75,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label, required Color color, required int bgHex}) {
    return Container(
      height: 166,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.15,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
           BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
           BoxShadow(
            color: Color(0x19000000),
            blurRadius: 3,
            offset: Offset(0, 1),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: Color(bgHex),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
             child: Icon(Icons.show_chart, color: color), // Placeholder icon
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontFamily: 'Arial',
              fontWeight: FontWeight.w700,
              height: 1.20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 14,
              fontFamily: 'Arial',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }
}
