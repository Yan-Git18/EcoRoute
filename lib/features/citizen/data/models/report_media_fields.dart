import '../../../../core/services/firestore_media.dart';

abstract final class ReportMediaFields {
  static List<String> photos(Map<String, dynamic> data) {
    final paths = _strings(data['imagePaths']).map(FirestoreMedia.location);
    final legacyPhotos = _strings(data['imageUrls']);
    final nested = data['images'];
    final nestedPhotos = nested is List
        ? _strings(nested.map((entry) => entry is Map ? entry['url'] : entry))
        : const <String>[];

    return {...paths, ...nestedPhotos, ...legacyPhotos}.toList(growable: false);
  }

  static List<String> evidence(Map<String, dynamic> data) {
    final paths = _strings(data['evidenceImagePaths']).map(FirestoreMedia.location).toList();
    if (paths.isNotEmpty) return paths;
    final first = FirestoreMedia.readLocation(data['evidenceImagePath'], null);
    if (first != null) return [first];

    final legacy = _strings(data['evidenceImageUrls']).toSet();
    if (legacy.isNotEmpty) return legacy.toList(growable: false);
    return _strings([
      data['evidenceImageUrl'],
      data['evidencePhoto'],
    ]).take(1).toList(growable: false);
  }

  static Iterable<String> _strings(Object? value) => value is Iterable
      ? value.whereType<String>().where((item) => item.trim().isNotEmpty)
      : const [];
}
