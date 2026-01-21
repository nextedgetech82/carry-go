import 'dart:io';

import 'package:carrygo/ui/screens/chat/full_multiimage_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      /// 🔥 CREATE POST BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context),
        icon: const Icon(Icons.edit),
        label: const Text('Post'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feeds')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const _EmptyFeedState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final data = snap.data!.docs[i].data() as Map<String, dynamic>;
              return _FeedPostCard(postId: snap.data!.docs[i].id, data: data);
            },
          );
        },
      ),
    );
  }

  /// ================= CREATE POST (MULTI IMAGE) =================

  void _showCreatePostSheet(BuildContext context) {
    final ctrl = TextEditingController();

    final List<File> selectedImages = [];
    File? selectedVideo;

    bool posting = false;

    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool hasImages = selectedImages.isNotEmpty;
            bool hasVideo = selectedVideo != null;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 📝 TEXT
                    TextField(
                      controller: ctrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Share your experience…',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🖼 IMAGE PREVIEW (MULTI)
                    if (hasImages)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          itemBuilder: (_, i) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImages[i],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedImages.removeAt(i);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    /// 🎥 VIDEO PREVIEW
                    if (hasVideo)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedVideo = null;
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    /// 📸 IMAGE + 🎥 VIDEO PICKERS
                    Wrap(
                      spacing: 8,
                      children: [
                        /// IMAGE CAMERA
                        TextButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Image'),
                          onPressed: hasVideo
                              ? null
                              : () async {
                                  final picked = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                    maxWidth: 1200,
                                  );
                                  if (picked != null &&
                                      selectedImages.length < 5) {
                                    setState(() {
                                      selectedImages.add(File(picked.path));
                                    });
                                  }
                                },
                        ),

                        /// IMAGE GALLERY (MULTI)
                        TextButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          onPressed: hasVideo
                              ? null
                              : () async {
                                  final picked = await picker.pickMultiImage(
                                    imageQuality: 80,
                                    maxWidth: 1200,
                                  );
                                  if (picked.isNotEmpty) {
                                    setState(() {
                                      selectedImages.addAll(
                                        picked
                                            .take(5 - selectedImages.length)
                                            .map((e) => File(e.path)),
                                      );
                                    });
                                  }
                                },
                        ),

                        /// VIDEO CAMERA
                        TextButton.icon(
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video'),
                          onPressed: hasImages
                              ? null
                              : () async {
                                  final picked = await picker.pickVideo(
                                    source: ImageSource.camera,
                                    maxDuration: const Duration(minutes: 2),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedVideo = File(picked.path);
                                    });
                                  }
                                },
                        ),

                        /// VIDEO GALLERY
                        TextButton.icon(
                          icon: const Icon(Icons.video_library),
                          label: const Text('Video Gallery'),
                          onPressed: hasImages
                              ? null
                              : () async {
                                  final picked = await picker.pickVideo(
                                    source: ImageSource.gallery,
                                    maxDuration: const Duration(minutes: 2),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedVideo = File(picked.path);
                                    });
                                  }
                                },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 🚀 POST
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: posting
                            ? null
                            : () async {
                                if (ctrl.text.trim().isEmpty &&
                                    !hasImages &&
                                    !hasVideo)
                                  return;

                                setState(() => posting = true);

                                final user = FirebaseAuth.instance.currentUser!;
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get();

                                final u = userDoc.data() ?? {};

                                final List<String> imageUrls = [];
                                String videoUrl = '';

                                /// 🔥 UPLOAD IMAGES
                                for (final img in selectedImages) {
                                  final ref = FirebaseStorage.instance.ref(
                                    'feed_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  );
                                  await ref.putFile(img);
                                  imageUrls.add(await ref.getDownloadURL());
                                }

                                /// 🔥 UPLOAD VIDEO
                                if (selectedVideo != null) {
                                  final ref = FirebaseStorage.instance.ref(
                                    'feed_videos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4',
                                  );
                                  await ref.putFile(selectedVideo!);
                                  videoUrl = await ref.getDownloadURL();
                                }

                                /// 🔥 SAVE POST (RULE SAFE)
                                final Map<String, dynamic> payload = {
                                  'uid': user.uid,
                                  'role': u['role'],
                                  'displayName':
                                      '${u['firstName']} ${u['lastName']}',
                                  'avatarUrl': '',
                                  'text': ctrl.text.trim(),
                                  'likes': 0,
                                  'likedBy': [],
                                  'createdAt': FieldValue.serverTimestamp(),
                                };

                                if (imageUrls.isNotEmpty) {
                                  payload['imageUrls'] =
                                      imageUrls; // ✅ ONLY images
                                }

                                if (videoUrl.isNotEmpty) {
                                  payload['videoUrl'] =
                                      videoUrl; // ✅ ONLY video
                                }

                                await FirebaseFirestore.instance
                                    .collection('feeds')
                                    .add(payload);

                                // await FirebaseFirestore.instance
                                //     .collection('feeds')
                                //     .add({
                                //       'uid': user.uid,
                                //       'role': u['role'],
                                //       'displayName':
                                //           '${u['firstName']} ${u['lastName']}',
                                //       'avatarUrl': '',
                                //       'text': ctrl.text.trim(),
                                //       'imageUrls': imageUrls,
                                //       'videoUrl': videoUrl,
                                //       'likes': 0,
                                //       'likedBy': [],
                                //       'createdAt': FieldValue.serverTimestamp(),
                                //     });

                                Navigator.pop(context);
                              },
                        child: posting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Post'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// =======================================================
/// 🔹 FEED POST CARD
/// =======================================================

class _FeedPostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const _FeedPostCard({required this.postId, required this.data});

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Divider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CommentList(feedId: postId),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: CommentInput(feedId: postId),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final liked = likedBy.contains(uid);

    /// 🧠 MEDIA NORMALIZATION
    final String videoUrl = (data['videoUrl'] ?? '').toString();

    final List<String> imageUrls = [
      ...(data['imageUrls'] is List
          ? List<String>.from(data['imageUrls'])
          : []),
      if ((data['imageUrl'] ?? '').toString().isNotEmpty)
        data['imageUrl'].toString(),
    ];

    final bool hasVideo = videoUrl.isNotEmpty;
    final bool hasImages = imageUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👤 USER HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    (data['displayName'] ?? '?')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['displayName'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        data['role'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 📝 TEXT
            if ((data['text'] ?? '').toString().isNotEmpty)
              Text(
                data['text'],
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),

            if (hasVideo || hasImages) const SizedBox(height: 12),

            /// 🎥 VIDEO POST (PRIORITY)
            if (hasVideo) _VideoPreview(videoUrl: videoUrl),

            /// 🖼 IMAGE POST
            if (!hasVideo && hasImages) _ImageCarousel(imageUrls: imageUrls),

            const SizedBox(height: 12),

            /// ❤️ ACTION BAR
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(liked, uid),
                ),
                Text('${data['likes'] ?? 0}'),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined),
                  onPressed: () => _openComments(context),
                ),
                const Text('Comment'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feeds')
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('$count'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ❤️ LIKE TOGGLE
  Future<void> _toggleLike(bool liked, String uid) async {
    final ref = FirebaseFirestore.instance.collection('feeds').doc(postId);
    await ref.update({
      'likes': FieldValue.increment(liked ? -1 : 1),
      'likedBy': liked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }
}

class _VideoPreview extends StatelessWidget {
  final String videoUrl;
  const _VideoPreview({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenVideoPlayer(videoUrl: videoUrl),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 220, width: double.infinity, color: Colors.black),
            const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _ImageCarousel({super.key, required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        /// 🖼 IMAGE SLIDER
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) {
                final imageUrl = widget.imageUrls[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          images: widget.imageUrls,
                          initialIndex: i,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'feed_image_${imageUrl}_$i',
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, p) {
                        if (p == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        /// 🔘 DOT INDICATORS
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == i ? 8 : 6,
                  height: index == i ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// =======================================================
/// 🔹 EMPTY STATE
/// =======================================================

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.dynamic_feed, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No posts yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class CommentInput extends StatefulWidget {
  final String feedId;
  const CommentInput({super.key, required this.feedId});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final ctrl = TextEditingController();
  bool sending = false;

  Future<void> addComment({
    required String feedId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final u = userDoc.data()!;

    await FirebaseFirestore.instance
        .collection('feeds')
        .doc(feedId)
        .collection('comments')
        .add({
          'uid': user.uid,
          'displayName': '${u['firstName']} ${u['lastName']}',
          'role': u['role'],
          'avatarUrl': '',
          'text': text.trim(),
          'likes': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _send() async {
    if (ctrl.text.trim().isEmpty) return;

    setState(() => sending = true);
    await addComment(feedId: widget.feedId, text: ctrl.text);
    ctrl.clear();
    setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Write a comment…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: sending
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Icon(Icons.send),
          onPressed: sending ? null : _send,
        ),
      ],
    );
  }
}

class CommentList extends StatefulWidget {
  final String feedId;
  const CommentList({super.key, required this.feedId});

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  String? replyingToCommentId;

  Future<void> toggleCommentLike({
    required String commentId,
    required bool liked,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.increment(liked ? -1 : 1),
          'likedBy': liked
              ? FieldValue.arrayRemove([uid])
              : FieldValue.arrayUnion([uid]),
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feeds')
          .doc(widget.feedId)
          .collection('comments')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text(
            'No comments yet',
            style: TextStyle(color: Colors.grey),
          );
        }

        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final doc = snap.data!.docs[i];
            final c = doc.data() as Map<String, dynamic>;

            final uid = FirebaseAuth.instance.currentUser!.uid;
            final likedBy = List<String>.from(c['likedBy'] ?? []);
            final liked = likedBy.contains(uid);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 COMMENT ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(c['displayName'][0]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['displayName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(c['text']),
                              const SizedBox(height: 6),

                              /// ❤️ Like + Reply
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => toggleCommentLike(
                                      commentId: doc.id,
                                      liked: liked,
                                    ),
                                    child: Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 16,
                                      color: liked ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${c['likes'] ?? 0}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 16),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('feeds')
                                        .doc(widget.feedId)
                                        .collection('comments')
                                        .doc(doc.id)
                                        .collection('replies')
                                        .snapshots(),
                                    builder: (context, replySnap) {
                                      final replyCount =
                                          replySnap.data?.docs.length ?? 0;

                                      return Row(
                                        children: [
                                          /// Reply Button
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                replyingToCommentId = doc.id;
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(40, 24),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              replyCount > 0
                                                  ? 'Reply ($replyCount)'
                                                  : 'Reply',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          /// 🔹 Optional subtle badge (Instagram-style dot)
                                          if (replyCount > 0)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                replyCount.toString(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// 🔹 INLINE REPLIES (HIERARCHY)
                  ReplyList(feedId: widget.feedId, commentId: doc.id),

                  /// 🔹 INLINE REPLY INPUT
                  if (replyingToCommentId == doc.id)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 6),
                      child: ReplyInput(
                        feedId: widget.feedId,
                        commentId: doc.id,
                        onSent: () {
                          setState(() {
                            replyingToCommentId = null;
                          });
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ReplyInput extends StatefulWidget {
  final String feedId;
  final String commentId;
  final VoidCallback onSent;

  const ReplyInput({
    super.key,
    required this.feedId,
    required this.commentId,
    required this.onSent,
  });

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  final ctrl = TextEditingController();
  bool sending = false;

  Future<void> _send() async {
    if (ctrl.text.trim().isEmpty) return;

    setState(() => sending = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final u = userDoc.data()!;

    await FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('replies')
        .add({
          'uid': user.uid,
          'displayName': '${u['firstName']} ${u['lastName']}',
          'role': u['role'],
          'avatarUrl': '',
          'text': ctrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

    ctrl.clear();
    setState(() => sending = false);
  }

  void _confirmDeleteReply(
    BuildContext context,
    String feedId,
    String commentId,
    String replyId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete reply'),
                onTap: () async {
                  Navigator.pop(context);

                  await FirebaseFirestore.instance
                      .collection('feeds')
                      .doc(feedId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .doc(replyId)
                      .delete();
                },
              ),
              ListTile(
                title: const Center(child: Text('Cancel')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Write a reply…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: sending
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Icon(Icons.send),
          onPressed: sending ? null : _send,
        ),
      ],
    );
  }
}

class ReplyList extends StatelessWidget {
  final String feedId;
  final String commentId;

  const ReplyList({super.key, required this.feedId, required this.commentId});

  Future<void> _deleteReply({required String replyId}) async {
    await FirebaseFirestore.instance
        .collection('feeds')
        .doc(feedId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feeds')
          .doc(feedId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          children: snap.data!.docs.map((d) {
            final r = d.data() as Map<String, dynamic>;
            final isOwner = r['uid'] == currentUid;

            return Padding(
              padding: const EdgeInsets.only(left: 40, top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Avatar
                  CircleAvatar(radius: 12, child: Text(r['displayName'][0])),
                  const SizedBox(width: 6),

                  /// Reply bubble
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Reply text
                          Text(r['text'], style: const TextStyle(fontSize: 13)),

                          const SizedBox(height: 4),

                          /// Time + delete
                          Row(
                            children: [
                              Text(
                                timeAgo(r['createdAt']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),

                              const Spacer(),

                              /// 🗑 Delete (ONLY OWNER)
                              if (isOwner)
                                GestureDetector(
                                  onTap: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete reply?'),
                                        content: const Text(
                                          'This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (ok == true) {
                                      await _deleteReply(replyId: d.id);
                                    }
                                  },
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

String timeAgo(Timestamp? ts) {
  if (ts == null) return '';

  final now = DateTime.now();
  final date = ts.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';

  return '${date.day}/${date.month}/${date.year}';
}
