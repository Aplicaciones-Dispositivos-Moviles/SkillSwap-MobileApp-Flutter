// Rúbrica con la que el Verificador califica un caso (mock-up 14 "Detalle del caso").
// El backend recibe la decisión y las notas de la rúbrica como texto (máximo 2000 caracteres),
// así que la app arma ese texto con el nivel de cada criterio y el comentario.

enum RubricLevel {
  insufficient('Insuficiente'),
  basic('Básico'),
  good('Bueno'),
  excellent('Excelente');

  final String label;

  const RubricLevel(this.label);
}

class RubricCriterion {
  final String name;
  final String description;

  const RubricCriterion(this.name, this.description);
}

// Criterios según lo que el Estudiante entregó para revisión
List<RubricCriterion> rubricFor({required bool miniProject}) => miniProject
    ? const [
        RubricCriterion('Funcionamiento', 'El repositorio se ejecuta y resuelve el enunciado'),
        RubricCriterion('Uso de la habilidad', 'Aplica correctamente las técnicas del nodo'),
        RubricCriterion('Calidad del código', 'Código ordenado, legible y sin duplicación'),
        RubricCriterion('Comunicación', 'README claro con los pasos y los hallazgos'),
      ]
    : const [
        RubricCriterion('Dominio del sub-tema débil', 'Entiende el tema donde más falló'),
        RubricCriterion('Comprensión conceptual', 'Explica por qué su respuesta es o no correcta'),
        RubricCriterion('Aplicación práctica', 'Puede aplicar la habilidad en un caso real'),
      ];

const rubricNotesMaxLength = 2000;

// Texto de las notas: una línea por criterio y el comentario al final.
String buildRubricNotes(List<RubricCriterion> criteria, Map<String, RubricLevel> levels, String comment) {
  final lines = [
    for (final c in criteria)
      if (levels[c.name] != null) '${c.name}: ${levels[c.name]!.label}',
  ];
  final trimmed = comment.trim();
  if (trimmed.isNotEmpty) lines.add('Comentario: $trimmed');
  final notes = lines.join('\n');
  return notes.length <= rubricNotesMaxLength ? notes : notes.substring(0, rubricNotesMaxLength);
}

// Sugerencia de decisión: se aprueba si ningún criterio quedó en Insuficiente y la mayoría está en Bueno o más.
bool suggestsApproval(Map<String, RubricLevel> levels) {
  if (levels.isEmpty) return false;
  if (levels.values.contains(RubricLevel.insufficient)) return false;
  final strong = levels.values.where((l) => l.index >= RubricLevel.good.index).length;
  return strong * 2 >= levels.length;
}
