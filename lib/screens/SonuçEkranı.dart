import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recovery_app/screens/AnaEkran.dart';
import '../services/groq_service.dart';

class SonuEkran extends ConsumerStatefulWidget {
  final int painLevel;
  final int symptomCount;
  final bool isRisky;

  const SonuEkran({
    Key? key,
    required this.painLevel,
    required this.symptomCount,
    required this.isRisky,
  }) : super(key: key);

  @override
  ConsumerState<SonuEkran> createState() => _SonuEkranState();
}

class _SonuEkranState extends ConsumerState<SonuEkran> {
  String _aiAdvice = "Analiz ediliyor...";

  @override
  void initState() {
    super.initState();
    _getAIAdvice();
  }

  Future<void> _getAIAdvice() async {
    final prompt = "Kullanıcının ağrı seviyesi ${widget.painLevel}/10. Belirti sayısı: ${widget.symptomCount}. Durum riskli mi: ${widget.isRisky ? 'Evet' : 'Hayır'}. Buna göre 1 cümlelik özet bir değerlendirme ve 2-3 adet madde madde kısa öneri ver. Moral verici olsun.";
    try {
      final response = await ref.read(groqServiceProvider).sendMessage(prompt);
      if (mounted) {
        setState(() {
          _aiAdvice = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAdvice = "Şu anda öneri alınamadı.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🤖 AI Akıllı Rehber',
                          style: TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 24,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        SizedBox(height: 8),
                         Text(
                          'Durumunuza özel kişiselleştirilmiş öneriler',
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

                  const SizedBox(height: 24),

                  // Stats Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(0.00, 0.50),
                        end: Alignment(1.00, 0.50),
                        colors: [Color(0x196AAA74), Color(0x195DACE2)],
                      ),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1.15,
                          color: Color(0x4C6AAA74),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                           children: [
                             const Icon(Icons.show_chart, size: 20, color: Color(0xFF2D3436)),
                             const SizedBox(width: 8),
                             const Text('Ağrı seviyeniz:', style: TextStyle(color: Color(0xFF2D3436), fontSize: 14)),
                             const SizedBox(width: 4),
                             Text(
                               '${widget.painLevel}/10', 
                               style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14, fontWeight: FontWeight.bold)
                             ),
                           ],
                         ),
                         Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.5)),
                         Row(
                           children: [
                             const Text('Belirti sayısı:', style: TextStyle(color: Color(0xFF2D3436), fontSize: 14)),
                             const SizedBox(width: 4),
                             Text(
                               '${widget.symptomCount}', 
                               style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14, fontWeight: FontWeight.bold)
                             ),
                           ],
                         ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Analysis Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: ShapeDecoration(
                      color: widget.isRisky ? const Color(0x0CFF4D4D) : const Color(0x0C6BAA75),
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
                            Icon(Icons.auto_awesome, color: widget.isRisky ? Colors.red : const Color(0xFF6BAA75)),
                            const SizedBox(width: 8),
                             Text(
                               widget.isRisky ? 'Dikkat Gerektirebilir' : '✨ Mükemmel İlerleme!',
                               style: TextStyle(
                                 color: widget.isRisky ? Colors.red : const Color(0xFF6BAA75),
                                 fontSize: 16,
                                 fontFamily: 'Arial',
                                 fontWeight: FontWeight.w400,
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _aiAdvice,
                          style: const TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 16,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.62,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Home Button
                   SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => AnaEkran()), 
                          (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6BAA75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Ana Sayfaya Dön',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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
}
