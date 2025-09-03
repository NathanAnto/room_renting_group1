import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  static const route = '/terms-of-service'; // For GoRouter navigation
  const TermsOfServiceScreen({super.key});

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
                _buildSectionTitle(context, 'Terms of Service'),
                _buildParagraph(
                  'Last updated: September 3, 2025\n\n'
                  'Please read these Terms of Service ("Terms") carefully before using the G1 mobile application (the "Service") operated by the G1 Development Team ("us", "we", or "our"). Your access to and use of the Service is conditioned on your acceptance of and compliance with these Terms.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '1. Agreement to Terms'),
                _buildParagraph(
                  'By creating an account and using the Service, you agree to be bound by these Terms. If you disagree with any part of the terms, then you may not access the Service.',
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle(context, '2. User Accounts'),
                _buildListItem('You must provide us with information that is accurate, complete, and current at all times.'),
                _buildListItem('You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.'),
                _buildListItem('You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.'),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '3. User-Generated Content'),
                _buildParagraph(
                  'Our Service allows you to post, link, store, share and otherwise make available certain information, such as property listings, text, and photographs ("Content"). You are responsible for the Content that you post to the Service, including its legality, reliability, and appropriateness.',
                ),
                _buildParagraph(
                  'By posting Content to the Service, you grant us the right and license to use, modify, publicly display, and distribute such Content on and through the Service. You retain any and all of your rights to any Content you submit.'
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '4. Prohibited Activities'),
                 _buildParagraph(
                  'You agree not to use the Service for any purpose that is illegal or prohibited by these Terms. Prohibited activities include, but are not limited to:',
                ),
                _buildListItem('Posting false, inaccurate, or misleading information.'),
                _buildListItem('Harassing, abusing, or harming another person.'),
                _buildListItem('Using the Service for any commercial purpose other than what is intended.'),
                _buildListItem('Attempting to bypass any measures of the Service designed to prevent or restrict access.'),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '5. Limitation of Liability'),
                 _buildParagraph(
                  'G1 acts as a platform to connect homeowners and students. We are not a party to any rental agreement between users. In no event shall the G1 Development Team be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(context, '6. Termination'),
                _buildParagraph(
                  'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
                ),
                 const SizedBox(height: 24),

                _buildSectionTitle(context, '7. Changes to These Terms'),
                _buildParagraph(
                  'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. We will provide notice of any changes by updating the "Last updated" date.',
                ),
                 const SizedBox(height: 24),

                _buildSectionTitle(context, '8. Contact Us'),
                _buildParagraph(
                  'If you have any questions about these Terms, please contact us:\n'
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
