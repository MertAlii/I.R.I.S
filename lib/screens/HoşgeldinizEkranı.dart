import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class HoGeldinEkran extends ConsumerStatefulWidget {
  @override
  _HoGeldinEkranState createState() => _HoGeldinEkranState();
}

class _HoGeldinEkranState extends ConsumerState<HoGeldinEkran> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPolicyAccepted = false;

  void _login() async {
    if (!_validatePolicy()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      // Navigation handled by main.dart stream
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giriş başarısız: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _register() async {
    if (!_validatePolicy()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginAnon() async {
    if (!_validatePolicy()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validatePolicy() {
    if (!_isPolicyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen Gizlilik Politikası ve Kullanım Koşullarını kabul ediniz.')),
      );
      return false;
    }
    return true;
  }
  
  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
        ],
      ),
    );
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
            height: 900,
            padding: const EdgeInsets.only(top: 150, left: 32, right: 32),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 335,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İyileşme Rehberi',
                        style: TextStyle(
                          color: const Color(0xFF2D3436),
                          fontSize: 24,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'İyileşme yolculuğunuzda yanınızdayız.',
                        style: TextStyle(
                          color: const Color(0xFF6BAA75),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Input Fields
                _buildTextField("E-posta", _emailController),
                const SizedBox(height: 16),
                _buildTextField("Şifre", _passwordController, obscureText: true),
                const SizedBox(height: 32),
                
                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isPolicyAccepted,
                        activeColor: const Color(0xFF6BAA75),
                        onChanged: (val) => setState(() => _isPolicyAccepted = val!),
                        side: const BorderSide(color: Color(0xFF6C757D)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 14,
                            height: 1.4,
                            fontFamily: 'Arial',
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _showPolicyDialog("Gizlilik Politikası", "İşbu Gizlilik Politikası... (Buraya uzun metin gelecek)"),
                                child: const Text(
                                  'Gizlilik Politikası',
                                  style: TextStyle(
                                    color: Color(0xFF6BAA75),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' ve '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _showPolicyDialog("Kullanım Koşulları", "İşbu Kullanım Koşulları... (Buraya uzun metin gelecek)"),
                                child: const Text(
                                  'Kullanım Koşullarını',
                                  style: TextStyle(
                                    color: Color(0xFF6BAA75),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' okudum ve kabul ediyorum.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                _buildButton("Giriş Yap", _login, const Color(0xFF6BAA75), Colors.white),
                const SizedBox(height: 16),
                _buildButton("Kayıt Ol", _register, Colors.white, Color(0xFF6BAA75), isOutlined: true),
                const SizedBox(height: 16),
                _buildButton("Anonim Giriş", _loginAnon, Colors.grey.shade200, Colors.black87),

                // Loading indicator removed as per user request
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFFF8F9FA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF6C757D)),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, Color bgColor, Color textColor, {bool isOutlined = false}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: 337,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            side: isOutlined
                ? const BorderSide(width: 1.22, color: Color(0xFF6BAA75))
                : BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
