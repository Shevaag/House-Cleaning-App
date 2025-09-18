import 'package:flutter/material.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final Function(String, Map<String, dynamic>) acceptJob;
  final Function(String, Map<String, dynamic>) finishJob;
  final Function(String) deleteJob;

  JobDetailsScreen({
    required this.job,
    required this.acceptJob,
    required this.finishJob,
    required this.deleteJob,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              deleteJob(job['jobId']); // Call deleteJob function
              Navigator.pop(context); // Go back to the job list
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display all job details
              _buildDetailItem('Job Name', job['name']), //to display each detail of the job
              _buildDetailItem('Address', job['address']),
              _buildDetailItem('Mobile Number', job['mobile']),
              _buildDetailItem('Number of Floors', job['floors']),
              _buildDetailItem('Number of Rooms', job['rooms']),
              _buildDetailItem('Number of Bathrooms', job['bathrooms']),
              _buildDetailItem('Flooring Type', job['flooringType']),
              _buildDetailItem('Starting Amount', job['startPrice']),
              _buildDetailItem('Final Amount', job['finalPrice']),
              _buildDetailItem('Date', job['date']),

              if (job['imageURL'] != null) // Display image if available
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Image.network(
                    job['imageURL'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              SizedBox(height: 20),

              if (job['status'] == 'open')
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      acceptJob(job['jobId'], job); // Accept the job
                      Navigator.pop(context); // Go back to the job list
                    },
                    child: Text('Accept Job'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 5),
          Text(
            value ?? 'N/A',
            style: TextStyle(fontSize: 16),
          ),
          Divider(), //creates a horizontal line that separates the items
        ],
      ),
    );
  }
}