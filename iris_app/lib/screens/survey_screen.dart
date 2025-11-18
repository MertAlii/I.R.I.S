import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Verileri JSON formatında kaydetmek için
import 'package:iris_app/main.dart'; // FadeInAnimation için

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // Ağrı Seviyesi (0.0 - 10.0 arası)
  double _currentPainValue = 0;

  // Seçilen Belirtiler Listesi
  final List<String> _selectedSymptoms = [];

  // Tüm Belirtiler (Figma'dan alındı)
  final List<String> _allSymptoms = [
    'Yara Yerinde Ağrı', 'Kas Ağrısı', 'Eklem Ağrısı',
    'Şişlik', 'Kızarıklık', 'Akıntı',
    'Ateş', 'Titreme', 'Terleme',
    'Baş Ağrısı', 'Baş Dönmesi', 'Bulantı',
    'Kusma', 'İshal', 'Kabızlık',
    'Gaz Problemi', 'İştah Kaybı', 'Yorgunluk',
    'Halsizlik', 'Uyku Sorunu', 'Nefes Darlığı',
    'Öksürük', 'Çarpıntı', 'Diğer'
  ];

  // Tasarım Renkleri
  final Color primaryGreen = const Color(0xFF6BAA75);
  final Color primaryDark = const Color(0xFF2D3436);

  // Verileri Telefona Kaydetme Fonksiyonu
  Future<void> _saveSurvey() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Yeni Kayıt Objesi
    final Map<String, dynamic> newLog = {
      'date': DateTime.now().toIso8601String(),
      'painLevel': _currentPainValue.round(),
      'symptoms': _selectedSymptoms,
    };

    // Eski kayıtları çek
    List<String> logs = prefs.getStringList('logs') ?? [];
    
    // Yeni kaydı ekle (JSON string'e çevirerek)
    logs.add(jsonEncode(newLog));
    
    // Geri Kaydet
    await prefs.setStringList('logs', logs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Durumunuz kaydedildi!"),
          backgroundColor: Color(0xFF6BAA75),
          duration: Duration(seconds: 1),
        ),
      );
      // Ana Ekrana Dön (true parametresi ile dönüyoruz ki ana ekran yenilensin)
      Navigator.pop(context, true);
    }
  }

  // Ağrıya göre renk değiştiren yardımcı fonksiyon
  Color _getPainColor(double value) {
    if (value < 4) return const Color(0xFF6BAA75); // Yeşil (İyi)
    if (value < 7) return const Color(0xFFF39C12); // Turuncu (Orta)
    return const Color(0xFFFF8575); // Kırmızı (Kötü)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3436)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bugünkü Durumunuz',
          style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AĞRI SEVİYESİ KARTI
              FadeInAnimation(
                delay: 100,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                    boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ağrı Seviyenizi Değerlendirin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '0 (Ağrı yok) - 10 (En kötü ağrı)',
                        style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                      ),
                      const SizedBox(height: 30),
                      
                      // Büyük Yuvarlak Gösterge (Figma Tasarımı)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _getPainColor(_currentPainValue),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getPainColor(_currentPainValue).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${_currentPainValue.round()}',
                            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _getPainColor(_currentPainValue),
                          inactiveTrackColor: const Color(0xFFECECF0),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                          overlayColor: _getPainColor(_currentPainValue).withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _currentPainValue,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _currentPainValue.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _currentPainValue = value;
                            });
                          },
                        ),
                      ),
                      
                      // 0-10 Numaraları
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(11, (index) => Text('$index', style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // 2. BELİRTİLER (SYMPTOMS) KARTI
              FadeInAnimation(
                delay: 300,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                    boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Yaşadığınız Belirtiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                      const SizedBox(height: 8),
                      const Text('Varsa tüm belirtilerinizi seçin (opsiyonel)', style: TextStyle(color: Color(0xFF6C757D), fontSize: 14)),
                      const SizedBox(height: 24),

                      // CHIP'LER (Kutucuklar)
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: _allSymptoms.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSymptoms.remove(symptom);
                                } else {
                                  _selectedSymptoms.add(symptom);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryGreen : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? primaryGreen : Colors.black.withOpacity(0.1),
                                  width: 1.15,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                    : [const BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
                              ),
                              child: Text(
                                symptom,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryDark,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 3. KAYDET BUTONU
              FadeInAnimation(
                delay: 500,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Kaydet ve AI Tavsiyelerini Gör',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}