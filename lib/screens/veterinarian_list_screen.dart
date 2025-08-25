import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'veterinarian_profile_screen.dart';
import 'veterinarian_detail_screen.dart';

class VeterinarianListScreen extends StatefulWidget {
  const VeterinarianListScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianListScreen> createState() => _VeterinarianListScreenState();
}

class _VeterinarianListScreenState extends State<VeterinarianListScreen> {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Veterinerler',
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Yeni veteriner profili oluşturma
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VeterinarianProfileScreen(
                    userId: 'current_user_id', // Gerçek kullanıcı ID'si
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isVeterinarian', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final veterinarians = snapshot.data?.docs ?? [];

          if (veterinarians.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz veteriner bulunmuyor',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk veteriner profili oluşturmak için + butonuna tıklayın',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: veterinarians.length,
            itemBuilder: (context, index) {
              final veterinarian =
                  veterinarians[index].data() as Map<String, dynamic>;
              final veterinarianId = veterinarians[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    veterinarian['veterinarianClinicName'] ??
                        'Veteriner Klinik',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (veterinarian['veterinarianPhone'] != null)
                        Text(
                          '📞 ${veterinarian['veterinarianPhone']}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      if (veterinarian['veterinarianCities'] != null &&
                          (veterinarian['veterinarianCities'] as List)
                              .isNotEmpty)
                        Text(
                          '📍 ${(veterinarian['veterinarianCities'] as List).join(', ')}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      if (veterinarian['veterinarianAvailable'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🟢 Müsait',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: textSecondary,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VeterinarianDetailScreen(
                          veterinarianId: veterinarianId,
                          veterinarianData: veterinarian,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
