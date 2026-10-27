// Formatos de texto compartidos por las pantallas.

// "python-data-science" -> "Python data science". Los casos solo traen el tag de la habilidad.
String skillLabel(String tag) {
  final words = tag.replaceAll('_', '-').split('-').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return tag;
  final text = words.join(' ');
  return text[0].toUpperCase() + text.substring(1);
}

// Tiempo que falta para el plazo de revisión: "Vence en 6 h", "Vence en 2 días" o "Vencido".
String? dueLabel(DateTime? dueAt, {DateTime? now}) {
  if (dueAt == null) return null;
  final left = dueAt.difference(now ?? DateTime.now());
  if (left.isNegative) return 'Vencido';
  if (left.inHours < 1) return 'Vence en ${left.inMinutes} min';
  if (left.inHours < 24) return 'Vence en ${left.inHours} h';
  final days = left.inDays;
  return days == 1 ? 'Vence en 1 día' : 'Vence en $days días';
}

// Fecha corta en hora local: 26/10/2026 18:40
String shortDate(DateTime? date) {
  if (date == null) return '—';
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

// yyyy-MM-dd para los parámetros from/to de las métricas
String isoDay(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

DateTime? parseDate(dynamic value) => value is String ? DateTime.tryParse(value) : null;
