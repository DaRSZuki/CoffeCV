import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/disease.dart';

/// Base de conocimiento local (assets/diseases.json). Funciona sin conexión.
class DiseaseRepository {
  DiseaseRepository._();
  static final instance = DiseaseRepository._();

  List<Disease>? _cache;

  Future<List<Disease>> all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/diseases.json');
    _cache = (jsonDecode(raw) as List).map((e) => Disease.fromJson(e)).toList();
    return _cache!;
  }

  Future<Disease?> byId(String id) async {
    for (final d in await all()) {
      if (d.id == id) return d;
    }
    return null;
  }
}
