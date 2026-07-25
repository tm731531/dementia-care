# care-record-app — Plan 1: Foundation + On-Device STT Spike

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)
> or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A working, offline Flutter app that records a spoken caregiving note, transcribes it
on-device (zero network), lets the user edit the text, and saves it locally — AND a gated spike
that proves on-device Mandarin transcription is good enough before the rest is built.

**Architecture:** Feature-first Flutter (`lib/features/record/{model,data,service,view}`), Riverpod for
state, `sqflite` for local persistence (native — not Web), on-device Whisper via a whisper.cpp Flutter
binding. Plan 1 is the **walking skeleton + risk kill**: it delivers one end-to-end vertical slice
(speak → transcribe → edit → save → list) and no more. Structured items, trends, doctor export,
merge, and encryption are Plans 2–3.

**Tech Stack:** Flutter (stable at `/home/tom/development/flutter`), Dart, Riverpod, `sqflite`,
`path_provider`, `record` (audio capture), a whisper.cpp binding (candidate: `whisper_ggml` —
validated in Task 2), `flutter_test`.

## Global Constraints

- **Zero cloud. Zero network calls of any kind.** No analytics, no crash reporting, no font CDN,
  no remote STT. Transcription and storage are 100% on-device. (spec §2 C1/C2)
- **Data lives only on the device.** No account backend. (spec §2 C2)
- **All UI text in Traditional Chinese.** (spec §4 / monorepo rule)
- **Low-vision contrast:** off-white background `#f5f5f5`, dark text `#222`, font size ≥ 24px,
  line-height ≥ 1.6. Never pure-black-on-pure-white. (母層 CLAUDE.md 白內障 frame)
- **Git:** work on `dev` branch, never `main`. Commit messages in English, `feat:`/`test:`/`chore:` prefix.
- **Event note is append-only + timestamped + author-tagged** from day one — the data model that makes
  Plan 3's merge trivial. Do not model notes as a single overwritable field. (spec §4.3)
- **寧缺勿錯:** transcription the model is unsure of is shown to the user to fix; never auto-"corrected"
  into the saved record silently. (spec §4.7 / README.md:55 lineage)

---

## File Structure (Plan 1 scope)

```
care-record-app/
  pubspec.yaml                                  # deps + assets (whisper model)
  assets/models/                                # bundled whisper ggml model (Task 2 decides size)
  lib/
    main.dart                                   # app entry, ProviderScope, MaterialApp theme
    core/
      theme.dart                                # low-vision theme (colors, text sizes)
      time.dart                                 # shift-of-day helper (早/晚/大夜)
    features/record/
      model/
        care_note.dart                          # CareNote entity (pure Dart) + JSON
        note_author.dart                        # enum family / caregiver
      data/
        note_dao.dart                           # sqflite CRUD for care_note
        local_db.dart                           # sqflite open/migrate
      service/
        audio_recorder.dart                     # wraps `record`
        transcriber.dart                        # abstract Transcriber + WhisperTranscriber
      view/
        record_note_screen.dart                 # record → transcribe → edit → save
        note_list_screen.dart                   # list saved notes (verifies persistence)
  spike/                                         # Task 2 spike, deleted or promoted after gate
    stt_spike.md                                # spike results + accuracy evidence
  test/
    features/record/
      care_note_test.dart
      note_dao_test.dart
      time_test.dart
```

---

### Task 1: Flutter project scaffold + low-vision theme

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/core/theme.dart`
- Test: `test/smoke_test.dart`

**Interfaces:**
- Produces: `careTheme` (a `ThemeData` in `theme.dart`); an `App` widget in `main.dart`.

- [ ] **Step 1: Create the Flutter project in place**

Run:
```bash
cd /home/tom/Desktop/dementia-care
/home/tom/development/flutter/bin/flutter create --org com.tomting --project-name care_record_app \
  --platforms=android,ios care-record-app
