import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'post_request_controller.dart';

final postRequestProvider = StateNotifierProvider<PostRequestController, bool>(
  (ref) => PostRequestController(ref),
);
