# CLAUDE.md — Motivador Personal (Flutter)

## ¿Qué es esto?

App móvil Flutter **solo para Android** para uso personal de una sola persona.
Sin backend, sin login, sin internet. Todo local en el dispositivo.

**Target**: Android únicamente. No configurar ni generar nada de iOS o macOS.

---

## Problema que resuelve

El usuario tiene sobrepeso, posterga todo y no se cuida.
La app lo combate con retos diarios, calendario de progreso y mensajes motivacionales BRUTALES hardcoded.
Sin IA. Sin APIs externas. Todo offline.

---

## Tech Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart) |
| Navegación | go_router |
| Storage | shared_preferences |
| Notificaciones | flutter_local_notifications |
| Íconos | Material Icons (built-in) |
| UUID | package uuid |
| Estado | StatefulWidget + setState (sin Riverpod, sin Bloc, sin Provider) |

**IMPORTANTE**: No usar arquitecturas complejas. Esta app es chica. StatefulWidget alcanza y sobra.

---

## pubspec.yaml — dependencias exactas

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^13.0.0
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^17.0.0
  uuid: ^4.3.3
```

---

## Estructura del proyecto

```
lib/
├── main.dart                        ← MaterialApp + go_router, rutas
├── data/
│   └── messages.dart                ← 100 mensajes brutales hardcoded
├── models/
│   ├── challenge.dart               ← clase Challenge con toJson/fromJson
│   └── progress_entry.dart          ← clase ProgressEntry con toJson/fromJson
├── services/
│   ├── storage_service.dart         ← singleton, SharedPreferences, todo async
│   └── notification_service.dart    ← flutter_local_notifications, schedule/cancel
├── utils/
│   └── date_utils.dart              ← helpers: todayKey(), thisMonth(), etc.
├── widgets/
│   ├── challenge_card.dart          ← tarjeta con botones COMPLETAR / POSTERGAR
│   ├── calendar_grid.dart           ← grid mensual coloreado
│   ├── progress_bar.dart            ← barra de progreso simple
│   └── brutal_message_dialog.dart   ← Dialog que muestra el mensaje brutal
└── screens/
    ├── home_screen.dart             ← retos de HOY
    ├── calendar_screen.dart         ← progreso mensual
    ├── challenges_screen.dart       ← crear/editar/borrar retos
    └── settings_screen.dart         ← notificaciones on/off, ver streak
```

---

## Modelos de datos

### Challenge
```dart
class Challenge {
  final String id;       // UUID v4
  String title;          // "Tomar 4 litros de agua"
  String emoji;          // "💧"
  int colorValue;        // 0xFF3B82F6
  String reminderTime;   // "08:00"
  bool active;
  String createdAt;      // "2026-03-25"
}
```

### ProgressEntry
```dart
class ProgressEntry {
  bool completed;
  String? completedAt;   // "10:30"
  int postponedCount;    // cuántas veces postergó hoy
}
```

---

## SharedPreferences — keys y estructura

### key: `"challenges"` → JSON array
```json
[
  {
    "id": "uuid-v4",
    "title": "Tomar 4 litros de agua",
    "emoji": "💧",
    "colorValue": 4282485750,
    "reminderTime": "08:00",
    "active": true,
    "createdAt": "2026-03-25"
  }
]
```

### key: `"progress"` → JSON map anidado
```json
{
  "2026-03-25": {
    "uuid-1": { "completed": true, "completedAt": "10:30", "postponedCount": 0 },
    "uuid-2": { "completed": false, "completedAt": null, "postponedCount": 2 }
  }
}
```

### key: `"settings"` → JSON object
```json
{
  "notificationsEnabled": true,
  "streakDays": 0
}
```

---

## Flujo principal

```
App abre → HomeScreen
  │
  ├─ Botón COMPLETAR
  │    ├─ Marca completed: true en progress
  │    ├─ Guarda hora (completedAt)
  │    ├─ Muestra BrutalMessageDialog con mensaje de brutal_positive
  │    └─ Recalcula y guarda streak
  │
  ├─ Botón POSTERGAR
  │    ├─ Incrementa postponedCount
  │    ├─ Si postponedCount >= 3 → mensaje de brutal_postpone_max
  │    ├─ Si postponedCount < 3  → mensaje de brutal_postpone
  │    ├─ Muestra BrutalMessageDialog
  │    └─ Reagenda notificación +2 horas
  │
  └─ BottomNavigationBar → Calendar / Challenges / Settings
