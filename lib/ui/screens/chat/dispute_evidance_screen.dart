import 'dart:io';

import 'package:carrygo/main.dart';
import 'package:carrygo/ui/screens/chat/full_image_screen.dart';
import 'package:carrygo/ui/screens/chat/pdf_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DisputeEvidenceScreen extends StatelessWidget {
  final String tripRequestId;

  const DisputeEvidenceScreen({super.key, required this.tripRequestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Evidence')),

      /// 🔹 MAIN CONTENT
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trip_requests')
            .doc(tripRequestId)
            .snapshots(),
        builder: (context, tripSnap) {
          if (tripSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!tripSnap.hasData || !tripSnap.data!.exists) {
            return const Center(child: Text('Trip not found'));
          }

          final trip = tripSnap.data!.data() as Map<String, dynamic>;
          final status = trip['status'];

          /// ❌ Not disputed → no evidence UI
          if (status != 'disputed') {
            return const Center(
              child: Text('Dispute not active for this trip'),
            );
          }

          /// 🔍 Resolve dispute from disputes collection
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('disputes')
                .where('tripRequestId', isEqualTo: tripRequestId)
                .limit(1)
                .snapshots(),
            builder: (context, disputeSnap) {
              print('tripRequestId passed to screen = $tripRequestId');

              if (!disputeSnap.hasData || disputeSnap.data!.docs.isEmpty) {
                return const Center(child: Text('Dispute record not found'));
              }

              final disputeId = disputeSnap.data!.docs.first.id;

              return Column(
                children: [
                  _DisputeInfoBanner(status: status),
                  Expanded(child: _EvidenceList(disputeId: disputeId)),
                ],
              );
            },
          );
        },
      ),

      /// 🔹 UPLOAD BUTTON (VISIBLE ONLY WHEN DISPUTED)
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('disputes')
            .where('tripRequestId', isEqualTo: tripRequestId)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }

          final disputeId = snap.data!.docs.first.id;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Evidence'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  _showEvidencePicker(context: context, disputeId: disputeId);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== PICKER =====================

  void _showEvidencePicker({
    required BuildContext context,
    required String disputeId,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Upload Evidence Proof',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, disputeId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, disputeId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Upload PDF / Bill'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(disputeId);
              },
            ),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  // ===================== IMAGE =====================

  Future<void> _pickImage(ImageSource source, String disputeId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    await _uploadEvidence(
      disputeId: disputeId,
      file: File(image.path),
      filename: image.name,
      type: 'IMAGE',
    );
  }

  // ===================== FILE =====================

  Future<void> _pickFile(String disputeId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;

    await _uploadEvidence(
      disputeId: disputeId,
      file: File(file.path!),
      filename: file.name,
      type: 'FILE',
    );
  }

  // ===================== UPLOAD =====================

  Future<void> _uploadEvidence({
    required String disputeId,
    required File file,
    required String filename,
    required String type,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final storageRef = FirebaseStorage.instance.ref(
      'disputes/$disputeId/${DateTime.now().millisecondsSinceEpoch}_$filename',
    );

    final uploadTask = storageRef.putFile(file);

    double progress = 0;

    // 🔒 Show progress dialog
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            uploadTask.snapshotEvents.listen((event) {
              if (event.totalBytes > 0) {
                progress = event.bytesTransferred / event.totalBytes;
                setState(() {});
              }
            });

            return _UploadProgressDialog(progress: progress);
          },
        );
      },
    );

    try {
      await uploadTask;

      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('disputes')
          .doc(disputeId)
          .collection('evidence')
          .add({
            'uploadedBy': uid,
            'type': type,
            'filename': filename,
            'url': url,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } finally {
      // ✅ Always close dialog (even if error occurs)
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pop();
      }
    }
  }
}

class _EvidenceList extends StatelessWidget {
  final String disputeId;

  const _EvidenceList({required this.disputeId});

  @override
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .doc(disputeId)
          .collection('evidence')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyEvidenceState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final e = snap.data!.docs[i].data() as Map<String, dynamic>;
            final isImage = e['type'] == 'IMAGE';

            return _EvidenceCard(
              isImage: isImage,
              filename: e['filename'] ?? 'Evidence',
              imageUrl: e['url'],
            );
          },
        );
      },
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final bool isImage;
  final String filename;
  final String imageUrl;

  const _EvidenceCard({
    required this.isImage,
    required this.filename,
    required this.imageUrl,
  });

  void _openPdfViewer(BuildContext context, String url, String filename) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(pdfUrl: url, filename: filename),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isImage) {
            _openImageViewer(context, imageUrl);
          } else {
            _openPdfViewer(context, imageUrl, filename);
          }
        },

        // onTap: isImage
        //     ? () => _openImageViewer(context, imageUrl)
        //     : _openPdfViewer(context, imageUrl, filename),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isImage
                    ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.blue.shade50,
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 36,
                          color: Colors.blue,
                        ),
                      ),
              ),

              const SizedBox(width: 14),

              /// Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.lock, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Evidence locked',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isImage) const Icon(Icons.zoom_in, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullImageViewer(imageUrl: url)),
    );
  }
}

class _DisputeInfoBanner extends StatelessWidget {
  final String status;

  const _DisputeInfoBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Row(
        children: const [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This order is under dispute. Uploaded evidence cannot be deleted.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvidenceState extends StatelessWidget {
  const _EmptyEvidenceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No evidence uploaded yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _UploadProgressDialog extends StatelessWidget {
  final double progress;

  const _UploadProgressDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Uploading Evidence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Text('${(progress * 100).toStringAsFixed(0)} %'),
            const SizedBox(height: 8),
            const Text('Please wait…', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
