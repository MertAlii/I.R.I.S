import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Veritabanı paketi
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iris_app/screens/surgery_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // --- 1. MİSAFİR GİRİŞİ ---
  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // Misafirler için veritabanı kaydı opsiyoneldir, şimdilik geçiyoruz.
      if (context.mounted) _navigateToNext(context);
    } catch (e) {
      _showError(context, "Hata: $e");
    }
  }

  // --- 2. GOOGLE GİRİŞİ ---
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Google ile gireni de veritabanına kaydedelim (veya güncelleyelim)
      if (userCred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'email': userCred.user!.email,
          'displayName': userCred.user!.displayName,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // merge: true -> Varsa üzerine yazma, güncelle
      }

      if (context.mounted) _navigateToNext(context);
    } catch (e) {
      _showError(context, "Google Giriş Hatası: $e");
    }
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );
  }

  void _navigateToNext(BuildContext context) {
    // pushReplacement yerine pushAndRemoveUntil kullanıyoruz ki geri tuşuyla tekrar giriş ekranına dönmesin
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SurgeryScreen()),
      (route) => false,
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFFF8575),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF6BAA75);
    final Color primaryDark = const Color(0xFF2D3436);
    final Color borderColor = const Color(0xFFE5E5E5);
    final Color buttonBgColor = const Color(0x4C6AAA74);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: const Color(0x19000000), blurRadius: 25, offset: const Offset(0, 20), spreadRadius: -5),
                      ],
                    ),
                    child: Center(child: Icon(Icons.health_and_safety, size: 60, color: primaryGreen)),
                  ),
                  const SizedBox(height: 48),
                  Text('İyileşme Rehberi', textAlign: TextAlign.center, style: TextStyle(color: primaryDark, fontSize: 24, fontFamily: 'Arial', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('İyileşme yolculuğunuzda yanınızdayız.', textAlign: TextAlign.center, style: TextStyle(color: primaryGreen, fontSize: 16, fontFamily: 'Arial')),
                  const SizedBox(height: 60),

                  Column(
                    children: [
                      _SocialLoginButton(
                        text: 'Google ile Devam Et',
                        assetImagePath: 'assets/images/google_logo.png',
                        bgColor: buttonBgColor,
                        borderColor: borderColor,
                        textColor: const Color(0xFF0A0A0A),
                        onPressed: () => _signInWithGoogle(context),
                      ),
                      const SizedBox(height: 16),
                      // DÜZELTME: Arka plan rengi (bgColor) buttonBgColor yapıldı
                      _SocialLoginButton(
                        text: 'E-posta ile Devam Et',
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF2D3436),
                        bgColor: buttonBgColor, // ARTIK DİĞERLERİYLE AYNI RENK
                        borderColor: borderColor,
                        textColor: const Color(0xFF0A0A0A),
                        onPressed: () => _showAuthSheet(context),
                      ),
                      const SizedBox(height: 16),
                      _SocialLoginButton(
                        text: 'Misafir Olarak Devam Et',
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF2D3436),
                        bgColor: buttonBgColor,
                        borderColor: borderColor,
                        textColor: const Color(0xFF0A0A0A),
                        onPressed: () => _signInAnonymously(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- AUTH SHEET VE KAYIT MANTIĞI ---
class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF6BAA75);

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? userCred;
      
      if (isLogin) {
        // GİRİŞ YAP
        userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // KAYIT OL
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // İsmi Auth profiline ekle
        await userCred.user?.updateDisplayName(_nameController.text.trim());

        // VERİTABANINA KAYDET (Firestore)
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SurgeryScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("İşlem Başarısız: ${e.toString().split(']').last.trim()}"),
          backgroundColor: const Color(0xFFFF8575),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kodu kısaltmak için buradaki UI kısmını öncekiyle aynı bırakıyorum,
    // Sadece _submit fonksiyonundaki Firestore eklemesini yukarıda yaptım.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 32, right: 32, top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [_buildTabButton("Giriş Yap", true), _buildTabButton("Kayıt Ol", false)]),
          ),
          const SizedBox(height: 32),
          if (!isLogin) ...[_buildTextField(controller: _nameController, label: "Ad Soyad", icon: Icons.person_outline), const SizedBox(height: 16)],
          _buildTextField(controller: _emailController, label: "E-posta", icon: Icons.email_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _passwordController, label: "Şifre", icon: Icons.lock_outline, isObscure: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Giriş Yap" : "Hesap Oluştur", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActiveState) {
    final bool isActive = isLogin == isActiveState;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = isActiveState),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(child: Text(text, style: TextStyle(color: isActive ? const Color(0xFF2D3436) : const Color(0xFF6C757D), fontWeight: isActive ? FontWeight.bold : FontWeight.w500))),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E5E5), width: 1.2)),
      child: TextField(controller: controller, obscureText: isObscure, style: const TextStyle(color: Color(0xFF2D3436)), decoration: InputDecoration(hintText: label, hintStyle: const TextStyle(color: Color(0xFF6C757D)), prefixIcon: Icon(icon, color: const Color(0xFF6C757D)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? assetImagePath;
  final Color? iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({required this.text, this.icon, this.assetImagePath, this.iconColor, required this.bgColor, required this.borderColor, required this.textColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = assetImagePath != null ? Image.asset(assetImagePath!, height: 24, width: 24) : Icon(icon, size: 24, color: iconColor);
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(width: 1.22, color: borderColor)), padding: EdgeInsets.zero),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [buttonContent, const SizedBox(width: 12), Text(text, style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'Roboto', fontWeight: FontWeight.w500))]),
      ),
    );
  }
}