import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_posting.dart';
import 'job_details_screen.dart';
import 'customer_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; //provides access to the file system
import 'package:firebase_storage/firebase_storage.dart';

class CustomerHomeScreenBody extends StatefulWidget {
  @override
  _CustomerHomeScreenBodyState createState() => _CustomerHomeScreenBodyState();
}

class _CustomerHomeScreenBodyState extends State<CustomerHomeScreenBody> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0; // Index for the selected tab

  File? _profileImage; //stores the selected profile image

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData(); // Fetch profile data when the screen loads
  }

  // Fetch profile data from Firestore
  Future<void> _fetchProfileData() async {
    User? user = _auth.currentUser; //retrieves the currently logged-in user
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get(); //access the user collection on firebase
    if (userDoc.exists) { //checks if the user has a profile stored in Firestore
      setState(() { //update the UI with the Retrieved Data
        _nameController.text = userDoc['name'] ?? ''; //if exist uses it
        _dobController.text = userDoc['dob'] ?? '';
        _mobileController.text = userDoc['mobile'] ?? '';
        _addressController.text = userDoc['address'] ?? '';
        _genderController.text = userDoc['gender'] ?? '';
        _languageController.text = userDoc['language'] ?? '';
        _emergencyContactController.text = userDoc['emergencyContact'] ?? '';
        _bioController.text = userDoc['bio'] ?? '';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOngoingJobs() async {
    User? user = _auth.currentUser; //getting the current user
    if (user == null) return [];

    QuerySnapshot querySnapshot = await _firestore
        .collection('jobs') //searches the firestore jobs collection
        .where('customerId', isEqualTo: user.uid) //fetches the jobs of the currently logged in customer
        .where('status', whereIn: ['accepted', 'finished']) //fetch ongoing and finished jobs
        .orderBy('timestamp', descending: true) //from newest to oldest
        .get();
    //Converting Firestore Data into a List
    return querySnapshot.docs.map((doc) { //extracts job data and stores it in a map
      var data = doc.data() as Map<String, dynamic>;
      data['jobId'] = doc.id; //adds the job's unique Firestore ID to the map
      return data;
    }).toList(); //converts the mapped data into a List
  }

  //submit review
  void _submitReview(String jobId, String review) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'review': review, //add the review to the job document
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker(); //allow users to select an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); //converts the XFile object to a File and stores it

    if (image != null) {
      setState(() { //refresh
        _profileImage = File(image.path);
      });
    }
  }

  // Save profile data to Firestore
  Future<void> _saveProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String imageUrl = '';
    if (_profileImage != null) {
      //upload the image to Firebase Storage and get the URL
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('customer_profile_images/${user.uid}'); //stores the image
      UploadTask uploadTask = storageReference.putFile(_profileImage!); //uploads the image
      TaskSnapshot snapshot = await uploadTask; //returns the details about the upload
      imageUrl = await snapshot.ref.getDownloadURL(); //retrieves the public URL of the uploaded image
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': _nameController.text,
      'profileImage': imageUrl,
      'dob': _dobController.text,
      'mobile': _mobileController.text,
      'address': _addressController.text,
      'gender': _genderController.text,
      'language': _languageController.text,
      'emergencyContact': _emergencyContactController.text,
      'bio': _bioController.text,
    }, SetOptions(merge: true)); //ensures existing data is not erased

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Fetch posted jobs
  Future<List<Map<String, dynamic>>> _fetchPostedJobs() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    QuerySnapshot querySnapshot = await _firestore
        .collection('jobs')
        .where('customerId', isEqualTo: user.uid) //filters jobs where customerId matches the logged-in user's ID
        .orderBy('timestamp', descending: true) //newest to oldest
        .get();

    //convert data to a list
    return querySnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>; //doc data -> map
      data['jobId'] = doc.id; // Include jobId for reference
      return data;
    }).toList(); //mapped job data -> list
  }

  // Function to delete a job
  Future<void> _deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete(); //finds the job using jobId and deletes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Refresh the job list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete job. Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) { //build method constructs the Customer Home Screen UI
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Home',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0, // Remove shadow
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildPostedJobsScreen() // Posted Jobs Screen
          : _currentIndex == 1
          ? _buildOngoingJobsScreen() // Ongoing Jobs Screen
          : _buildProfileScreen(), // Profile Screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, //keeps track of the currently active tab
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.secondary, //selected
        unselectedItemColor: Colors.grey, //unselected
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Posted Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Ongoing Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobPostingScreen(),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      )
          : null, // Show FAB only on the Posted Jobs screen
    );
  }

  // Logout function
  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CustomerAuthScreen()),
    );
  }

  //Posted Jobs screen
  Widget _buildPostedJobsScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPostedJobs(), //return a list of jobs
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); //loading button
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading jobs'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No jobs posted yet.'));
        } else {
          return ListView.builder( //used to display the jobs
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length, //list of items shld be displayed
            itemBuilder: (context, index) {
              var job = snapshot.data![index];
              return Card(
                elevation: 5, // Add shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    job['name'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  subtitle: Text(
                    'Address: ${job['address'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]), // Grey text
                  ),
                  trailing: IconButton(  //to display in a row after the text field
                    icon: Icon(Icons.delete, color: Colors.red), // Red delete icon
                    onPressed: () {
                      _deleteJob(job['jobId']);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailsScreen(
                          job: job,
                          acceptJob: (jobId, job) {}, // Placeholder for acceptJob
                          finishJob: (jobId, job) {}, // Placeholder for finishJob
                          deleteJob: _deleteJob, // Pass the deleteJob function
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  //Ongoing Jobs screen
  Widget _buildOngoingJobsScreen() {
    return Padding( //to add some space around the content
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ongoing Jobs:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchOngoingJobs(), //fetches the list of ongoing jobs
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); //loading
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading ongoing jobs'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No ongoing jobs.'));
                } else {
                  return ListView.builder( //to display jobs
                    padding: EdgeInsets.all(16),
                    itemCount: snapshot.data!.length, //defines the number of jobs in the list
                    itemBuilder: (context, index) { //builds each job card dynamically
                      var job = snapshot.data![index];
                      return Card(
                        elevation: 5, // Add shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), //
                        ),
                        child: ListTile(
                          leading: Icon(Icons.assignment, color: Theme.of(context).primaryColor),
                          title: Text(
                            job['name'] ?? 'No Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          subtitle: Text(
                            'Address: ${job['address'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: job['status'] == 'finished'
                              ? ElevatedButton(
                            onPressed: () {
                              _showReviewDialog(job['jobId']); // Show review dialog
                            },
                            child: Text('Give Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                          )
                              : null, //nothing is displayed in that space
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Show a dialog to submit a review
  void _showReviewDialog(String jobId) {
    final TextEditingController _reviewController = TextEditingController(); //to capture user input from the text field

    showDialog( //pop up dialog
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Submit Review',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          content: TextField(
            controller: _reviewController, //ensures that input text filed is saved
            decoration: InputDecoration(
              labelText: 'Enter your review',
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submitReview(jobId, _reviewController.text); // Submit the review
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  //Profile screen
  Widget _buildProfileScreen() {
    return SingleChildScrollView( //ensures scrolling
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : AssetImage('assets/default_profile.png') as ImageProvider,
            child: IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _pickImage, //to select a new image
            ),
          ),
          SizedBox(height: 20),
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
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _dobController,
            decoration: InputDecoration(
              labelText: 'Date of Birth',
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

            //opens a calender popup
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                _dobController.text = "${pickedDate.toLocal()}".split(' ')[0]; //Saves the selected date
              }
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _mobileController,
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
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
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
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _genderController.text.isEmpty ? null : _genderController.text, //when is empty, we prevent Flutter from throwing an error
            decoration: InputDecoration(
              labelText: 'Gender',
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
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value, //sets the internal value of the dropdown item
                child: Text(value), //determines what is displayed in the dropdown
              );
            }).toList(), //map -> list
            onChanged: (String? newValue) {
              setState(() {
                _genderController.text = newValue!; //saves selection
              });
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _languageController,
            decoration: InputDecoration(
              labelText: 'Preferred Language',
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
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _emergencyContactController,
            decoration: InputDecoration(
              labelText: 'Emergency Contact',
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
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: 'Bio',
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
            maxLines: 3,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveProfile,
            child: Text('Save Profile'),
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
          ElevatedButton(
            onPressed: () => _logout(context),
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}