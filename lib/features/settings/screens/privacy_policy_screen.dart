import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const route = '/privacy-policy'; // For GoRouter navigation
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Privacy Policy'),
                _buildParagraph(
                  'Last updated: September 3, 2025\n\n'
                  'Welcome to G1. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '1. Information We Collect'),
                _buildParagraph(
                  'We may collect information about you in a variety of ways. The information we may collect via the Application includes:',
                ),
                _buildSubTitle('Personal Data'),
                _buildListItem('Full Name, Email Address, and Password provided during registration.'),
                _buildListItem('Profile Picture, Country, Phone Number, and School/University information you provide in your user profile.'),
                _buildListItem('Property listings, including photos, descriptions, location, and price.'),

                _buildSubTitle('Facial Recognition Data'),
                _buildParagraph(
                  'For security purposes and user verification, we use facial recognition technology (DeepFace). When you upload a picture, we process it to create a facial data representation. This data is used solely to verify your identity and is stored securely. We do not use your facial data for any other purpose.'
                ),

                _buildSubTitle('Automatically Collected Information'),
                _buildListItem('We may collect data related to your device and usage of our app through Firebase Analytics to improve our services.'),
                const SizedBox(height: 24),
                
                _buildSectionTitle(context, '2. How We Use Your Information'),
                 _buildParagraph(
                  'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the Application to:',
                ),
                _buildListItem('Create and manage your account.'),
                _buildListItem('Facilitate connections between students and homeowners for room rentals.'),
                _buildListItem('Process bookings and manage rental agreements.'),
                _buildListItem('Improve the application and user experience through data analysis.'),
                _buildListItem('Ensure the security of our platform and prevent fraudulent activity.'),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '3. Disclosure of Your Information'),
                 _buildParagraph(
                  'We do not share your personal information with third parties except as described in this policy. We may share information with:',
                ),
                _buildListItem('**Firebase (Google):** Our backend services, including authentication, database (Firestore), and analytics are provided by Google\'s Firebase. Their privacy policy can be viewed on their website.'),
                _buildListItem('**Other Users:** Your profile information (name, photo) and property listings are visible to other users of the platform to facilitate rentals.'),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '4. Security of Your Information'),
                _buildParagraph(
                  'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable.',
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle(context, '5. Your Rights'),
                _buildParagraph(
                  'You have the right to access, update, or delete your personal information at any time through your profile settings or by contacting us directly.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '6. Changes to This Policy'),
                 _buildParagraph(
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date of this Privacy Policy.',
                ),
                 const SizedBox(height: 24),

                _buildSectionTitle(context, '7. Contact Us'),
                _buildParagraph(
                  'If you have questions or comments about this Privacy Policy, please contact us at:\n'
                  'G1 Development Team\n'
                  'https://github.com/NathanAnto/room_renting_group1',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
      ),
    );
  }
  
  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[800],
        height: 1.5,
      ),
    );
  }
  
  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey[800], fontSize: 15)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
