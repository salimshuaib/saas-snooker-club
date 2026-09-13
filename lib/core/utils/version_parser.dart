/// Utility for parsing and comparing semantic versions (e.g. 1.0.0+1).
class VersionParser {
  /// Compares two semantic version strings.
  /// Returns a negative integer if [v1] is less than [v2],
  /// zero if they are equal,
  /// and a positive integer if [v1] is greater than [v2].
  static int compare(String v1, String v2) {
    // Remove any build number (e.g., +1) or pre-release tags for this simple comparison
    final coreV1 = v1.split('+').first.split('-').first;
    final coreV2 = v2.split('+').first.split('-').first;

    final parts1 = coreV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = coreV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad lists with zeros so they are the same length
    final maxLength = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;
    while (parts1.length < maxLength) {
      parts1.add(0);
    }
    while (parts2.length < maxLength) {
      parts2.add(0);
    }

    for (var i = 0; i < maxLength; i++) {
      final p1 = parts1[i];
      final p2 = parts2[i];
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    // If core versions are equal, we could compare build numbers,
    // but typically core versions are sufficient for major updates.
    return 0;
  }

  /// Returns true if [currentVersion] is lower than [requiredVersion].
  static bool isLower(String currentVersion, String requiredVersion) {
    return compare(currentVersion, requiredVersion) < 0;
  }
}
