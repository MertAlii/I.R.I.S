import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'HoşgeldinizEkranı.dart';

class AyarlarEkran extends ConsumerStatefulWidget {
  const AyarlarEkran({super.key});

  @override
  ConsumerState<AyarlarEkran> createState() => _AyarlarEkranState();
}

class _AyarlarEkranState extends ConsumerState<AyarlarEkran> {
  bool _notificationsEnabled = true;
  int _devTapCount = 0;
  
  String _userName = 'Kullanıcı';
  String _userEmail = 'Anonim';
  String _surgeryType = 'Diğer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = ref.read(storageServiceProvider);
    final data = storage.getUserData();
    if (data != null) {
      if (mounted) {
        setState(() {
          _userName = data['name'] ?? 'Kullanıcı';
          _surgeryType = data['surgeryType'] ?? 'Diğer';
          _userEmail = 'Anonim'; 
        });
      }
    }
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _handleDevTap() {
    setState(() {
      _devTapCount++;
    });
    if (_devTapCount == 7) {
      _devTapCount = 0;
      _showDevModeDialog();
    }
  }

  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kendi Groq API anahtarınızı girin. Boş bırakırsanız varsayılan kullanılır.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'gsk_...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(storageServiceProvider).saveApiKey(controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key kaydedildi!')));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showFakeNotification() {
    // Determine the overlay context
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), // Light green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication, color: Color(0xFF43A047)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('İlaç Hatırlatıcısı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Akşam ilacınızı alma saatiniz geldi. 💊', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);

    // Remove it after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  void _showDevModeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gizli Geliştirici Modu 🕵️",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text("Sahte Bildirim Yolla"),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _showFakeNotification();
              },
            ),
            ListTile(
              leading: const Icon(Icons.key, color: Colors.blue),
              title: const Text("API Key Yönetimi"),
              subtitle: const Text("Groq API"),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _showApiKeyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Tüm Verileri Sil"),
               onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
     final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sil?'),
        content: const Text('Bu işlem geri alınamaz. Uygulama sıfırlanacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldClear == true) {
      await ref.read(storageServiceProvider).clearAllData();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HoGeldinEkran()),
          (route) => false,
        );
      }
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
              width: double.infinity,
              // Background color removed (was 0xFFFFF8F0)
              child: Container(
                width: double.infinity,
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
                child: SafeArea(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          // Header
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _handleDevTap,
                                child: const Text(
                                  'Ayarlar',
                                  style: TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 16,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Profile Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const ShapeDecoration(
                                    color: Color(0x196BAA75),
                                    shape: CircleBorder(),
                                  ),
                                  child: const Icon(Icons.person, color: Color(0xFF6BAA75)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Profilim',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          height: 1.43,
                                        ),
                                      ),
                                      Text(
                                        _userName, 
                                        style: const TextStyle(
                                          color: Color(0xFF2D3436),
                                          fontSize: 16,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                      Text(
                                        _userEmail, 
                                        style: const TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 14,
                                          fontFamily: 'Arial',
                                          height: 1.43,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Settings Options
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
                                // Surgery Type
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ameliyat Türü',
                                            style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                                          ),
                                          Text(
                                            _surgeryType,
                                            style: const TextStyle(color: Color(0xFF2D3436), fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.black.withValues(alpha: 0.10)),

                                // Daily Reminder
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Günlük Hatırlatıcı',
                                              style: TextStyle(color: Color(0xFF2D3436), fontSize: 16),
                                            ),
                                            Text(
                                              "Her gün saat 20:00'de bildirim al",
                                              style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _notificationsEnabled, 
                                        onChanged: (val) {
                                          setState(() => _notificationsEnabled = val);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(val ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı')),
                                          );
                                        }, 
                                        activeThumbColor: const Color(0xFF6BAA75),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.black.withValues(alpha: 0.10)),

                                // Privacy Policy
                                InkWell(
                                  onTap: () => _showPolicyDialog(
                                    'Gizlilik Politikası', 
                                    '''
1. Veri Toplama ve Kullanımı
I.R.I.S uygulaması, sağladığınız ameliyat verilerini, ağrı seviyelerini ve günlük notları yalnızca yerel cihazınızda saklar. Sunucularımıza verileriniz (sohbet hariç) gönderilmez.
Yapay zeka asistanı ile yapılan sohbetler, hizmetin sağlanması amacıyla Groq API sağlayıcısına iletilir ancak kimliğinizle eşleştirilmez.

2. Veri Güvenliği
Verileriniz şifrelenmiş veya sanal korumalı depolama yöntemleri ile cihazınızda tutulur. Uygulamayı sildiğinizde verileriniz kaybolur.

3. Üçüncü Taraflar
Uygulama, Google Haritalar (Overpass/OSM) gibi hizmetleri kullanır. Bu hizmetlerin kendi gizlilik politikaları geçerlidir.
                                    ''',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C757D)),
                                        SizedBox(width: 12),
                                        Text('Gizlilik Sözleşmesi', style: TextStyle(color: Color(0xFF2D3436), fontSize: 16)),
                                        Spacer(),
                                        Icon(Icons.chevron_right, color: Color(0xFF6C757D)),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: Colors.black.withValues(alpha: 0.10)),

                                // Terms of Use
                                InkWell(
                                  onTap: () => _showPolicyDialog(
                                    'Kullanım Koşulları', 
                                    '''
1. Sağlık Tavsiyesi Değildir
I.R.I.S. bir tıbbi cihaz veya doktor değildir. Sağlanan bilgiler sadece rehberlik amaçlıdır. Kesinlikle tıbbi tanı veya tedavi yerine geçmez. Acil durumlarda lütfen doktorunuza başvurun.

2. Sorumluluk Reddi
Uygulamanın kullanımı tamamen kullanıcının sorumluluğundadır. Geliştiriciler, uygulama önerilerinin uygulanmasından doğabilecek sonuçlardan sorumlu tutulamaz.

3. Hizmet Değişiklikleri
Geliştiriciler, uygulamayı güncelleme veya özellikleri değiştirme hakkını saklı tutar.
                                    ''',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.description_outlined, color: Color(0xFF6C757D)),
                                        SizedBox(width: 12),
                                        Text('Kullanım Koşulları', style: TextStyle(color: Color(0xFF2D3436), fontSize: 16)),
                                        Spacer(),
                                        Icon(Icons.chevron_right, color: Color(0xFF6C757D)),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: Colors.black.withValues(alpha: 0.10)),

                                // Developers (About)
                                InkWell(
                                  onTap: _showDevelopersDialog,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.info_outline, color: Color(0xFF6C757D)),
                                        SizedBox(width: 12),
                                        Text('Geliştiriciler & Hakkında', style: TextStyle(color: Color(0xFF2D3436), fontSize: 16)),
                                        Spacer(),
                                        Icon(Icons.chevron_right, color: Color(0xFF6C757D)),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                Divider(height: 1, color: Colors.black.withValues(alpha: 0.10)),

                                // Reset App
                                InkWell(
                                  onTap: _confirmDelete,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.delete_outline, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Uygulamayı Sıfırla', style: TextStyle(color: Colors.red, fontSize: 16)),
                                        Spacer(),
                                        Icon(Icons.chevron_right, color: Colors.red),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),


                          // Logout Text
                          GestureDetector(
                            onTap: () async {
                              await ref.read(authServiceProvider).signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => HoGeldinEkran()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const SizedBox(
                              width: double.infinity, 
                              height: 48,
                              child: Center(
                                child: Text(
                                  'Çıkış Yap',
                                  style: TextStyle(
                                    color: Color(0xFFFF8575),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),

                          GestureDetector(
                            onTap: _handleDevTap,
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'I.R.I.S. Beta (Sun)',
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      fontSize: 12,
                                      fontFamily: 'Arial',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                  ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showDevelopersDialog() {
      showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geliştiriciler',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildDevCard('Mert Ali Alkan'),
              const SizedBox(height: 12),
              _buildDevCard('Umut Türker'),
              const SizedBox(height: 12),
              _buildDevCard('Berk Talha Aslan'),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat', style: TextStyle(fontSize: 16, color: Color(0xFF6BAA75))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevCard(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.22, color: Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(16.40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.40)),
            ),
             child: const Icon(Icons.code, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 18,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Front ve Backend Geliştiricisi',
                style: TextStyle(
                  color: Color(0xFF737373),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
