import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/tls_identity.dart';

void main() {
  group('TlsIdentityService', () {
    test('generates a valid self-signed certificate and fingerprint', () {
      final service = TlsIdentityService(keySize: 1024);
      final identity = service.generate(commonName: 'Test Device');

      expect(identity.certificatePem, contains('BEGIN CERTIFICATE'));
      expect(identity.privateKeyPem, contains('BEGIN PRIVATE KEY'));
      expect(identity.fingerprint, hasLength(64));

      final cert = X509Utils.x509CertificateFromPem(identity.certificatePem);
      expect(cert.tbsCertificate, isNotNull);
      expect(cert.tbsCertificate!.subject, isNotEmpty);
      expect(
        TlsIdentityService.fingerprintOfCertificatePem(
          identity.certificatePem,
        ),
        identity.fingerprint,
      );
    });

    test('normalizes and compares fingerprints', () {
      const upper = 'AA:BB:CC:DD';
      expect(TlsIdentityService.normalizeFingerprint(upper), 'aabbccdd');
      expect(
        TlsIdentityService.fingerprintMatches(upper, 'aa bb cc dd'),
        isTrue,
      );
      expect(
        TlsIdentityService.fingerprintMatches(upper, 'aabbccde'),
        isFalse,
      );
    });
  });
}
