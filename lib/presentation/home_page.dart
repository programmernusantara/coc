import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showProfilePopup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Selamat Datang ${widget.userData['nama']}')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ID: ${widget.userData['user_id']}'),
                Text('Asrama: ${widget.userData['asrama']}'),
                Text('Kelas: ${widget.userData['kelas']}'),
              ],
            ),
          ),
          if (_showProfilePopup) _buildProfilePopup(),
        ],
      ),
    );
  }

  Widget _buildProfilePopup() {
    return Center(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil Anda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showProfilePopup = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.userData['profil_url'] != null
                    ? NetworkImage(widget.userData['profil_url'])
                    : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
              ),
              const SizedBox(height: 20),
              _buildProfileItem('Nama', widget.userData['nama']),
              _buildProfileItem('ID', widget.userData['user_id']),
              _buildProfileItem('Asrama', widget.userData['asrama']),
              _buildProfileItem('Kelas', widget.userData['kelas']),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showProfilePopup = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
