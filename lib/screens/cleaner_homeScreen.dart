import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cleaner_auth.dart';
import 'cleaner_profile_screen.dart';
import 'job_details_screen.dart';

class CleanerHomeScreen extends StatefulWidget {
  @override
  _CleanerHomeScreenState createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends State<CleanerHomeScreen> {
  int _currentIndex = 0; //Tracks which tab is selected
  List<Map<String, dynamic>> acceptedJobs = []; //Stores the list of jobs the cleaner has accepted

  Future<List<Map<String, dynamic>>> _fetchAllJobs() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'open')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> jobs = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['jobId'] = doc.id; // Ensure jobId is included
        return data;
      }).toList();

      print("Fetched Jobs for Cleaner: $jobs"); // Debugging line

      return jobs;
    } catch (e) {
      print("Error fetching jobs: $e"); // Debugging line
      return [];
    }
  }

  Future<void> _fetchAcceptedJobs() async {
    String? cleanerId = FirebaseAuth.instance.currentUser?.uid;
    if (cleanerId == null) return;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('cleanerId', isEqualTo: cleanerId) //filter jobs where the cleanerId matches the current user's ID
        .get();

    setState(() {
      acceptedJobs = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['jobId'] = doc.id; // Include jobId for reference
        return data;
      }).toList();
    });
  }

  void acceptJob(String jobId, Map<String, dynamic> job) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'accepted', //marks the job as accepted.
        'cleanerId': FirebaseAuth.instance.currentUser?.uid, // Add cleaner's ID
      });

      print("Accepted Job ID: $jobId"); // Debugging line

      _fetchAcceptedJobs(); // Refresh accepted jobs

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Job Accepted!")),
      );
    } catch (e) {
      print("Error accepting job: $e"); // Debugging line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting job.")),
      );
    }
  }

  //FinishJob method
  void finishJob(String jobId, Map<String, dynamic> job) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'finished',
      });

      _fetchAcceptedJobs(); // Refresh accepted jobs

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Job Marked as Finished!")),
      );
    } catch (e) {
      print("Error finishing job: $e"); // Debugging line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finishing job.")),
      );
    }
  }

  //DeleteJob method
  Future<void> deleteJob(String jobId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      //Retrieves the job document from Firestore using jobId
      DocumentSnapshot jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!jobDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job not found.')),
        );
        return;
      }

      var jobData = jobDoc.data() as Map<String, dynamic>; //doc -> map
      String customerId = jobData['customerId']; //Extracts the customerId who created the job

      // Only the customer who posted the job can delete it
      if (user.uid != customerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You do not have permission to delete this job.')),
        );
        return;
      }

      // Delete the job
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job deleted successfully!')),
      );

      // Refresh the job list
      if (_currentIndex == 0) {
        _fetchAllJobs(); // Refresh open jobs
      } else {
        _fetchAcceptedJobs(); // Refresh accepted jobs
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete job. Try again!')),
      );
    }
  }

  // Logout function
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CleanerAuthScreen()), // Redirect to login screen
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAcceptedJobs(); // Load accepted jobs on startup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Cleaning App', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0, // Remove shadow
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), // Logout button
            onPressed: () => _logout(context), // Call logout function
          ),
        ],
      ),
      body: _currentIndex == 0
          ? CleanerDashboardScreen(
        fetchJobs: _fetchAllJobs,
        acceptJob: acceptJob,
        finishJob: finishJob,
        deleteJob: deleteJob, // Pass the deleteJob method
      )
          : _currentIndex == 1
          ? AcceptedJobsScreen(
        acceptedJobs: acceptedJobs,
        finishJob: finishJob,
      )
          : CleanerProfileScreen(
        username: FirebaseAuth.instance.currentUser?.email ?? 'Cleaner',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job List'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Accepted Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class CleanerDashboardScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() fetchJobs; //Retrieves the list of available jobs
  final Function(String, Map<String, dynamic>) acceptJob; //Allows the cleaner to accept a job
  final Function(String, Map<String, dynamic>) finishJob; //Allows the cleaner to mark a job as finished
  final Function(String) deleteJob; //Allows the cleaner (or job owner) to delete a job

  CleanerDashboardScreen({
    required this.fetchJobs,
    required this.acceptJob,
    required this.finishJob,
    required this.deleteJob, // Add deleteJob parameter
  });

  @override
  _CleanerDashboardScreenState createState() => _CleanerDashboardScreenState();
}

class _CleanerDashboardScreenState extends State<CleanerDashboardScreen> {
  late Future<List<Map<String, dynamic>>> jobList;

  @override
  void initState() {
    super.initState();
    jobList = widget.fetchJobs(); // Fetch jobs when screen loads
  }

  void _refreshJobs() {
    setState(() {
      jobList = widget.fetchJobs(); // Refresh job list after accepting a job
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>( //listens for changes
      future: jobList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading jobs"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No jobs available."));
        } else {
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
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
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: ElevatedButton(
                    child: Text('View Details'),
                    onPressed: () {
                      // Navigate to JobDetailsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(
                            job: job,
                            acceptJob: widget.acceptJob,
                            finishJob: widget.finishJob,
                            deleteJob: widget.deleteJob, // Pass the deleteJob method
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}


class AcceptedJobsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> acceptedJobs;
  final Function(String, Map<String, dynamic>) finishJob;

  AcceptedJobsScreen({required this.acceptedJobs, required this.finishJob});

  @override
  Widget build(BuildContext context) {
    return acceptedJobs.isEmpty
        ? Center(
      child: Text(
        "No accepted jobs yet.",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: acceptedJobs.length,
      itemBuilder: (context, index) {
        var job = acceptedJobs[index];
        return Card(
          elevation: 5,
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
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: job['status'] == 'accepted'
                ? ElevatedButton(
              onPressed: () {
                finishJob(job['jobId'], job);
              },
              child: Text('Mark as Finished'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            )
                : null,
          ),
        );
      },
    );
  }
}
