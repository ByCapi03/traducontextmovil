/// Nombres de idioma en español, con tildes y eñe, por código ISO 639-1.
/// La app no depende del `nombre` del backend (llega sin tildes: "Ingles",
/// "Japones"); solo lo usa si el código no está en esta tabla.
const Map<String, String> nombresIdioma = {
  'af': 'Afrikáans',
  'ar': 'Árabe',
  'bg': 'Búlgaro',
  'bn': 'Bengalí',
  'ca': 'Catalán',
  'cs': 'Checo',
  'da': 'Danés',
  'de': 'Alemán',
  'el': 'Griego',
  'en': 'Inglés',
  'es': 'Español',
  'et': 'Estonio',
  'eu': 'Euskera',
  'fa': 'Persa',
  'fi': 'Finés',
  'fr': 'Francés',
  'ga': 'Irlandés',
  'gl': 'Gallego',
  'gn': 'Guaraní',
  'he': 'Hebreo',
  'hi': 'Hindi',
  'hr': 'Croata',
  'hu': 'Húngaro',
  'id': 'Indonesio',
  'it': 'Italiano',
  'ja': 'Japonés',
  'ko': 'Coreano',
  'la': 'Latín',
  'lt': 'Lituano',
  'lv': 'Letón',
  'ms': 'Malayo',
  'nl': 'Neerlandés',
  'no': 'Noruego',
  'pl': 'Polaco',
  'pt': 'Portugués',
  'qu': 'Quechua',
  'ro': 'Rumano',
  'ru': 'Ruso',
  'sk': 'Eslovaco',
  'sl': 'Esloveno',
  'sr': 'Serbio',
  'sv': 'Sueco',
  'sw': 'Suajili',
  'th': 'Tailandés',
  'tl': 'Tagalo',
  'tr': 'Turco',
  'uk': 'Ucraniano',
  'ur': 'Urdu',
  'vi': 'Vietnamita',
  'zh': 'Chino',
};

/// Nombre con tildes para [codigo] ('en', 'pt-BR', 'zh_CN'...). Si el código
/// no está en la tabla usa [respaldo] (el nombre del backend) o el código en
/// mayúsculas.
String nombreIdioma(String? codigo, {String? respaldo}) {
  final base = (codigo ?? '').trim().toLowerCase().split(RegExp('[-_]')).first;
  final propio = nombresIdioma[base];
  if (propio != null) return propio;
  if (respaldo != null && respaldo.trim().isNotEmpty) return respaldo.trim();
  return (codigo ?? '').trim().toUpperCase();
}

/// Igual que [nombreIdioma] pero null si no hay ni código ni respaldo.
String? nombreIdiomaOpcional(String? codigo, {String? respaldo}) {
  final nombre = nombreIdioma(codigo, respaldo: respaldo);
  return nombre.isEmpty ? null : nombre;
}

/// Clave para ordenar alfabéticamente sin que las tildes manden al final
/// ("Árabe" junto a "Alemán", no después de "Vietnamita").
String claveOrdenIdioma(String nombre) {
  const conTilde = 'áàäâéèëêíìïîóòöôúùüûñ';
  const sinTilde = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final letra in nombre.toLowerCase().split('')) {
    final indice = conTilde.indexOf(letra);
    buffer.write(indice < 0 ? letra : sinTilde[indice]);
  }
  return buffer.toString();
}
