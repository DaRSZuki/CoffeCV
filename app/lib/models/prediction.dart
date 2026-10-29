class ClassProbability {
  final String id;
  final String nombre;
  final double probabilidad;

  const ClassProbability({required this.id, required this.nombre, required this.probabilidad});

  factory ClassProbability.fromJson(Map<String, dynamic> j) =>
      ClassProbability(id: j['id'], nombre: j['nombre'], probabilidad: (j['probabilidad'] as num).toDouble());
}

class Prediction {
  final String clase;
  final String nombre;
  final double confianza;
  final bool sana;
  final bool concluyente;
  final List<ClassProbability> probabilidades;
  final double tiempoMs;

  const Prediction({
    required this.clase,
    required this.nombre,
    required this.confianza,
    required this.sana,
    required this.concluyente,
    required this.probabilidades,
    required this.tiempoMs,
  });

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
    clase: j['clase'],
    nombre: j['nombre'],
    confianza: (j['confianza'] as num).toDouble(),
    sana: j['sana'],
    concluyente: j['concluyente'],
    probabilidades: (j['probabilidades'] as List).map((e) => ClassProbability.fromJson(e)).toList(),
    tiempoMs: (j['tiempo_ms'] as num).toDouble(),
  );
}
