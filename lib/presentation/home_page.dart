import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${userData['nama']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${userData['user_id']}'),
                    Text('Asrama: ${userData['asrama']}'),
                    Text('Kelas: ${userData['kelas']}'),
                    if (userData['profil_url'] != null)
                      Image.network(userData['profil_url']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tambahkan tombol-tombol game di sini
          ],
        ),
      ),
    );
  }
}
