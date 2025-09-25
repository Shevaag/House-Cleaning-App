import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; //to handle file operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'customer_homeScreen.dart';

class JobPostingScreen extends StatefulWidget {
  @override
  _JobPostingScreenState createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen> {
  String _jobPriceStart = '';
  String _jobPriceFinal = '';
  final _formKey = GlobalKey<FormState>(); //used to validate the form
  String _selectedRoom = '1';
  String _selectedBathroom = '1';
  String _selectedFlooring = 'Tile';
  String _selectedFloors = '1';
  //String _jobPrice = ''; // Job price input
  //String _priceRange = 'Low';
  File? _image;
  DateTime? _selectedDate;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();

  // List of options for rooms, bathrooms, and flooring types
  final List<String> _roomOptions = List.generate(10, (index) => (index + 1).toString());
  final List<String> _bathroomOptions = List.generate(10, (index) => (index + 1).toString());
  final List<String> _flooringOptions = ['Tile', 'Wood', 'Carpet', 'Laminate', 'Vinyl'];
  final List<String> _floorsOptions = List.generate(10, (index) => (index + 1).toString());
  //final List<String> _priceRanges = ['Low', 'Medium', 'High'];

  // Image picker function
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); //Xfie -> file

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) { //validate the form
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        String imageUrl = '';
        if (_image != null) {
          imageUrl = await _uploadImage(File(_image!.path));
        }

        Map<String, dynamic> jobData = {
          'customerId': user.uid,
          'customerEmail': user.email,
          'name': _nameController.text,
          'address': _addressController.text,
          'mobile': _mobileController.text,
          'floors': _selectedFloors,
          'rooms': _selectedRoom,
          'bathrooms': _selectedBathroom,
          'flooringType': _selectedFlooring,
          'startPrice': _jobPriceStart,
          'finalPrice': _jobPriceFinal,
          'date': _selectedDate?.toIso8601String(), //converts to an ISO 8601 format
          'imageURL': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'open', //to track job status
        };

        await FirebaseFirestore.instance.collection('jobs').add(jobData); //saves the job

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job posted successfully!')),
        );

        // Redirect to the home screen after successful job posting
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreenBody()),
        );

        _formKey.currentState!.reset(); //clears form fields and resets the selected image.
        setState(() {
          _image = null;
        });

      } catch (e) {
        print('Error posting job: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job. Try again!')),
        );
      }
    }
  }

  // Function to upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    Reference storageReference = FirebaseStorage.instance.ref().child('job_images/${DateTime.now().millisecondsSinceEpoch}'); //creates a reference in Firebase Storage
    UploadTask uploadTask = storageReference.putFile(imageFile); //uploads
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Job', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column( //arranges vertically
              children: [
                SizedBox(height: 20),

                // Name TextField
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Address TextField
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Mobile Number TextField
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a mobile number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Dropdown for Number of Floors
                DropdownButtonFormField<String>(
                  value: _selectedFloors,
                  decoration: InputDecoration(
                    labelText: 'Number of Floors',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  items: _floorsOptions.map((String floor) { //generates a list of dropdown menu items from predefined options
                    return DropdownMenuItem<String>(
                      value: floor,
                      child: Text(floor),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFloors = newValue!; //update the state with the selected value
                    });
                  },
                  validator: (value) => value == null ? 'Please select number of floors' : null,
                ),
                SizedBox(height: 20),

                // Dropdown for Number of Rooms
                DropdownButtonFormField<String>(
                  value: _selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Number of Rooms',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  items: _roomOptions.map((String room) {
                    return DropdownMenuItem<String>(
                      value: room,
                      child: Text(room),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRoom = newValue!;
                    });
                  },
                  validator: (value) => value == null ? 'Please select number of rooms' : null,
                ),
                SizedBox(height: 20),

                // Dropdown for Number of Bathrooms
                DropdownButtonFormField<String>(
                  value: _selectedBathroom,
                  decoration: InputDecoration(
                    labelText: 'Number of Bathrooms',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  items: _bathroomOptions.map((String bathroom) {
                    return DropdownMenuItem<String>(
                      value: bathroom,
                      child: Text(bathroom),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBathroom = newValue!;
                    });
                  },
                  validator: (value) => value == null ? 'Please select number of bathrooms' : null,
                ),
                SizedBox(height: 20),

                // Dropdown for Flooring Type
                DropdownButtonFormField<String>(
                  value: _selectedFlooring,
                  decoration: InputDecoration(
                    labelText: 'Flooring Type',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  items: _flooringOptions.map((String flooring) {
                    return DropdownMenuItem<String>(
                      value: flooring,
                      child: Text(flooring),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFlooring = newValue!;
                    });
                  },
                  validator: (value) => value == null ? 'Please select flooring type' : null,
                ),
                SizedBox(height: 20),

                // Starting Amount TextField
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Starting Amount',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _jobPriceStart = value; // Save input to _jobPriceStart
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a starting price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Final Amount TextField
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Final Amount',
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _jobPriceFinal = value; // Save input to _jobPriceFinal
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a final price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Date Picker Button
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Image Picker Button
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image, color: Colors.white),
                      label: Text('Upload images of Rooms', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_image != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                  ],
                ),
                SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitJob,
                  child: Text('Post Job', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}