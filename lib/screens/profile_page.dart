import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:job_swipe/Utils/ats_helpers.dart';
import 'package:job_swipe/database/database_helper.dart';
import 'package:job_swipe/models/user_model.dart';
import 'package:job_swipe/widgets/footer_navigation_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _educationController = TextEditingController();
  final _workExperienceController = TextEditingController();
  String resumePath = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    UserProfile? profile = await DatabaseHelper().getUserProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _educationController.text = profile.education;
        _workExperienceController.text = profile.workExperience;
        resumePath = profile.resumePath;
      });
    }
  }

  ATSHelper atsHelper = ATSHelper();

  Future<void> _parseResume(File file) async {
    String? extractedText;
    if (file.path.toLowerCase().endsWith('.pdf')) {
      extractedText = await atsHelper.extractTextFromPdf(
        file.path,
      ); // Use either pdf function.
    } else if (file.path.toLowerCase().endsWith('.doc') ||
        file.path.toLowerCase().endsWith('.docx')) {
      extractedText = await atsHelper.extractTextFromWord(file.path);
    }

    if (extractedText != null) {
      String? name = await atsHelper.extractName(extractedText);
      List<String> emails = atsHelper.extractEmailAddresses(extractedText);
      String education = atsHelper.extractEducation(extractedText);
      String workExperience = atsHelper.extractWorkExperience(extractedText);

      setState(() {
        if (name != null) {
          _nameController.text = name;
        }
        if (emails.isNotEmpty) {
          _emailController.text = emails.first;
        }
        _educationController.text = education;
        _workExperienceController.text = workExperience;
        resumePath = file.path;
      });
    } else {
      // Handle error, perhaps show a message to the user
      print("Failed to extract text from the file.");
    }
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'doc', 'docx'],
      type: FileType.custom,
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _parseResume(file);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      UserProfile profile = UserProfile(
        name: _nameController.text,
        email: _emailController.text,
        education: _educationController.text,
        workExperience: _workExperienceController.text,
        resumePath: resumePath,
      );
      UserProfile? existingProfile = await DatabaseHelper().getUserProfile();
      if (existingProfile != null) {
        profile.id = existingProfile.id;
        await DatabaseHelper().updateUserProfile(profile);
      } else {
        await DatabaseHelper().insertUserProfile(profile);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile'), centerTitle: true),
      bottomNavigationBar: FooterNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickResume,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resume'),
                ),
                if (resumePath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Selected Resume: $resumePath'),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please enter your name'
                              : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please enter your email'
                              : null,
                ),
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(labelText: 'Education'),
                ),
                TextFormField(
                  controller: _workExperienceController,
                  decoration: const InputDecoration(
                    labelText: 'Work Experience',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