```

---

## Reglas de negocio

1. **Streak**: días consecutivos donde se completaron TODOS los retos activos
2. **Color del día en calendario**:
   - `Colors.green[800]` → 100% completado
   - `Colors.green[300]` → 50–99%
   - `Colors.yellow[700]` → 1–49%
   - `Colors.red[400]`   → 0% (con retos activos ese día)
   - `Colors.grey[300]`  → sin datos
3. **Postpone escalado**: 1-2 veces = brutal_postpone / 3+ veces = brutal_postpone_max
4. **Sin IA**: cero llamadas a APIs externas, cero internet

---

## messages.dart — estructura y estilo

```dart
enum MessageCategory {
  brutalPositive,      // al completar (25 mensajes)
  brutalPostpone,      // al postergar 1-2 veces (25 mensajes)
  brutalPostponeMax,   // al postergar 3+ veces (25 mensajes)
  brutalWater,         // específicos de agua/hidratación (25 mensajes)
}

const Map<MessageCategory, List<String>> messages = {
  MessageCategory.brutalPositive: [ ... ],
  MessageCategory.brutalPostpone: [ ... ],
  MessageCategory.brutalPostponeMax: [ ... ],
  MessageCategory.brutalWater: [ ... ],
};

String getRandomMessage(MessageCategory category) {
  final list = messages[category]!;
  return list[Random().nextInt(list.length)];
}
```

**Estilo de los mensajes**:
- Español rioplatense/casual
- Directo, sin filtro, grosero-cariñoso
- Máximo 2-3 frases
- Prohibido: frases genéricas, emojis de corazón, lenguaje de coach motivacional

Ejemplos del tono esperado:
- `"¿Ya tomaste el agua? No, claro que no. Levantate del sillón y tomátelos de una vez."`
- `"Tres veces lo postergaste. TRES. Sos peor que el gobierno."`
- `"Lo hiciste. No me lo esperaba honestamente. Seguí así."`
- `"Otro día más mirando el techo. Tu yo del futuro te odia."`
- `"Che, ¿cuándo fue la última vez que terminaste algo? Exacto. Hacelo ahora."`

---

## Pantallas — detalle

### HomeScreen
- Header: fecha de hoy + racha actual (ej: "🔥 5 días")
- ListView de ChallengeCard para cada reto activo
- Si todos completos: banner "¡Todo listo por hoy!" en verde
- BottomNavigationBar con 4 tabs: Hoy / Calendario / Retos / Config

### CalendarScreen
- GridView 7 columnas con días del mes actual
- Cada celda: número del día con color de fondo según progreso
- Tap en celda: muestra qué retos se completaron ese día (showDialog simple)

### ChallengesScreen
- ListView de todos los retos (activos e inactivos)
- Switch para activar/desactivar cada reto
- Swipe left para eliminar (Dismissible widget)
- FAB "+" para agregar reto nuevo
- Form de creación: TextField título, fila de emojis predefinidos, ColorPicker simple (8 colores fijos), TimePicker para recordatorio

### SettingsScreen
- Switch notificaciones on/off
- Text "Racha actual: X días"
- Botón "Resetear progreso de hoy" (con confirmación)

---

## Lo que NO tiene (por diseño)

- Sin backend, sin base de datos
- Sin login, sin registro
- Sin sincronización en la nube
- Sin IA, sin APIs externas
- Sin evidencia fotográfica
- Sin analytics, sin ads
- Sin tests unitarios
- Sin suscripciones

---

## Cómo correr

```bash
flutter pub get
flutter run -d android

# Generar APK para instalar directo en el celu
flutter build apk --release
```

**Solo Android**. No correr ni configurar para iOS.

---

## Reglas para la IA que implementa esto

- Implementar TODO lo del documento, nada más, nada menos
- **Solo Android**: no tocar ni generar código de iOS/macOS
- StatefulWidget + setState. No usar Provider, Riverpod ni Bloc
- StorageService como singleton con métodos async que serializan/deserializan JSON
- Escribir los 100 mensajes completos en messages.dart (25 por categoría), con el tono indicado
- El BrutalMessageDialog debe bloquearse en pantalla y cerrarse solo con botón "ENTENDIDO"
- Las notificaciones se cancelan y re-crean cuando se edita hora de un reto
- Configurar AndroidManifest.xml con los permisos de notificaciones correctos
- No crear archivos extra que no estén en la estructura de este documento
