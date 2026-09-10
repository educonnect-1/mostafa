import 'package:flutter_test/flutter_test.dart';
import 'package:marwan_elgendi_academy/core/errors/app_exception.dart';
import 'package:marwan_elgendi_academy/core/utils/file_validators.dart';

void main() {
  group('UploadRules.validate', () {
    test('accepts a normal-sized image', () {
      expect(
        () => UploadRules.validate(extension: 'jpg', sizeBytes: 2 * 1024 * 1024),
        returnsNormally,
      );
    });

    test('accepts a normal-sized PDF', () {
      expect(
        () => UploadRules.validate(extension: 'pdf', sizeBytes: 5 * 1024 * 1024),
        returnsNormally,
      );
    });

    test('rejects an unsupported extension', () {
      expect(
        () => UploadRules.validate(extension: 'exe', sizeBytes: 1024),
        throwsA(isA<ValidationAppException>()),
      );
    });

    test('rejects an oversized image', () {
      expect(
        () => UploadRules.validate(
          extension: 'png',
          sizeBytes: UploadRules.maxImageBytes + 1,
        ),
        throwsA(isA<ValidationAppException>()),
      );
    });

    test('rejects an oversized document', () {
      expect(
        () => UploadRules.validate(
          extension: 'pdf',
          sizeBytes: UploadRules.maxDocumentBytes + 1,
        ),
        throwsA(isA<ValidationAppException>()),
      );
    });

    test('extension check is case-insensitive and tolerates a leading dot', () {
      expect(UploadRules.isImage('JPG'), isTrue);
      expect(UploadRules.isImage('.png'), isTrue);
      expect(UploadRules.isDocument('.PDF'), isTrue);
    });
  });
}
