/// Región por defecto de cada idioma para el reconocimiento y la síntesis de
/// voz (misma tabla que `reconocimiento-voz.service.ts` de la web): con el
/// código base ('es') algunos motores no devuelven resultados.
const Map<String, String> regionPorIdioma = {
  'es': 'es-ES',
  'en': 'en-US',
  'fr': 'fr-FR',
  'de': 'de-DE',
  'it': 'it-IT',
  'pt': 'pt-BR',
  'ja': 'ja-JP',
  'zh': 'zh-CN',
  'ko': 'ko-KR',
  'ru': 'ru-RU',
  'ar': 'ar-SA',
  'hi': 'hi-IN',
};

/// Normaliza 'es_MX' → 'es-MX'. Devuelve '' si no hay código.
String normalizarIdioma(String? codigo) => (codigo ?? '').trim().replaceAll('_', '-');

/// 'es' → la región del dispositivo que coincida (es-MX), si se conoce, o la
/// de la tabla (es-ES). Un código que ya trae región se respeta.
String resolverIdiomaVoz(String? codigo, {Iterable<String> disponibles = const []}) {
  final limpio = normalizarIdioma(codigo);
  if (limpio.isEmpty || limpio.contains('-')) return limpio;
  final base = limpio.toLowerCase();
  final porTabla = regionPorIdioma[base];
  final candidatos = [
    for (final idioma in disponibles)
      if (normalizarIdioma(idioma).toLowerCase().split('-').first == base) normalizarIdioma(idioma),
  ];
  if (candidatos.isEmpty) return porTabla ?? base;
  return candidatos.firstWhere(
    (idioma) => idioma.toLowerCase() == porTabla?.toLowerCase(),
    orElse: () => candidatos.first,
  );
}
