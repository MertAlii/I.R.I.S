import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'AnaEkran.dart';
 // To access providers if needed trigger refresh

class AmeliyatEkran extends ConsumerStatefulWidget {
  @override
  _AmeliyatEkranState createState() => _AmeliyatEkranState();
}

class _AmeliyatEkranState extends ConsumerState<AmeliyatEkran> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedType;
  bool _isLoading = false;

  // Expanded surgery list as requested
  final List<String> _surgeryTypes = [
    'Diz Protezi',
    'Kalça Protezi',
    'Omuz Artroskopisi',
    'Ön Çapraz Bağ',
    'Menisküs',
    'Katarakt',
    'Kalp Bypass',
    'Safra Kesesi',
    'Fıtık',
    'Bademcik',
    'Burun Estetiği (Rinoplasti)',
    'Sezaryen',
    'Omurga Cerrahisi',
    'Mide Küçültme',
    'Tiroid',
    'Apendisit',
    'Lazer Göz',
    'Diş İmplantı',
    'Böbrek Taşı',
    'El Bileği',
    'Diğer'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), 
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF6BAA75),
            colorScheme: const ColorScheme.light(primary: Color(0xFF6BAA75)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveData() async {
    // If selectedType is null, try to see if user typed "Diğer" via logic? 
    // Autocomplete 'onSelected' handles setting _selectedType.
    if (_nameController.text.isEmpty || _selectedDate == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun')));
      return;
    }
    if (_selectedType == 'Diğer' && _otherTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen ameliyat türünü belirtin')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(storageServiceProvider).saveSurgeryData(
        _nameController.text.trim(),
        _selectedDate!,
        _selectedType == 'Diğer' ? _otherTypeController.text.trim() : _selectedType!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AnaEkran()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
        children: [
          Container(
            width: 399,
            height: 1000, 
            padding: const EdgeInsets.only(top: 100, left: 32, right: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                 const Text(
                  'Size Özel Bir Plan Oluşturalım',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2D3436),
                    fontSize: 16,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name Field
                _buildSectionHeader("Adınız"),
                const SizedBox(height: 8),
                _buildTextField(controller: _nameController, hint: "Adınızı giriniz"),
                const SizedBox(height: 24),

                // Date Field
                _buildSectionHeader("Ameliyat Tarihiniz"),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1.15, color: Colors.black.withValues(alpha: 0.10)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF6C757D)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null 
                              ? 'gg.aa.yyyy' 
                              : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? const Color(0xFF6C757D) : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Type Autocomplete
                _buildSectionHeader("Ameliyat Türünüz"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1.15, color: Colors.black.withValues(alpha: 0.10)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      final options = _surgeryTypes.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      }).toList();
                      
                      if (options.isEmpty) {
                        return ['Diğer'];
                      }
                      return options;
                    },
                    onSelected: (String selection) {
                      setState(() {
                         _selectedType = selection;
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Optional: Listen to controller to setup 'Diğer' logic if needed manual type
                       if (_selectedType != null && textEditingController.text != _selectedType) {
                          // Allow free typing? For now strict selection or 'Others' via selection
                          // But user said "yazarak aratalım eğer varsa altta çıksın yoksa diğer çıksın"
                          // So if no match, maybe default to "Diğer" logic? 
                          // Or let them type freely?
                       }
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Yazarak arayın...',
                          hintStyle: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      );
                    },
                  ),
                ),
                // Helper text
                if (_selectedType == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text('Aradığınız tür yoksa "Diğer" seçeneğini arayın.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),

                if (_selectedType == 'Diğer') ...[
                  const SizedBox(height: 16),
                  _buildTextField(controller: _otherTypeController, hint: "Ameliyat türünü yazınız"),
                ],

                const SizedBox(height: 48),
                
                // Save Button
                GestureDetector(
                  onTap: _isLoading ? null : _saveData,
                  child: Opacity(
                    opacity: _isLoading ? 0.7 : 1.0,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF6BAA75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Center(
                         child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Devam Et',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF2D3436),
        fontSize: 16,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.15, color: Colors.black.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6C757D)),
        ),
      ),
    );
  }
}
