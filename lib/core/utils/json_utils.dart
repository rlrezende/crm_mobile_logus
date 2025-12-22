List<dynamic> unwrapList(dynamic value) {
  if (value == null) {
    return const [];
  }
  if (value is List<dynamic>) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    final values = value[r'$values'];
    if (values is List<dynamic>) {
      return values;
    }
    final items = value['items'] ?? value['itemsDto'];
    if (items != null) {
      return unwrapList(items);
    }
  }
  return const [];
}

T? resolveEnum<T>(
  dynamic value,
  Map<String, T> map,
) {
  if (value == null) {
    return null;
  }
  final key = value.toString();
  final normalized = key.toUpperCase();
  return map[key] ?? map[normalized] ?? map[key.toLowerCase()];
}

Map<T, int> decodeEnumCounts<T>(
  dynamic value,
  Map<String, T> enumMap,
) {
  final result = <T, int>{};

  void process(dynamic key, dynamic count) {
    if (key == null) {
      return;
    }
    final enumValue = resolveEnum(key, enumMap);
    if (enumValue == null) {
      return;
    }
    final parsedCount = count is num ? count.toInt() : int.tryParse('$count');
    result[enumValue] = parsedCount ?? 0;
  }

  if (value is List<dynamic>) {
    for (final entry in value) {
      if (entry is Map<String, dynamic>) {
        process(entry['key'] ?? entry['Key'] ?? entry['0'], entry['value'] ?? entry['Value'] ?? entry['1']);
      } else if (entry is List<dynamic> && entry.length >= 2) {
        process(entry[0], entry[1]);
      }
    }
    return result;
  }

  if (value is Map<String, dynamic>) {
    if (value.containsKey(r'$values')) {
      return decodeEnumCounts(value[r'$values'], enumMap);
    }
    value.forEach((key, count) {
      if (key.startsWith(r'$')) {
        return;
      }
      process(key, count);
    });
  }

  return result;
}
