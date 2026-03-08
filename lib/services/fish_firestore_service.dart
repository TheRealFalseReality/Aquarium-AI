import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Firestore data structure for fish compatibility data
// ---------------------------------------------------------------------------
//
// Collection: fish_compat
//   Document:  freshwater
//     Sub-collection: fish
//       Document per fish (keyed by UUID or auto-ID)
//   Document:  marine
//     Sub-collection: fish
//       Document per fish (keyed by UUID or auto-ID)
//
// Each fish document stores the same fields as the JSON entry:
//   name        (String)
//   commonNames (Array<String>)
//   imageURL    (String)
//   reefSafe    (String | null)  — only set for marine fish
//   compatible        (Array<String>)
//   notRecommended    (Array<String>)
//   notCompatible     (Array<String>)
//   withCaution       (Array<String>)
//
// ---------------------------------------------------------------------------
// Firebase Console – Firestore Security Rules
// ---------------------------------------------------------------------------
//
// Add the following rule block to your Firestore rules so the app can read
// fish data without authentication (public read), while preventing
// unauthorised writes:
//
//   match /fish_compat/{category} {
//     allow read: if true;   // Anyone can read fish data
//     allow write: if false; // Writes only from Admin SDK / trusted code
//
//     match /fish/{fishId} {
//       allow read: if true;
//       allow write: if false;
//     }
//   }
//
// If you want to restrict reads to authenticated users instead, replace
// `if true` with `if request.auth != null`.
//
// IMPORTANT: The upload helper in this file uses the Firestore client SDK, so
// you must temporarily allow writes during the initial upload (or use the
// Firebase Admin SDK / Firebase CLI).  A practical approach for the debug
// upload is to allow writes only for authenticated users while running the
// debug build:
//
//   match /fish_compat/{category} {
//     allow read: if true;
//     allow write: if request.auth != null;  // allow during debug upload
//
//     match /fish/{fishId} {
//       allow read: if true;
//       allow write: if request.auth != null;
//     }
//   }
//
// After the initial upload you can tighten it back to `allow write: if false`.
// ---------------------------------------------------------------------------

/// Service for reading and writing fish-compatibility data to Cloud Firestore.
class FishFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Top-level collection that holds per-category documents.
  static const String _collection = 'fish_compat';

  /// Sub-collection name within each category document.
  static const String _fishSubcollection = 'fish';

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  /// Upload the bundled `assets/data/fishcompat.json` to Firestore.
  ///
  /// Each fish is written as an individual document inside
  /// `fish_compat/{category}/fish/{uuid}`.
  ///
  /// Firestore batch writes are capped at 500 operations each, so this method
  /// splits large datasets into multiple batches automatically.
  ///
  /// [onProgress] is called with the number of fish written so far and the
  /// total count so the caller can show a progress indicator.
  ///
  /// Returns the total number of fish documents written.
  static Future<int> uploadFromAsset({
    void Function(int done, int total)? onProgress,
  }) async {
    final jsonString = await rootBundle.loadString('assets/data/fishcompat.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    return _uploadJsonData(jsonData, onProgress: onProgress);
  }

  /// Upload fish data provided as a decoded JSON map to Firestore.
  ///
  /// [jsonData] must contain `freshwater` and/or `marine` keys, each holding
  /// a `List` of fish objects.
  ///
  /// Returns the total number of fish documents written.
  static Future<int> uploadJsonData(
    Map<String, dynamic> jsonData, {
    void Function(int done, int total)? onProgress,
  }) {
    return _uploadJsonData(jsonData, onProgress: onProgress);
  }

  static Future<int> _uploadJsonData(
    Map<String, dynamic> jsonData, {
    void Function(int done, int total)? onProgress,
  }) async {
    const categories = ['freshwater', 'marine'];

    // Count total fish first so we can report progress.
    int total = 0;
    for (final cat in categories) {
      final list = jsonData[cat];
      if (list is List) total += list.length;
    }

    int done = 0;
    const int batchLimit = 500;

    for (final category in categories) {
      final rawList = jsonData[category];
      if (rawList == null || rawList is! List || rawList.isEmpty) continue;

      // Create a category-level document so the collection is visible in the
      // Firebase console even before any fish sub-documents are written.
      await _firestore.collection(_collection).doc(category).set({
        'category': category,
        'count': rawList.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Write fish documents in batches of ≤500.
      WriteBatch batch = _firestore.batch();
      int opsInBatch = 0;

      for (final rawFish in rawList) {
        if (rawFish is! Map<String, dynamic>) continue;

        final uuid = rawFish['uuid'] as String?;
        final docRef = uuid != null && uuid.isNotEmpty
            ? _firestore
                .collection(_collection)
                .doc(category)
                .collection(_fishSubcollection)
                .doc(uuid)
            : _firestore
                .collection(_collection)
                .doc(category)
                .collection(_fishSubcollection)
                .doc();

        batch.set(docRef, _sanitizeFishDoc(rawFish));
        opsInBatch++;
        done++;

        if (opsInBatch >= batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          opsInBatch = 0;
        }

        onProgress?.call(done, total);
      }

      if (opsInBatch > 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        debugPrint(
          'FishFirestoreService: uploaded ${rawList.length} $category fish.',
        );
      }
    }

    return done;
  }

  /// Remove null values and ensure list fields are typed correctly.
  static Map<String, dynamic> _sanitizeFishDoc(Map<String, dynamic> raw) {
    final doc = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is List) {
        doc[entry.key] = List<dynamic>.from(value);
      } else {
        doc[entry.key] = value;
      }
    }
    return doc;
  }

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch all fish data from Firestore.
  ///
  /// Returns a map with `freshwater` and `marine` keys, each containing a list
  /// of raw fish data maps (same shape as the local JSON).
  ///
  /// Returns `null` if either category collection is empty (indicating that the
  /// data has not been uploaded yet) or if a Firestore error occurs.
  static Future<Map<String, List<Map<String, dynamic>>>?> fetchFishData() async {
    try {
      const categories = ['freshwater', 'marine'];
      final result = <String, List<Map<String, dynamic>>>{};

      for (final category in categories) {
        final snapshot = await _firestore
            .collection(_collection)
            .doc(category)
            .collection(_fishSubcollection)
            .get();

        if (snapshot.docs.isEmpty) {
          // No data uploaded yet for this category — abort and fall through
          // to the next data source.
          if (kDebugMode) {
            debugPrint(
              'FishFirestoreService: no $category fish found in Firestore.',
            );
          }
          return null;
        }

        result[category] =
            snapshot.docs.map((d) => d.data()).toList();
      }

      if (kDebugMode) {
        debugPrint(
          'FishFirestoreService: loaded '
          '${result['freshwater']?.length ?? 0} freshwater + '
          '${result['marine']?.length ?? 0} marine fish from Firestore.',
        );
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FishFirestoreService.fetchFishData error: $e');
      }
      return null;
    }
  }

  /// Returns a real-time stream of all fish in [category].
  ///
  /// Each emitted list contains the raw document data maps (same shape as the
  /// local JSON entries).
  static Stream<List<Map<String, dynamic>>> fishStream(String category) {
    return _firestore
        .collection(_collection)
        .doc(category)
        .collection(_fishSubcollection)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
