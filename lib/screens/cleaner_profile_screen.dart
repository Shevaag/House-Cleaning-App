import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; //provides access to the file system
import 'package:firebase_storage/firebase_storage.dart';
import 'cleaner_auth.dart';

class CleanerProfileScreen extends StatefulWidget {
  final String username;

  CleanerProfileScreen({required this.username});

  @override
  _CleanerProfileScreenState createState() => _CleanerProfileScreenState();
}

class _CleanerProfileScreenState extends State<CleanerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _profileImage; // For storing the selected profile image
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load profile data when the screen initializes
  }

  // Load profile data (name, DOB, experience, bio, and image URL) from Firestore
  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('cleaners').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? '';
          _dobController.text = userDoc['dob'] ?? '';
          _experienceController.text = userDoc['experience'] ?? '';
          _bioController.text = userDoc['bio'] ?? '';
        });
      }
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); //image will be picked from the gallery

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('cleaner_profile_images/${_auth.currentUser!.uid}');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Save profile data (name, DOB, experience, bio, and image) to Firestore
  Future<void> _saveProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String imageUrl = ''; //If no profile image is selected, the imageUrl will remain an empty string
    if (_profileImage != null) {
      imageUrl = await _uploadImage(_profileImage!);
    }

    await _firestore.collection('cleaners').doc(user.uid).set({
      'name': _nameController.text,
      'dob': _dobController.text,
      'experience': _experienceController.text,
      'bio': _bioController.text,
      'profileImage': imageUrl,
    }, SetOptions(merge: true)); //ensures that only the provided fields are updated

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  // Logout function
  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CleanerAuthScreen()),
    );
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.toLocal()}".split(' ')[0]; // Format: YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView( //scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : AssetImage('assets/default_profile.png') as ImageProvider,
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage, // Allow user to pick a profile image
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context), // Open date picker
                ),
              ),
              readOnly: true, // Prevent manual input
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Experience (e.g., 3 years)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3, // Allow multi-line input
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile, // Save profile data
              child: Text('Save Profile'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context), // Logout button
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}