```
Expected: Flutter generates `android/`, `ios/`, `lib/main.dart`, `pubspec.yaml` inside the existing
`care-record-app/` folder (keeps our `CLAUDE.md`, `README.md`, `docs/`).

- [ ] **Step 2: Add Plan-1 dependencies**

Run:
```bash
cd /home/tom/Desktop/dementia-care/care-record-app
/home/tom/development/flutter/bin/flutter pub add flutter_riverpod sqflite path path_provider record
```
Expected: `pubspec.yaml` `dependencies:` now lists `flutter_riverpod`, `sqflite`, `path`,
`path_provider`, `record`. (Whisper binding is added in Task 2 after validation.)

- [ ] **Step 3: Write the low-vision theme**

`lib/core/theme.dart`:
```dart
import 'package:flutter/material.dart';

/// Low-vision-safe theme for elderly caregivers with cataracts:
/// off-white bg + dark text (NOT pure black/white), large type, generous spacing.
final ThemeData careTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2C5D80),
    surface: const Color(0xFFF5F5F5),
    onSurface: const Color(0xFF222222),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 24, height: 1.6, color: Color(0xFF222222)),
    bodyMedium: TextStyle(fontSize: 20, height: 1.6, color: Color(0xFF222222)),
    titleLarge: TextStyle(fontSize: 28, height: 1.5, color: Color(0xFF222222)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(88, 56), // ≥48px touch target, comfortable for elderly
      textStyle: const TextStyle(fontSize: 22),
    ),
  ),
);
```

- [ ] **Step 4: Wire main.dart to the theme + a placeholder home**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '照護紀錄',
        theme: careTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: Text('照護紀錄', key: Key('home-title')))),
      );
}
```

- [ ] **Step 5: Write a smoke test**

`test/smoke_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:care_record_app/core/theme.dart';

void main() {
  testWidgets('app boots and shows title on off-white bg', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: careTheme, home: const Scaffold(body: Text('照護紀錄'))),
    ));
    expect(find.text('照護紀錄'), findsOneWidget);
    expect(careTheme.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
  });
}
```

- [ ] **Step 6: Run tests**

Run: `/home/tom/development/flutter/bin/flutter test test/smoke_test.dart`
Expected: PASS (1 test).

- [ ] **Step 7: Commit**

```bash
git add care-record-app/pubspec.yaml care-record-app/lib care-record-app/test \
        care-record-app/android care-record-app/ios
git commit -m "feat: scaffold care-record-app Flutter project with low-vision theme"
```

---

### Task 2: On-device STT spike (GATE — everything downstream depends on this)

**Why first:** spec §3.2 measured desktop `faster-whisper` (an *upper bound*). The product bets on an
*on-device* model, which is weaker. If on-device transcription of Taiwan-Mandarin caregiving speech is
not usable, the whole voice-input approach must be reconsidered BEFORE building the app around it. This
task is exploratory (not TDD); its deliverable is **evidence + a go/no-go decision**, recorded in
`spike/stt_spike.md`.

**Files:**
- Create: `spike/stt_spike.md` (results), a throwaway spike screen (deleted or promoted after gate)
- Modify: `pubspec.yaml` (whisper binding + bundled model asset)

- [ ] **Step 1: Choose and add a whisper.cpp binding**

Evaluate current pub.dev on-device whisper bindings (candidates: `whisper_ggml`, `whisper_flutter_plus`).
Selection criteria, checked against each package's README/pub page:
- Runs fully offline (bundled ggml model, no network at inference)
- Supports Chinese (`zh`) and a `small` (or `base`) ggml model
- Maintained (updated within ~12 months), Android + iOS
Add the chosen one:
```bash
/home/tom/development/flutter/bin/flutter pub add <chosen_whisper_pkg>
```
Record the choice + why in `spike/stt_spike.md`.

- [ ] **Step 2: Bundle a small ggml model as an asset**

