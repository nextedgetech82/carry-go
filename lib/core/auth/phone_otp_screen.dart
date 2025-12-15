// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class PhoneOtpScreen_OLD extends StatefulWidget {
//   final String phone;
//   const PhoneOtpScreen({super.key, required this.phone});

//   @override
//   State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
// }

// class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
//   String verificationId = '';
//   final otpCtrl = TextEditingController();
//   bool loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _sendOtp();
//   }

//   Future<void> _sendOtp() async {
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: widget.phone,
//       verificationCompleted: (cred) async {
//         await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
//         await _markPhoneVerified();
//       },
//       verificationFailed: (e) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(e.message ?? 'OTP Failed')));
//       },
//       codeSent: (id, _) {
//         verificationId = id;
//       },
//       codeAutoRetrievalTimeout: (id) {
//         verificationId = id;
//       },
//     );
//   }

//   Future<void> _verifyOtp() async {
//     setState(() => loading = true);

//     final cred = PhoneAuthProvider.credential(
//       verificationId: verificationId,
//       smsCode: otpCtrl.text.trim(),
//     );

//     await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);

//     await _markPhoneVerified();
//   }

//   Future<void> _markPhoneVerified() async {
//     final uid = FirebaseAuth.instance.currentUser!.uid;

//     await FirebaseFirestore.instance.collection('users').doc(uid).update({
//       'phoneVerified': true,
//     });

//     Navigator.pushReplacementNamed(context, '/email-verification');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Verify Mobile')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text('OTP sent to ${widget.phone}'),
//             const SizedBox(height: 16),
//             TextField(
//               controller: otpCtrl,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'Enter OTP'),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: loading ? null : _verifyOtp,
//               child: loading
//                   ? const CircularProgressIndicator()
//                   : const Text('Verify OTP'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
