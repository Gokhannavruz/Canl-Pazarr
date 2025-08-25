import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String privacyPolicyUrl =
      "https://canlipazar.blogspot.com/2025/08/canlpazar-gizlilik-politikas.html";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text(
          'CanlıPazar Gizlilik Politikası',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CanlıPazar Gizlilik Politikası',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: ${DateTime.now().year}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('1. Giriş'),
                  _buildText(
                    'CanlıPazar, hayvan alım satımı platformu olarak kişisel verilerinizin güvenliğini önemsemektedir. Bu gizlilik politikası, uygulamamızı kullanırken toplanan bilgilerin nasıl kullanıldığını ve korunduğunu açıklar.',
                    isFirst: true,
                    isLast: false,
                    hasIcon: Icons.info_outline,
                    iconColor: const Color(0xFF2196F3),
                  ),
                  _buildSectionTitle('2. Toplanan Bilgiler'),
                  _buildText(
                    '• Hesap bilgileri (ad, e-posta, telefon)\n'
                    '• Konum bilgileri (size yakın ilanları göstermek için)\n'
                    '• Hayvan ilanları ve fotoğrafları\n'
                    '• Mesajlaşma içerikleri\n'
                    '• Kullanım istatistikleri ve analitik veriler',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.collections_bookmark,
                    iconColor: const Color(0xFF4CAF50),
                  ),
                  _buildSectionTitle('3. Bilgilerin Kullanım Amacı'),
                  _buildText(
                    '• Hesap oluşturma ve yönetimi\n'
                    '• Hayvan ilanlarının yayınlanması ve görüntülenmesi\n'
                    '• Kullanıcılar arası mesajlaşma\n'
                    '• Size yakın ilanların gösterilmesi\n'
                    '• Platform güvenliğinin sağlanması\n'
                    '• Hizmet kalitesinin iyileştirilmesi',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.assignment_outlined,
                    iconColor: const Color(0xFFFF9800),
                  ),
                  _buildSectionTitle('4. Bilgi Paylaşımı'),
                  _buildText(
                    'Kişisel bilgilerinizi üçüncü taraflarla paylaşmayız, ancak:\n\n'
                    '• Yasal zorunluluk durumunda\n'
                    '• Platform güvenliği için gerekli olduğunda\n'
                    '• Hizmet sağlayıcılarımızla (sadece gerekli bilgiler)\n'
                    '• Açık rızanız olduğunda',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.share_outlined,
                    iconColor: const Color(0xFF9C27B0),
                  ),
                  _buildSectionTitle('5. Veri Güvenliği'),
                  _buildText(
                    '• Tüm verileriniz şifrelenerek saklanır\n'
                    '• Güvenli sunucu altyapısı kullanılır\n'
                    '• Düzenli güvenlik güncellemeleri yapılır\n'
                    '• Erişim kontrolleri uygulanır',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.security,
                    iconColor: const Color(0xFFE91E63),
                  ),
                  _buildSectionTitle('6. Çerezler ve Takip'),
                  _buildText(
                    'Uygulamamız, deneyiminizi iyileştirmek için çerezler ve benzer teknolojiler kullanabilir. Bu teknolojiler:\n\n'
                    '• Oturum yönetimi\n'
                    '• Tercih hatırlama\n'
                    '• Analitik veriler\n'
                    '• Güvenlik kontrolleri',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.cookie_outlined,
                    iconColor: const Color(0xFF795548),
                  ),
                  _buildSectionTitle('7. Kullanıcı Hakları'),
                  _buildText(
                    'Kişisel verilerinizle ilgili şu haklara sahipsiniz:\n\n'
                    '• Verilerinize erişim\n'
                    '• Düzeltme ve güncelleme\n'
                    '• Silme talep etme\n'
                    '• İşlemeye itiraz etme\n'
                    '• Veri taşınabilirliği',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.verified_user,
                    iconColor: const Color(0xFF00BCD4),
                  ),
                  _buildSectionTitle('8. Çocukların Gizliliği'),
                  _buildText(
                    'CanlıPazar, 18 yaş altı kullanıcılardan bilerek kişisel bilgi toplamaz. Eğer 18 yaş altında olduğunuzu fark edersek, hesabınızı kapatır ve verilerinizi sileriz.',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.child_care,
                    iconColor: const Color(0xFFFF5722),
                  ),
                  _buildSectionTitle('9. Politika Değişiklikleri'),
                  _buildText(
                    'Bu gizlilik politikasını zaman zaman güncelleyebiliriz. Önemli değişiklikler olduğunda sizi bilgilendireceğiz. Güncel politika her zaman uygulamamızda mevcut olacaktır.',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.update,
                    iconColor: const Color(0xFF607D8B),
                  ),
                  _buildSectionTitle('10. İletişim'),
                  _buildText(
                    'Gizlilik politikamızla ilgili sorularınız için:\n\n'
                    '📧 E-posta: destek.canlipazar@gmail.com\n'
                    '🌐 Web: www.canlipazar.net',
                    isFirst: false,
                    isLast: true,
                    hasIcon: Icons.contact_support,
                    iconColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Browser Button
            Center(
              child: Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    const String url =
                        'https://canlipazar.blogspot.com/2025/08/canlpazar-gizlilik-politikas.html';

                    try {
                      final Uri uri = Uri.parse(url);
                      final bool canLaunch = await canLaunchUrl(uri);

                      if (canLaunch) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        // Alternatif yöntem
                        await launchUrl(
                          uri,
                          mode: LaunchMode.platformDefault,
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Bağlantı açılamadı. Lütfen internet bağlantınızı kontrol edin.'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'Tekrar Dene',
                            textColor: Colors.white,
                            onPressed: () async {
                              try {
                                final Uri uri = Uri.parse(url);
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                // Hata durumunda kullanıcıya bilgi ver
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(
                    'Gizlilik Politikasını Tarayıcıda Aç',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildText(
    String text, {
    bool isFirst = false,
    bool isLast = false,
    IconData? hasIcon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 8,
        bottom: isLast ? 0 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor?.withOpacity(0.1) ??
                    const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasIcon,
                color: iconColor ?? const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15.0,
                color: const Color(0xFF495057),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