Download `ggml-small.bin` (or the binding's expected quantised variant, e.g. `ggml-small-q5_1.bin`)
into `assets/models/`, and declare it in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/
```
Note the on-disk size in `spike/stt_spike.md` (feeds the spec §5 model-size decision).

- [ ] **Step 3: Build a throwaway record→transcribe spike screen**

A single screen: a record button (using `record`), on stop it runs the whisper binding on the captured
file with `language: 'zh'`, and displays the raw transcription text on screen. No persistence, no styling
beyond legibility. Purpose: run it on a REAL phone.

- [ ] **Step 4: Run on a real device against a fixed script**

Read this fixed caregiving script aloud (contains the clinical keywords that killed OCR):
> 「今天精神穩定，午餐吃一半，屁股有點紅紅的，半穀饅頭吃了，左手會痛。」

Do this on at least one real Android phone (and an iPhone if available). Capture the transcription output.

- [ ] **Step 5: Score against ground truth and record evidence**

In `spike/stt_spike.md`, record: device model, OS, whisper model size, wall-clock transcription time,
and a character-level diff of output vs the script. Specifically check whether each **keyword**
(精神穩定 / 吃一半 / 屁股 / 紅 / 饅頭 / 左手痛) survived.

- [ ] **Step 6: GATE — go / no-go**

Decision rule, written explicitly in `spike/stt_spike.md`:
- **GO** if the everyday keywords above are captured correctly (minor errors on non-keyword filler are
  fine) AND transcription of a ~15s clip finishes in a tolerable time (target < ~15s) on a mid-range phone.
- **NO-GO** if keywords are mangled or it is unusably slow. STOP. Do not proceed to Task 3. Escalate to
  Tom with the evidence: options are a larger model (size/perf cost), a different binding, or revisiting
  the input method. (This is the honest off-ramp the spec's §3.2 caveat demands.)

- [ ] **Step 7: Commit the spike evidence**

```bash
git add care-record-app/spike/stt_spike.md care-record-app/pubspec.yaml care-record-app/assets
git commit -m "chore: on-device STT spike — evidence and go/no-go for Mandarin caregiving speech"
```

> **Do not start Task 3 until Step 6 records GO.**

---

### Task 3: CareNote domain model (pure Dart — full TDD)

**Files:**
- Create: `lib/features/record/model/note_author.dart`, `lib/features/record/model/care_note.dart`
- Test: `test/features/record/care_note_test.dart`

**Interfaces:**
- Produces:
  - `enum NoteAuthor { family, caregiver }` with `String get code` (`'F'` / `'C'`) and
    `static NoteAuthor fromCode(String)`.
  - `class CareNote` with fields `String id`, `DateTime timestamp`, `NoteAuthor author`,
    `String text`, `String? photoPath`; `Map<String, dynamic> toJson()`; and
    `factory CareNote.fromJson(Map<String, dynamic>)`. `id` is caller-supplied (a UUID string) so
    merge (Plan 3) can dedup by it. Append-only: no mutating setters.

- [ ] **Step 1: Write the failing test**

`test/features/record/care_note_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/model/note_author.dart';
import 'package:care_record_app/features/record/model/care_note.dart';

void main() {
  test('NoteAuthor round-trips through its code', () {
    expect(NoteAuthor.family.code, 'F');
    expect(NoteAuthor.caregiver.code, 'C');
    expect(NoteAuthor.fromCode('F'), NoteAuthor.family);
    expect(NoteAuthor.fromCode('C'), NoteAuthor.caregiver);
  });

  test('CareNote serialises and deserialises losslessly', () {
    final note = CareNote(
      id: 'uuid-123',
      timestamp: DateTime.utc(2026, 7, 21, 22, 57),
      author: NoteAuthor.family,
      text: '屁股有點紅紅的，左手會痛',
      photoPath: '/data/photos/uuid-123.jpg',
    );
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.id, note.id);
    expect(restored.timestamp, note.timestamp);
    expect(restored.author, NoteAuthor.family);
    expect(restored.text, note.text);
    expect(restored.photoPath, note.photoPath);
  });

  test('CareNote tolerates a null photoPath', () {
    final note = CareNote(
      id: 'x', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.caregiver, text: 'ok');
    final restored = CareNote.fromJson(note.toJson());
    expect(restored.photoPath, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/care_note_test.dart`
Expected: FAIL (files/types not defined).

- [ ] **Step 3: Write the minimal implementation**

`lib/features/record/model/note_author.dart`:
```dart
enum NoteAuthor {
  family,
  caregiver;

  String get code => this == NoteAuthor.family ? 'F' : 'C';

  static NoteAuthor fromCode(String code) =>
      code == 'F' ? NoteAuthor.family : NoteAuthor.caregiver;
}
```

`lib/features/record/model/care_note.dart`:
```dart
import 'note_author.dart';

/// One caregiving event note. Append-only, timestamped, author-tagged so that
/// merging two devices' notes (Plan 3) is a union deduped by [id].
class CareNote {
  final String id; // caller-supplied UUID → stable across devices
  final DateTime timestamp;
  final NoteAuthor author;
  final String text;
  final String? photoPath;

  const CareNote({
    required this.id,
    required this.timestamp,
    required this.author,
    required this.text,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'author': author.code,
        'text': text,
        'photoPath': photoPath,
      };

  factory CareNote.fromJson(Map<String, dynamic> json) => CareNote(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        author: NoteAuthor.fromCode(json['author'] as String),
        text: json['text'] as String,
        photoPath: json['photoPath'] as String?,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/care_note_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add care-record-app/lib/features/record/model care-record-app/test/features/record/care_note_test.dart
git commit -m "feat: CareNote append-only model with author tag and lossless JSON"
```

---

### Task 4: Local persistence (sqflite DAO — TDD)

**Files:**
- Create: `lib/features/record/data/local_db.dart`, `lib/features/record/data/note_dao.dart`
- Test: `test/features/record/note_dao_test.dart`

**Interfaces:**
- Consumes: `CareNote`, `NoteAuthor` from Task 3.
- Produces:
  - `class LocalDb { static Future<Database> open(String path); }` — opens/creates the `care_note` table.
  - `class NoteDao { NoteDao(Database db); Future<void> insert(CareNote n);
    Future<List<CareNote>> allNewestFirst(); }` — `insert` is idempotent by `id`
    (`ConflictAlgorithm.replace`) so re-importing (Plan 3) never duplicates.

- [ ] **Step 1: Write the failing test (uses sqflite_common_ffi so it runs on the dev host, no device)**

Run first: `/home/tom/development/flutter/bin/flutter pub add --dev sqflite_common_ffi`

`test/features/record/note_dao_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:care_record_app/features/record/data/local_db.dart';
import 'package:care_record_app/features/record/data/note_dao.dart';
import 'package:care_record_app/features/record/model/care_note.dart';
import 'package:care_record_app/features/record/model/note_author.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert then read back, newest first', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'a', timestamp: DateTime.utc(2026, 7, 20, 8), author: NoteAuthor.family, text: '早上穩定'));
    await dao.insert(CareNote(
        id: 'b', timestamp: DateTime.utc(2026, 7, 21, 22), author: NoteAuthor.caregiver, text: '左手痛'));
    final all = await dao.allNewestFirst();
    expect(all.map((n) => n.id).toList(), ['b', 'a']); // newest first
    expect(all.first.author, NoteAuthor.caregiver);
    await db.close();
  });

  test('inserting the same id twice replaces, does not duplicate (import-safe)', () async {
    final db = await LocalDb.open(inMemoryDatabasePath);
    final dao = NoteDao(db);
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v1'));
    await dao.insert(CareNote(
        id: 'dup', timestamp: DateTime.utc(2026, 7, 21), author: NoteAuthor.family, text: 'v2'));
    final all = await dao.allNewestFirst();
    expect(all.length, 1);
    expect(all.single.text, 'v2');
    await db.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/note_dao_test.dart`
Expected: FAIL (LocalDb / NoteDao not defined).

- [ ] **Step 3: Write the minimal implementation**

`lib/features/record/data/local_db.dart`:
```dart
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static Future<Database> open(String path) => openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE care_note (
              id TEXT PRIMARY KEY,
              timestamp TEXT NOT NULL,
              author TEXT NOT NULL,
              text TEXT NOT NULL,
              photoPath TEXT
            )
          ''');
        },
      );
}
```

`lib/features/record/data/note_dao.dart`:
```dart
import 'package:sqflite/sqflite.dart';
import '../model/care_note.dart';

class NoteDao {
  final Database _db;
  NoteDao(this._db);

  Future<void> insert(CareNote n) => _db.insert(
        'care_note',
        n.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace, // idempotent by id → import-safe
      );

  Future<List<CareNote>> allNewestFirst() async {
    final rows = await _db.query('care_note', orderBy: 'timestamp DESC');
    return rows.map(CareNote.fromJson).toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/note_dao_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add care-record-app/lib/features/record/data care-record-app/test/features/record/note_dao_test.dart \
        care-record-app/pubspec.yaml
git commit -m "feat: sqflite NoteDao with import-safe idempotent insert"
```

---

### Task 5: Audio capture + transcription service (integration behind interfaces)

**Files:**
- Create: `lib/features/record/service/audio_recorder.dart`,
  `lib/features/record/service/transcriber.dart`
- Test: `test/features/record/transcriber_contract_test.dart`

**Interfaces:**
- Consumes: the whisper binding validated in Task 2.
- Produces:
  - `abstract class Transcriber { Future<String> transcribe(String audioFilePath); }` — the seam that
    keeps UI (Task 6) and later plans testable without a real model.
  - `class WhisperTranscriber implements Transcriber` — wraps the Task-2 binding, `language: 'zh'`,
    fully offline.
  - `class AudioRecorder { Future<void> start(); Future<String> stopAndGetPath(); }` — wraps `record`,
    writes a temp file via `path_provider`.

- [ ] **Step 1: Write a contract test against a fake Transcriber**

`test/features/record/transcriber_contract_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/features/record/service/transcriber.dart';

class _FakeTranscriber implements Transcriber {
  @override
  Future<String> transcribe(String audioFilePath) async => '午餐吃一半，左手會痛';
}

void main() {
  test('Transcriber returns the spoken text for an audio path', () async {
    final Transcriber t = _FakeTranscriber();
    final text = await t.transcribe('/tmp/whatever.wav');
    expect(text, '午餐吃一半，左手會痛');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/transcriber_contract_test.dart`
Expected: FAIL (`transcriber.dart` not defined).

- [ ] **Step 3: Write the interface + implementations**

`lib/features/record/service/transcriber.dart`:
```dart
// The abstract seam. UI and tests depend on Transcriber, not on the whisper package.
abstract class Transcriber {
  /// Transcribe an on-device audio file to text. Fully offline. Never throws for
  /// low-confidence audio — returns best-effort text for the user to edit (寧缺勿錯:
  /// the human is the verifier).
  Future<String> transcribe(String audioFilePath);
}

// NOTE: replace <whisper_pkg> imports/calls with the exact API of the package chosen in Task 2.
class WhisperTranscriber implements Transcriber {
  final String modelAssetPath;
  WhisperTranscriber(this.modelAssetPath);

  @override
  Future<String> transcribe(String audioFilePath) async {
    // Pseudocode against the Task-2 binding — fill with its real API:
    //   final whisper = Whisper(model: modelAssetPath);
    //   final res = await whisper.transcribe(audio: audioFilePath, language: 'zh');
    //   return res.text.trim();
    throw UnimplementedError('Wire to the Task-2 whisper binding API');
  }
}
```

`lib/features/record/service/audio_recorder.dart`:
```dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioRecorder {
  final AudioRecorder _placeholder = throw UnimplementedError();
}
```
> Replace the placeholder body with the `record` package's current API: request mic permission,
> `start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: ...)`
> into a temp dir from `getTemporaryDirectory()`, and `stop()` returning the path. 16kHz mono WAV is
> what whisper.cpp expects. Keep the public surface exactly `start()` / `stopAndGetPath()`.

- [ ] **Step 4: Run the contract test (passes on the fake; real impls are device-verified in Task 6)**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/transcriber_contract_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Wire WhisperTranscriber to the real binding and verify on device**

Implement `WhisperTranscriber.transcribe` and `AudioRecorder` against the real packages. Verify by
running the app on a real device in Task 6 (there is no unit test for the native model — the Task-2
spike + Task-6 manual smoke are its verification).

- [ ] **Step 6: Commit**

```bash
git add care-record-app/lib/features/record/service \
        care-record-app/test/features/record/transcriber_contract_test.dart
git commit -m "feat: Transcriber seam + WhisperTranscriber and AudioRecorder wrappers"
```

---

### Task 6: Record-a-note screen wired end-to-end + persistence check

**Files:**
- Create: `lib/features/record/view/record_note_screen.dart`,
  `lib/features/record/view/note_list_screen.dart`, `lib/core/time.dart`
- Modify: `lib/main.dart` (home → record screen)
- Test: `test/features/record/time_test.dart`

**Interfaces:**
- Consumes: `AudioRecorder`, `Transcriber`, `NoteDao`, `CareNote`, `NoteAuthor`.
- Produces: `String shiftOfDay(DateTime)` in `time.dart` returning `'早'`/`'晚'`/`'大夜'` (spec:
  06–14 早, 14–22 晚, 22–06 大夜). UI author defaults to `NoteAuthor.family` for Plan 1 (per-device
  author selection is Plan 3).

- [ ] **Step 1: Write the failing test for the shift helper**

`test/features/record/time_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:care_record_app/core/time.dart';

void main() {
  test('shiftOfDay buckets by caregiving shift', () {
    expect(shiftOfDay(DateTime(2026, 7, 21, 9)), '早');   // 06-14
    expect(shiftOfDay(DateTime(2026, 7, 21, 15)), '晚');  // 14-22
    expect(shiftOfDay(DateTime(2026, 7, 21, 23)), '大夜'); // 22-06
    expect(shiftOfDay(DateTime(2026, 7, 21, 3)), '大夜');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/time_test.dart`
Expected: FAIL (`time.dart` not defined).

- [ ] **Step 3: Implement the shift helper**

`lib/core/time.dart`:
```dart
/// Caregiving shift bucket for a timestamp (matches whiteboard-ocr-bot's 早/晚/大夜).
String shiftOfDay(DateTime t) {
  final h = t.hour;
  if (h >= 6 && h < 14) return '早';
  if (h >= 14 && h < 22) return '晚';
  return '大夜';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tom/development/flutter/bin/flutter test test/features/record/time_test.dart`
Expected: PASS.

- [ ] **Step 5: Build the record screen**

`lib/features/record/view/record_note_screen.dart`: a `ConsumerStatefulWidget` with one big
「🎤 開始說話」 FilledButton. Flow: tap → `AudioRecorder.start()`; tap again (「⏹ 停止」) →
`stopAndGetPath()` → `Transcriber.transcribe(path)` → put the result into an editable `TextField`
(pre-filled, user can fix — 寧缺勿錯). A 「儲存」 button builds a `CareNote` (id = a fresh UUID via
`add uuid` package, timestamp = `DateTime.now()`, author = `NoteAuthor.family`) and calls
`NoteDao.insert`, then navigates to `note_list_screen`. Use `careTheme` sizes; show a
`CircularProgressIndicator` with 「辨識中…」 while transcribing. All strings Traditional Chinese.

- [ ] **Step 6: Build the note list screen**

`lib/features/record/view/note_list_screen.dart`: reads `NoteDao.allNewestFirst()`, renders each note
as a large-text tile showing `shiftOfDay(timestamp)` + time + author label (家屬/照顧者) + text (+ a
📷 marker if `photoPath != null`). This screen is how we visually verify persistence survives an app
restart.

- [ ] **Step 7: Point main.dart home at the record screen**

Replace the placeholder `home:` with `RecordNoteScreen()`. Ensure `NoteDao`/`AudioRecorder`/
`WhisperTranscriber` are provided via Riverpod providers (DB opened once at startup via
`getApplicationDocumentsDirectory()` + `LocalDb.open`).

- [ ] **Step 8: Device smoke test (manual — the native model has no unit test)**

Run on a real device:
```bash
cd /home/tom/Desktop/dementia-care/care-record-app
/home/tom/development/flutter/bin/flutter run
```
Verify end-to-end **in airplane mode** (proves zero-network): speak the script → text appears →
edit a character → 儲存 → it shows in the list → kill and reopen the app → the note is still there.
Record the result (pass + device) in `spike/stt_spike.md` under a "Task 6 smoke" heading.

- [ ] **Step 9: Run the full test suite + commit**

Run: `/home/tom/development/flutter/bin/flutter test`
Expected: all tests PASS.
```bash
git add care-record-app/lib care-record-app/test care-record-app/pubspec.yaml
git commit -m "feat: end-to-end record→transcribe→edit→save→list voice note (offline)"
```

---

## Plan 1 done = walking skeleton
At this point the app records a caregiving note by voice, offline, and persists it. The riskiest
assumption (on-device Mandarin STT) is proven or has been escalated. **Plans 2 and 3 are written only
after Plan 1's Task-2 gate records GO**, because a NO-GO changes their shape:

- **Plan 2 — Structured items + doctor output:** the 12 tap-select items (driving trend data), the
  optional whiteboard photo attach, and the single-file HTML/PDF doctor export (trends + clean notes).
- **Plan 3 — Portability + security:** ZIP export/import with union-by-id + newest-wins merge
  (spec §4.5), biometric app lock + auto-lock on background (`local_auth`), at-rest encryption
  (`flutter_secure_storage` key + encrypted DB), optional ZIP-encryption toggle.

---

## Self-review (against spec)
- **§2 C1/C2 zero-cloud/local-only** → Global Constraints + Task 6 airplane-mode smoke. ✓
- **§3.1 no OCR** → not in any task; explicitly out of scope. ✓
- **§3.2 on-device STT is the risk** → Task 2 gate front-loads it with real-device evidence + off-ramp. ✓
- **§4.2 voice input + (tap items, photo)** → voice in Plan 1; tap items + photo deferred to Plan 2 (noted). ✓
- **§4.3 append-only, timestamped, author-tagged notes** → Task 3 model + Global Constraints. ✓
- **§4.4 doctor readable output** → Plan 2 (noted, not silently dropped). ✓
- **§4.5 merge** → Plan 3; Task 4 already makes insert idempotent-by-id to enable it. ✓
- **§4.6 security** → Plan 3 (noted). ✓
- **低視力對比** → Task 1 theme. ✓
- Placeholder scan: the only intentional "fill against real API" markers are in Task 5 (WhisperTranscriber /
  AudioRecorder), because the exact binding API is chosen in Task 2 — flagged, not hidden. ✓
- Type consistency: `CareNote` fields, `NoteAuthor.code`, `NoteDao.insert/allNewestFirst`,
  `Transcriber.transcribe`, `shiftOfDay` names are used identically across tasks. ✓
