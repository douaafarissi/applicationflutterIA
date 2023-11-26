import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: ActivityPage(),
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivityPage> {
  int _selectedIndex = 0;
  File? _image;
  List? _output;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Page'),
        centerTitle: true,
      ),
      body: Container(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(color: Colors.red),
        unselectedLabelStyle: TextStyle(color: Colors.red),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _pickImage();
          print("Take a photo!");
        },
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildActivitiesList();
    } else if (_selectedIndex == 1) {
      return _buildAddContent();
    } else {
      return _buildProfileContent();
    }
  }

  Widget _buildActivitiesList() {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedCategory,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: ['All', 'Food', 'Sport', 'Shopping'].map<DropdownMenuItem<String>>(
                (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            },
          ).toList(),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('activity').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<Map<String, dynamic>> activities = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                if (_selectedCategory != null && _selectedCategory != 'All') {
                  activities = activities
                      .where((activity) => activity['Category'] == _selectedCategory)
                      .toList();
                }

                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> activity = activities[index];
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(activity['Title'] ?? ''),
                        subtitle: Text(
                          '${activity['Location'] ?? ''} - ${activity['Price'] ?? ''} - ${activity['Number of people'] ?? ''}',
                        ),
                        leading: GestureDetector(
                          onTap: () {
                            _showDetails(activity);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            height: 150,
                            width: 150,
                            child: Image.network(
                              activity['Image'] ?? '',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddContent() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AddActivityForm(
              onUpdate: () {
                setState(() {});
              },
            ),
            SizedBox(height: 10),
            _image != null
                ? Image.file(
              _image!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            )
                : SizedBox.shrink(),
            SizedBox(height: 15),
            _output != null
                ? Text(
              'Category: ${_output![0]['label'].toString().substring(2)}',
              style: TextStyle(fontSize: 10),
            )
                : Text(
              'Category not available',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProfileForm(onUpdate: () {
          setState(() {});
        }),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        detectImage(_image!);
      });
    }
  }

  void detectImage(File image) async {
    print("Image Path: ${image.path}");
    var prediction = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _output = prediction!;
      print(_output);
    });
  }

  void _showDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(activity['Title'] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: ${activity['Location'] ?? ''}'),
                Text('Price: ${activity['Price'] ?? ''}'),
                Text(
                    'Number of people: ${activity['Number of people'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class AddActivityForm extends StatefulWidget {
  final VoidCallback onUpdate;

  const AddActivityForm({required this.onUpdate, Key? key}) : super(key: key);

  @override
  _AddActivityFormState createState() => _AddActivityFormState();
}

class _AddActivityFormState extends State<AddActivityForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _numPeopleController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  late File _imageFile;
  late String _imageUrl;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Location'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(labelText: 'Price'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the price';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _numPeopleController,
            decoration: InputDecoration(labelText: 'Number of people'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the number of people';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              _pickImage();
            },
            child: Text('Pick an image from gallery'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submitForm();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_imageFile != null) {
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('activity_images')
          .child('${DateTime.now()}.png');

      UploadTask uploadTask = ref.putFile(_imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      _imageUrl = await taskSnapshot.ref.getDownloadURL();

      if (_titleController.text.isNotEmpty &&
          _locationController.text.isNotEmpty &&
          _priceController.text.isNotEmpty) {
        await FirebaseFirestore.instance.collection('activity').add({
          'Title': _titleController.text,
          'Image': _imageUrl,
          'Location': _locationController.text,
          'Price': _priceController.text,
          'Number of people': _numPeopleController.text,
          'Category': _categoryController.text,
          'Timestamp': FieldValue.serverTimestamp(),
        });

        _titleController.clear();
        _locationController.clear();
        _priceController.clear();
        _numPeopleController.clear();
        _categoryController.clear();

        widget.onUpdate();
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }
}

class ProfileForm extends StatefulWidget {
  final VoidCallback onUpdate;

  const ProfileForm({required this.onUpdate, Key? key}) : super(key: key);

  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(labelText: 'Phone Number'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveProfile();
              }
            },
            child: Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    try {
      if (_nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneNumberController.text.isNotEmpty) {
        await FirebaseFirestore.instance.collection('profiles').add({
          'Name': _nameController.text,
          'Email': _emailController.text,
          'Phone Number': _phoneNumberController.text,
          'Timestamp': FieldValue.serverTimestamp(),
        });

        _nameController.clear();
        _emailController.clear();
        _phoneNumberController.clear();

        widget.onUpdate();
      }
    } catch (e) {
      print('Error saving profile: $e');
    }
  }
}
