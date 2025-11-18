import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iris_app/screens/home_screen.dart';
import 'package:iris_app/main.dart'; // FadeInAnimation için

class SurgeryScreen extends StatefulWidget {
  const SurgeryScreen({super.key});

  @override
  State<SurgeryScreen> createState() => _SurgeryScreenState();
}

class _SurgeryScreenState extends State<SurgeryScreen> {
  DateTime? selectedDate;
  String? selectedSurgeryType;
  final TextEditingController _otherSurgeryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final List<String> surgeryTypes = [
    'Kalça Protezi', 'Diz Protezi', 'Omuz Protezi', 'Omurga Ameliyatı', 'Karın Ameliyatı', 'Kalp Ameliyatı', 'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserName();
  }

  void _checkUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: DateTime.now(), // Bugün başlasın
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // --- DÜZELTME: GELECEK TARİH SEÇİLEMEZ ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6BAA75),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3436),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String finalSurgeryType = selectedSurgeryType!;
    if (selectedSurgeryType == 'Diğer') {
      finalSurgeryType = _otherSurgeryController.text.trim();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('surgeryType', finalSurgeryType);
      await prefs.setString('surgeryDate', selectedDate!.toIso8601String());
      await prefs.setBool('isProfileComplete', true);
      await prefs.setString('userId', user.uid);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kayıt Hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOtherSelected = selectedSurgeryType == 'Diğer';
    bool isOtherValid = !isOtherSelected || _otherSurgeryController.text.isNotEmpty;
    bool isNameValid = _nameController.text.trim().isNotEmpty;
    bool isFormValid = selectedDate != null && selectedSurgeryType != null && isOtherValid && isNameValid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Animasyonlu Başlık
                const FadeInAnimation(
                  delay: 100,
                  child: Text(
                    'Size Özel Bir Plan Oluşturalım',
                    style: TextStyle(color: Color(0xFF2D3436), fontSize: 24, fontFamily: 'Arial', fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                // Animasyonlu İsim Alanı
                FadeInAnimation(
                  delay: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Adınız Soyadınız'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: _buildBoxDecoration(),
                        child: TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: "Adınız",
                            hintStyle: TextStyle(color: Color(0xFF6C757D)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: Icon(Icons.person_outline, color: Color(0xFF6C757D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Animasyonlu Tarih Alanı
                FadeInAnimation(
                  delay: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Ameliyat Tarihiniz'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: _buildBoxDecoration(),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF6C757D), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate == null
                                    ? 'gg.aa.yyyy'
                                    : DateFormat('d MMMM yyyy', 'tr_TR').format(selectedDate!),
                                style: TextStyle(
                                  color: selectedDate == null ? const Color(0xFF6C757D) : Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Arial',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Animasyonlu Tür Alanı
                FadeInAnimation(
                  delay: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Ameliyat Türünüz'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: _buildBoxDecoration(),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSurgeryType,
                            hint: const Text('Seçiniz...', style: TextStyle(color: Color(0xFF6C757D), fontSize: 16, fontFamily: 'Arial')),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C757D)),
                            isExpanded: true,
                            items: surgeryTypes.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedSurgeryType = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isOtherSelected)
                  FadeInAnimation(
                    delay: 450,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildInputLabel('Ameliyatın Adını Yazınız'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: _buildBoxDecoration(),
                          child: TextField(
                            controller: _otherSurgeryController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: "Örn: Menisküs",
                              hintStyle: TextStyle(color: Color(0xFF6C757D)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 48),
                
                // Animasyonlu Buton
                FadeInAnimation(
                  delay: 500,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isFormValid ? _saveAndContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6BAA75),
                        disabledBackgroundColor: const Color(0xFF6BAA75).withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: isFormValid ? 4 : 0,
                      ),
                      child: const Text('Devam Et', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Arial', fontWeight: FontWeight.bold)),
                    ),
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

  Widget _buildInputLabel(String text) {
    return Text(text, style: const TextStyle(color: Color(0xFF2D3436), fontSize: 16, fontFamily: 'Arial', fontWeight: FontWeight.w500));
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black.withOpacity(0.10), width: 1.15),
      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 4, offset: Offset(0, 2))],
    );
  }
}