import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_homeScreen.dart';

class CustomerAuthScreen extends StatefulWidget {
  @override
  _CustomerAuthScreenState createState() => _CustomerAuthScreenState(); //creates an instance
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> {
  final _emailController = TextEditingController(); //store user input
  final _passwordController = TextEditingController(); //store user input
  final FirebaseAuth _auth = FirebaseAuth.instance; //firebase authentication

  bool _validateInputs() {
    return _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  void _login() async {
    if (_validateInputs()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(), //removes unnecessary spaces
          password: _passwordController.text.trim(), //removes unnecessary spaces
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreenBody()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else { //if the fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _signUp() async {
    if (_validateInputs()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign Up Successful! Please log in.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign Up Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Sign In / Sign Up',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column( //vertically stacked
            mainAxisAlignment: MainAxisAlignment.center, //centered vertically
            children: [
              Text(
                'Customer Authentication Screen',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary), // Focused border color
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary), // Focused border color
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white, // White text
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white, // White text
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
    );
  }
}