import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'SonuçEkranı.dart';

class AnketEkran extends ConsumerStatefulWidget {
  @override
  _AnketEkranState createState() => _AnketEkranState();
}

class _AnketEkranState extends ConsumerState<AnketEkran> {
  double _painLevel = 0;
  // Updated symptoms list as requested
  final Map<String, bool> _symptoms = {
    'Yara Yerinde Ağrı': false,
    'Kas Ağrısı': false,
    'Eklem Ağrısı': false,
    'Şişlik': false,
    'Kızarıklık': false,
    'Akıntı': false,
    'Ateş': false,
    'Titreme': false,
    'Terleme': false,
    'Baş Ağrısı': false,
    'Mide Bulantısı': false,
    'Halsizlik': false,
    'İştahsızlık': false,
    'Uykusuzluk': false,
    'Nefes Darlığı': false, 
    'Göğüs Ağrısı': false, 
  };
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  void _saveSurvey() async {
    setState(() => _isLoading = true);
    
    try {
      final selectedSymptoms = _symptoms.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await ref.read(storageServiceProvider).saveDailySurvey(
        _painLevel.round(),
        selectedSymptoms,
        _noteController.text,
      );

      // Analyze functionality
      bool isRisky = _painLevel > 7 || 
                     _symptoms['Ateş']! || 
                     _symptoms['Akıntı']! ||
                     _symptoms['Nefes Darlığı']! ||
                     (_symptoms['Göğüs Ağrısı'] ?? false);

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SonuEkran(
            isRisky: isRisky, 
            painLevel: _painLevel.round(),
            symptomCount: selectedSymptoms.length,
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matching the background color from the provided snippet
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
               Container(
                padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 40),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cancel Button / Header
                  Row(
                    children: [
                       GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24, color: Colors.black87),
                       ),
                       const SizedBox(width: 12),
                       const Text(
                        'Bugünkü Durumunuz',
                        style: TextStyle(
                          color: Color(0xFF2D3436),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Pain Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.22,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Ağrı Seviyenizi Değerlendirin',
                          style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 20,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 8),
                         const Text(
                          '0 (Ağrı yok) - 10 (En kötü ağrı)',
                          style: TextStyle(
                            color: Color(0xFF495565),
                            fontSize: 16,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Circle Indicator
                        Container(
                          width: 80,
                          height: 80,
                          decoration: ShapeDecoration(
                            color: _getPainColor(_painLevel),
                            shape: const CircleBorder(),
                          ),
                          child: Center(
                            child: Text(
                              '${_painLevel.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF0A0A0A),
                                fontSize: 36,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                         _buildCustomSlider(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Symptoms & Note Section
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yaşadığınız Belirtiler',
                          style: TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 16,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                         const SizedBox(height: 12),
                        const Text(
                          'Tüm belirtilerinizi seçin (opsiyonel)',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 14,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _symptoms.keys.map((s) => _buildSymptomChip(s)).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Note Input
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Eklemek istediğiniz notlar...',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                            ),
                             enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                            ),
                          ),
                        ),

                         const SizedBox(height: 32),

                         SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveSurvey,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6BAA75),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ),
                          ),
                      ],
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

  Widget _buildCustomSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF030213),
            inactiveTrackColor: const Color(0xFFECECF0),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF030213).withValues(alpha: 0.1),
            trackHeight: 16,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 2),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: _painLevel,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (val) => setState(() => _painLevel = val),
          ),
        ),
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 10.0),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (index) => Text(
              '$index', 
              style: const TextStyle(
                color: Color(0xFF697282),
                fontSize: 12,
              ),
            )),
                   ),
         )
      ],
    );
  }

  Widget _buildSymptomChip(String label) {
    final isSelected = _symptoms[label] ?? false;
    return GestureDetector(
      onTap: () {
        setState(() {
          _symptoms[label] = !isSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFF6BAA75) : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1.15,
              color: isSelected ? const Color(0xFF6BAA75) :  Colors.black.withValues(alpha: 0.10),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          shadows: isSelected ? [] : const [
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2D3436),
            fontSize: 12,
            fontFamily: 'Arial',
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
      ),
    );
  }

  Color _getPainColor(double value) {
    if (value <= 3) return const Color(0xFF00C950);
    if (value <= 7) return const Color(0xFFF4C724); // Orange-ish
    return const Color(0xFFFF4D4D);
  }
}