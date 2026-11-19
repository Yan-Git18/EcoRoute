import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_media.dart';

final firestoreImageProvider = StreamProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, path) => FirebaseFirestore.instance
          .doc(path)
          .snapshots()
          .map((snapshot) => (snapshot.data()?['data'] as Blob?)?.bytes),
    );

class MediaImage extends StatelessWidget {
  final String? location;
  final BoxFit fit;
  final Widget placeholder;
  final Widget? loading;

  const MediaImage({
    super.key,
    required this.location,
    required this.placeholder,
    this.loading,
    this.fit = BoxFit.cover,
  });

  Widget _memory(Uint8List bytes) =>
      Image.memory(bytes, fit: fit, errorBuilder: (_, _, _) => placeholder);

  @override
  Widget build(BuildContext context) {
    final value = location?.trim();
    if (value == null || value.isEmpty) return placeholder;

    final path = FirestoreMedia.path(value);
    if (path != null) {
      return Consumer(
        builder: (context, ref, child) => ref
            .watch(firestoreImageProvider(path))
            .when(
              data: (bytes) => bytes == null ? placeholder : _memory(bytes),
              loading: () => loading ?? placeholder,
              error: (_, _) => placeholder,
            ),
      );
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: loading == null
            ? null
            : (context, child, progress) => progress == null ? child : loading!,
      );
    }
    if (value.startsWith('data:image')) {
      try {
        return _memory(UriData.parse(value).contentAsBytes());
      } on FormatException {
        return placeholder;
      }
    }
    if (!kIsWeb) {
      final file = File(value);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, _, _) => placeholder,
        );
      }
    }
    return placeholder;
  }
}
