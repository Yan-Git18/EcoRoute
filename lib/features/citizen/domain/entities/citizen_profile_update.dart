import 'dart:typed_data';

class CitizenProfileUpdate {
  final String name;
  final String phone;
  final Uint8List? photo;

  const CitizenProfileUpdate({
    required this.name,
    required this.phone,
    this.photo,
  });

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Ingresa tu nombre.';
    if (name.length > 100) return 'Usa como máximo 100 caracteres.';
    return null;
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(digits) || phone.length > 30) {
      return 'Ingresa un número de teléfono válido.';
    }
    return null;
  }

  static const maxPhotoBytes = 5 * 1024 * 1024;

  static String? photoContentType(Uint8List bytes) {
    if (bytes.length < 12 || bytes.length > maxPhotoBytes) return null;
    if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x89 && _matches(bytes, 1, 'PNG\r\n\u001a\n')) {
      return 'image/png';
    }
    if (_matches(bytes, 0, 'RIFF') && _matches(bytes, 8, 'WEBP')) {
      return 'image/webp';
    }
    return null;
  }

  static bool _matches(Uint8List bytes, int start, String signature) {
    for (var i = 0; i < signature.length; i++) {
      if (bytes[start + i] != signature.codeUnitAt(i)) return false;
    }
    return true;
  }
}
