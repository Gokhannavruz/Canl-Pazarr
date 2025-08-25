import 'dart:typed_data';
import 'package:animal_trade/resources/auth_methods.dart';
import 'package:animal_trade/responsive/mobile_screen_layout.dart';
import 'package:animal_trade/responsive/responsive_layout_screen.dart';
import 'package:animal_trade/responsive/web_screen_layout.dart';
import 'package:animal_trade/screens/location_picker_screen.dart';
import 'package:animal_trade/screens/terms_of_use_page.dart';
import 'package:animal_trade/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedTerms = false;
  Uint8List? _image;
  double screenHeight = 0;
  double screenWidth = 0;
  bool _obscurePassword = true;

  // Form validation error messages
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _bioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    bool isMobile = screenWidth < 600;
    bool isTablet = screenWidth >= 600 && screenWidth < 1200;
    bool isDesktop = screenWidth >= 1200;
    bool isLargeDesktop = screenWidth >= 1600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: const Color(0xFF2E7D32),
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: isMobile
                        ? 24
                        : (isTablet ? 48 : (isDesktop ? 80 : 120)),
                    right: isMobile
                        ? 24
                        : (isTablet ? 48 : (isDesktop ? 80 : 120)),
                    top: isMobile ? 20 : 40,
                  ),
                  child: _buildResponsiveLayout(
                      isMobile, isTablet, isDesktop, isLargeDesktop),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
      bool isMobile, bool isTablet, bool isDesktop, bool isLargeDesktop) {
    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildWebLayout(isLargeDesktop);
    }
  }

  Widget _buildTabletLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Card(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "CanlıPazar",
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Hayvan alım satımında güvenli pazar yeri.',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // İki sütunlu form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol sütun (form alanları)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _usernameController,
                          label: "Kullanıcı Adı",
                          hintText: "Kullanıcı adınızı girin",
                          icon: Icons.person_outline_rounded,
                          maxLength: 25,
                          errorText: _usernameError,
                        ),
                        const SizedBox(height: 32),
                        _buildInputField(
                          controller: _emailController,
                          label: "E-posta",
                          hintText: "E-posta adresinizi girin",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Sağ sütun (şifre ve koşullar)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordField(),
                        const SizedBox(height: 32),
                        _buildTermsCheckbox(),
                        const SizedBox(height: 12),
                        _buildTermsLinks(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Hesap Oluştur Butonu
              _buildCreateAccountButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout([bool isLargeDesktop = false]) {
    return Container(
      constraints: BoxConstraints(maxWidth: isLargeDesktop ? 1400 : 1200),
      child: Card(
        color: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: EdgeInsets.all(isLargeDesktop ? 56.0 : 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "CanlıPazar",
                  style: GoogleFonts.poppins(
                    fontSize: isLargeDesktop ? 56 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Hayvan alım satımında güvenli pazar yeri.',
                  style: GoogleFonts.poppins(
                    fontSize: isLargeDesktop ? 20 : 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 56),
              // İki sütunlu form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol sütun (form alanları)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _usernameController,
                          label: "Kullanıcı Adı",
                          hintText: "Kullanıcı adınızı girin",
                          icon: Icons.person_outline_rounded,
                          maxLength: 25,
                          errorText: _usernameError,
                        ),
                        const SizedBox(height: 32),
                        _buildInputField(
                          controller: _emailController,
                          label: "E-posta",
                          hintText: "E-posta adresinizi girin",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isLargeDesktop ? 64 : 48),
                  // Sağ sütun (şifre ve koşullar)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordField(),
                        const SizedBox(height: 32),
                        _buildTermsCheckbox(),
                        const SizedBox(height: 12),
                        _buildTermsLinks(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              // Hesap Oluştur Butonu
              _buildCreateAccountButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              "CanlıPazar",
              style: GoogleFonts.poppins(
                fontSize: screenWidth < 400 ? 32 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Hayvan alım satımında güvenli pazar yeri.',
              style: GoogleFonts.poppins(
                fontSize: screenWidth < 400 ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Form Alanları
          _buildInputField(
            controller: _usernameController,
            label: "Kullanıcı Adı",
            hintText: "Kullanıcı adınızı girin",
            icon: Icons.person_outline_rounded,
            maxLength: 25,
            errorText: _usernameError,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _emailController,
            label: "E-posta",
            hintText: "E-posta adresinizi girin",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 24),
          // Koşullar
          _buildTermsCheckbox(),
          const SizedBox(height: 8),
          _buildTermsLinks(),
          const SizedBox(height: 32),
          // Hesap Oluştur Butonu
          _buildCreateAccountButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.withOpacity(0.7)
                  : Colors.green,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            cursorColor: Colors.black,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null
                    ? Colors.red.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              counterText: "",
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Şifre",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _passwordError != null
                  ? Colors.red.withOpacity(0.7)
                  : Colors.green,
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            cursorColor: Colors.black,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Şifrenizi girin",
              hintStyle: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: _passwordError != null
                    ? Colors.red.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              _passwordError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        title: Text(
          "Kullanım koşullarını kabul ediyorum",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        value: _acceptedTerms,
        onChanged: (value) {
          setState(() {
            _acceptedTerms = value!;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        checkColor: Colors.white,
        activeColor: Colors.green,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTermsLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            _showTermsDialog();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            "Kullanım Şartları",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Container(
          height: 16,
          width: 1,
          color: Colors.black.withOpacity(0.3),
        ),
        TextButton(
          onPressed: () {
            _showConditionDialog();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            "Koşullar",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    bool isWebLayout = MediaQuery.of(context).size.width > 900;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                if (_acceptedTerms) {
                  signUpUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Lütfen kullanım koşullarını kabul edin",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.green.withOpacity(0.6),
              ),
              child: Text(
                "Hesap Oluştur",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  void _showConditionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CanlıPazar Gizlilik Politikası',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kişisel verilerinizin korunması',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConditionSection(
                          '1. Veri Toplama',
                          'CanlıPazar, hizmet kalitesini artırmak için şu verileri toplar:\n'
                              '• Hesap bilgileri (ad, e-posta, telefon)\n'
                              '• Konum bilgileri (yakın ilanları göstermek için)\n'
                              '• Hayvan ilanları ve fotoğrafları\n'
                              '• Mesajlaşma içerikleri\n'
                              '• Kullanım istatistikleri',
                          Icons.collections_bookmark,
                          const Color(0xFF4CAF50),
                        ),
                        _buildConditionSection(
                          '2. Veri Kullanımı',
                          'Toplanan veriler şu amaçlarla kullanılır:\n'
                              '• Hesap oluşturma ve yönetimi\n'
                              '• Hayvan ilanlarının yayınlanması\n'
                              '• Kullanıcılar arası mesajlaşma\n'
                              '• Size yakın ilanların gösterilmesi\n'
                              '• Platform güvenliğinin sağlanması',
                          Icons.assignment_outlined,
                          const Color(0xFFFF9800),
                        ),
                        _buildConditionSection(
                          '3. Veri Güvenliği',
                          'Kişisel verilerinizin güvenliği için:\n'
                              '• Güvenli sunucu altyapısı kullanılır\n'
                              '• Düzenli güvenlik güncellemeleri yapılır\n'
                              '• Erişim kontrolleri uygulanır\n'
                              '• Platform güvenliği sürekli izlenir',
                          Icons.security,
                          const Color(0xFFE91E63),
                        ),
                        _buildConditionSection(
                          '4. Veri Paylaşımı',
                          'Kişisel bilgilerinizi üçüncü taraflarla paylaşmayız, ancak:\n'
                              '• Yasal zorunluluk durumunda\n'
                              '• Platform güvenliği için gerekli olduğunda\n'
                              '• Hizmet sağlayıcılarımızla (sadece gerekli bilgiler)\n'
                              '• Açık rızanız olduğunda',
                          Icons.share_outlined,
                          const Color(0xFF9C27B0),
                        ),
                        _buildConditionSection(
                          '5. Kullanıcı Hakları',
                          'Kişisel verilerinizle ilgili şu haklara sahipsiniz:\n'
                              '• Verilerinize erişim\n'
                              '• Düzeltme ve güncelleme\n'
                              '• Silme talep etme\n'
                              '• İşlemeye itiraz etme\n'
                              '• Veri taşınabilirliği',
                          Icons.verified_user,
                          const Color(0xFF00BCD4),
                        ),
                        _buildConditionSection(
                          '6. Platform Kullanımı',
                          'CanlıPazar platformu:\n'
                              '• Oturum yönetimi için gerekli verileri saklar\n'
                              '• Kullanıcı tercihlerini hatırlar\n'
                              '• Platform performansını izler\n'
                              '• Güvenlik kontrollerini gerçekleştirir',
                          Icons.settings,
                          const Color(0xFF795548),
                        ),
                        _buildConditionSection(
                          '7. Kullanım Yaşı',
                          'CanlıPazar platformunu kullanmak için 18 yaşını doldurmuş olmanız önerilir. Platform kullanımından doğacak sorumluluklar kullanıcıya aittir.',
                          Icons.person_outline,
                          const Color(0xFFFF5722),
                        ),
                        _buildConditionSection(
                          '8. İletişim',
                          'Gizlilik politikamızla ilgili sorularınız için:\n'
                              '📧 gizlilik@canlipazar.com\n'
                              '🌐 www.canlipazar.com',
                          Icons.contact_support,
                          const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Anladım',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _buildConditionSection(
      String title, String content, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF495057),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CanlıPazar Kullanım Şartları',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hesap oluşturmadan önce lütfen okuyun',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          '1. Hizmet Tanımı',
                          'CanlıPazar, büyükbaş ve küçükbaş hayvan alım satımı için güvenli bir platform sağlar. Hizmetlerimiz hayvan ilanı yayınlama, kullanıcılar arası mesajlaşma, konum bazlı arama ve güvenli ödeme altyapısını içerir.',
                          Icons.pets,
                          const Color(0xFF795548),
                        ),
                        _buildTermsSection(
                          '2. Kullanıcı Sorumlulukları',
                          '• Doğru ve güncel bilgi sağlamalısınız\n'
                              '• Hayvan sağlığı ve refahını önemsemelisiniz\n'
                              '• Yasal düzenlemelere uymalısınız\n'
                              '• Diğer kullanıcılara saygılı olmalısınız\n'
                              '• Platform güvenliğini korumalısınız',
                          Icons.person_outline,
                          const Color(0xFF2196F3),
                        ),
                        _buildTermsSection(
                          '3. Yasaklı İçerik ve Davranışlar',
                          '• Sahte veya yanıltıcı hayvan ilanları\n'
                              '• Hasta veya sağlıksız hayvan satışı\n'
                              '• Taciz, tehdit veya saldırgan davranış\n'
                              '• Spam veya istenmeyen mesajlar\n'
                              '• Yasadışı hayvan ticareti',
                          Icons.block,
                          const Color(0xFFE91E63),
                        ),
                        _buildTermsSection(
                          '4. Hayvan Sağlığı ve Bilgilendirme',
                          '• Sadece sağlıklı hayvanlar satılabilir\n'
                              '• İlan sahibi aşı bilgilerini belirtir\n'
                              '• Veteriner belgesi zorunlu değildir\n'
                              '• Alıcı, belgelerin doğrulanmasını isteyebilir\n'
                              '• İlanın doğruluğundan satıcı sorumludur',
                          Icons.favorite,
                          const Color(0xFFFF5722),
                        ),
                        _buildTermsSection(
                          '5. İçerik Kontrolü ve Raporlama',
                          '• İlanlar yayınlandıktan sonra kontrol edilir\n'
                              '• Kullanıcı raporları değerlendirilir\n'
                              '• Yanıltıcı veya yanlış ilanlar kaldırılır\n'
                              '• Kural ihlali yapan hesaplar kapatılır\n'
                              '• Şüpheli durumlar için inceleme yapılır',
                          Icons.security,
                          const Color(0xFF607D8B),
                        ),
                        _buildTermsSection(
                          '6. Ödeme ve İşlemler',
                          '• Ödemeler uygulama üzerinden yapılmaz\n'
                              '• Kullanıcılar arası ödeme anlaşmaları\n'
                              '• CanlıPazar ödeme işlemlerinden sorumlu değildir\n'
                              '• Ödeme güvenliği tamamen kullanıcıların sorumluluğundadır\n'
                              '• Anlaşmazlık durumlarında platform müdahale etmez',
                          Icons.payment,
                          const Color(0xFF00BCD4),
                        ),
                        _buildTermsSection(
                          '7. Sorumluluk Sınırları',
                          '• CanlıPazar, kullanıcılar arası anlaşmalardan sorumlu değildir\n'
                              '• İlan içeriklerinin doğruluğundan satıcı sorumludur\n'
                              '• Hayvan sağlığı garantisi verilmez\n'
                              '• Üçüncü taraf hizmetlerden sorumlu değildir\n'
                              '• Teknik aksaklıklardan sorumlu değildir',
                          Icons.gavel,
                          const Color(0xFF795548),
                        ),
                        _buildTermsSection(
                          '8. İletişim',
                          'Sorularınız için:\n'
                              '📧 destek@canlipazar.com\n'
                              '🌐 www.canlipazar.com',
                          Icons.contact_support,
                          const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Anladım ve Kabul Ediyorum',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _buildTermsSection(
      String title, String content, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF495057),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildTextSpan(String text) {
    return TextSpan(
      text: text,
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  void signUpUser() async {
    // Önceki hata mesajlarını sıfırla
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });

    // Form alanlarını doğrula
    bool isValid = true;

    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = "Kullanıcı adı boş olamaz";
        isValid = false;
      });
    } else if (_usernameController.text.length < 3) {
      setState(() {
        _usernameError = "Kullanıcı adı en az 3 karakter olmalı";
        isValid = false;
      });
    }

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = "E-posta boş olamaz";
        isValid = false;
      });
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() {
        _emailError = "Lütfen geçerli bir e-posta adresi girin";
        isValid = false;
      });
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Şifre boş olamaz";
        isValid = false;
      });
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = "Şifre en az 6 karakter olmalı";
        isValid = false;
      });
    }

    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    // Boşlukları kaldır ve küçük harfe çevir
    String username =
        _usernameController.text.replaceAll(' ', '').toLowerCase();

    // Kullanıcıyı kaydet
    String res = await AuthMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      username: username,
      bio: _bioController.text,
      file: _image,
    );

    setState(() {
      _isLoading = false;
    });

    if (res == "success") {
      // Navigate directly to location selection (skip onboarding)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LocationPickerScreen(),
        ),
      );
    } else {
      // Firebase hata kodlarını temizle
      String cleanErrorMessage = res;

      // Firebase hata kodu deseni [firebase_auth/something] varsa kaldır
      if (res.contains(']')) {
        cleanErrorMessage = res.split(']').last.trim();
      }

      // İlk harfi büyük yap
      if (cleanErrorMessage.isNotEmpty) {
        cleanErrorMessage =
            cleanErrorMessage[0].toUpperCase() + cleanErrorMessage.substring(1);
      }

      // Hata mesajını ilgili alana göster
      if (cleanErrorMessage.toLowerCase().contains("email") ||
          res.toLowerCase().contains("email")) {
        setState(() {
          _emailError = cleanErrorMessage.replaceAll("email", "e-posta");
        });
      } else if (cleanErrorMessage.toLowerCase().contains("password") ||
          res.toLowerCase().contains("password")) {
        setState(() {
          _passwordError = cleanErrorMessage.replaceAll("password", "şifre");
        });
      } else if (cleanErrorMessage.toLowerCase().contains("username") ||
          res.toLowerCase().contains("username")) {
        setState(() {
          _usernameError =
              cleanErrorMessage.replaceAll("username", "kullanıcı adı");
        });
      } else {
        // Genel hata mesajını snackbar ile göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cleanErrorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
