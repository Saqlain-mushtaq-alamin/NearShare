import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local TLS material advertised through mDNS.
class TlsIdentity {
  const TlsIdentity({
    required this.certificatePem,
    required this.privateKeyPem,
    required this.fingerprint,
  });

  final String certificatePem;
  final String privateKeyPem;

  /// Lowercase SHA-256 fingerprint without separators.
  final String fingerprint;

  SecurityContext createSecurityContext() {
    return SecurityContext()
      ..useCertificateChainBytes(
        Uint8List.fromList(utf8.encode(certificatePem)),
      )
      ..usePrivateKeyBytes(
        Uint8List.fromList(utf8.encode(privateKeyPem)),
      );
  }
}

/// Generates and caches a self-signed certificate for this device.
///
/// Private key material is kept in the platform secure store instead of a
/// world-readable file. The certificate fingerprint is what peers pin.
class TlsIdentityService {
  TlsIdentityService({
    FlutterSecureStorage? storage,
    this.keySize = 2048,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const String _certKey = 'nearshare_tls_certificate_v1';
  static const String _keyKey = 'nearshare_tls_private_key_v1';
  static const String _fingerprintKey = 'nearshare_tls_fingerprint_v1';

  static final TlsIdentityService instance = TlsIdentityService();

  final FlutterSecureStorage _storage;
  final int keySize;
  Future<TlsIdentity>? _future;

  Future<TlsIdentity> loadOrCreate({String commonName = 'NearShare'}) {
    return _future ??= _loadOrCreate(commonName).catchError((Object error) {
      _future = null;
      throw error;
    });
  }

  Future<TlsIdentity> _loadOrCreate(String commonName) async {
    String? cert;
    String? key;
    try {
      cert = await _storage.read(key: _certKey);
      key = await _storage.read(key: _keyKey);
    } catch (e) {
      debugPrint('[TlsIdentity] Secure storage unavailable: $e');
    }
    if (cert != null && key != null && cert.isNotEmpty && key.isNotEmpty) {
      try {
        return TlsIdentity(
          certificatePem: cert,
          privateKeyPem: key,
          fingerprint: fingerprintOfCertificatePem(cert),
        );
      } catch (e) {
        debugPrint('[TlsIdentity] Stored certificate is invalid: $e');
      }
    }

    final TlsIdentity generated = generate(commonName: commonName);
    try {
      await _storage.write(key: _certKey, value: generated.certificatePem);
      await _storage.write(key: _keyKey, value: generated.privateKeyPem);
      await _storage.write(
        key: _fingerprintKey,
        value: generated.fingerprint,
      );
    } catch (e) {
      debugPrint('[TlsIdentity] Could not persist certificate: $e');
    }
    return generated;
  }

  @visibleForTesting
  TlsIdentity generate({String commonName = 'NearShare'}) {
    final AsymmetricKeyPair<PublicKey, PrivateKey> pair =
        CryptoUtils.generateRSAKeyPair(keySize: keySize);
    final RSAPrivateKey privateKey = pair.privateKey as RSAPrivateKey;
    final RSAPublicKey publicKey = pair.publicKey as RSAPublicKey;

    final String csr = X509Utils.generateRsaCsrPem(
      <String, String>{'CN': commonName, 'O': 'NearShare'},
      privateKey,
      publicKey,
      san: const <String>['localhost'],
    );
    final String certificate = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      3650,
      sans: const <String>['localhost'],
      extKeyUsage: const <ExtendedKeyUsage>[ExtendedKeyUsage.SERVER_AUTH],
    );

    return TlsIdentity(
      certificatePem: certificate,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
      fingerprint: fingerprintOfCertificatePem(certificate),
    );
  }

  static String fingerprintOfCertificatePem(String pem) {
    final List<int> der = CryptoUtils.getBytesFromPEMString(pem);
    return sha256.convert(der).toString();
  }

  static String normalizeFingerprint(String value) {
    return value.replaceAll(':', '').replaceAll(' ', '').toLowerCase();
  }

  static bool fingerprintMatches(String presented, String expected) {
    return normalizeFingerprint(presented) == normalizeFingerprint(expected);
  }
}
