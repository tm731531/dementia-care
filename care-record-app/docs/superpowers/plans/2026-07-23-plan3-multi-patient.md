# care-record-app — Plan 3: Multi-patient (default single, progressive disclosure)

> Executed via superpowers:subagent-driven-development.

**Goal:** Support 1..N patients on a device. A single-patient device looks EXACTLY like today (zero
patient UI). Adding a 2nd patient reveals a sticky patient switcher; everything (record / list /
review / HTML / export) scopes to the selected patient. Import auto-assigns by the patient carried in
the ZIP. A 病人管理 screen adds / renames / deletes (delete is destructive → confirm). Complexity
follows the data: 外勞's phone with 1 imported patient is automatically single-patient-simple.

**Design principle (agreed with Tom):** progressive disclosure — the "patient" concept is invisible at
1 patient, appears at 2+. Pick the current patient ONCE at the top (sticky), not per note. Import needs
no manual pick (ZIP carries patient identity).

## Global Constraints (carry over)
- Fully offline, local-only, no cloud/account. All UI Traditional Chinese; low-vision theme.
- Git on `dev`, English commits. Never touch pre-existing unrelated dirty files.
- **Data safety is paramount: the v1→v2 DB migration MUST NOT lose or mis-assign any existing note.**
- Insert remains idempotent-by-id (notes AND patients) so import merges without duplicates.

---

### Task 1: Patient model + DB v2 migration + PatientDao (heavy TDD — data safety)
**Files:** `lib/features/record/model/patient.dart`; `lib/features/record/data/patient_dao.dart`;
modify `lib/features/record/data/local_db.dart` (bump version 1→2, add migration);
modify `lib/features/record/model/care_note.dart` (add `patientId`); modify
`lib/features/record/data/note_dao.dart` (patient-scoped queries).
**Model:** `class Patient { final String id; final String name; Patient(...); toJson()/fromJson(); }`
(id = caller-supplied uuid so cross-device merge dedups by it).
**CareNote:** add `final String patientId;` — required going forward. `toJson`/`fromJson` include it.
**Migration (local_db.dart, onUpgrade v1→v2):**
1. `CREATE TABLE patient (id TEXT PRIMARY KEY, name TEXT NOT NULL)`.
2. `ALTER TABLE care_note ADD COLUMN patientId TEXT`.
3. Create ONE default patient `{id: <new uuid>, name: '本人'}`.
4. `UPDATE care_note SET patientId = <defaultId> WHERE patientId IS NULL` (backfill ALL existing notes).
   Also handle a FRESH install (onCreate v2): create the tables with patientId NOT NULL and seed the
   same default patient so `currentPatient` always resolves.
**PatientDao:** `insert(Patient)` (idempotent-by-id), `all()`, `delete(String id)` (also deletes that
patient's notes — do the note+photo cascade in a higher layer/service, see Task 4; the DAO delete just
removes the patient row and its `care_note` rows in a transaction).
**NoteDao:** add `allNewestFirstForPatient(String patientId)`; keep `existsIds()`; `insert` unchanged
(note now carries patientId).
**TDD (uses sqflite_common_ffi):**
- Migration test: open a v1 DB (create the v1 `care_note` schema + insert 2 notes WITHOUT patientId),
  then open at v2 via `LocalDb.open` → assert a default patient exists, both old notes now have that
  patientId, and no note was lost. (Simulate v1 by opening with version:1 and the old CREATE, closing,
  reopening at version:2.)
- Fresh-install test: open a brand-new v2 DB → assert the default patient exists.
- PatientDao insert/all/idempotent-by-id; delete removes patient + its notes.
- NoteDao `allNewestFirstForPatient` returns only that patient's notes, newest first.
**Done:** analyze clean, all tests pass, one apk build compiles.

### Task 2: Current-patient state + scoped providers
**Files:** `lib/features/record/providers.dart`; a small `lib/features/record/data/current_patient.dart`
persistence helper (`shared_preferences`).
- `flutter pub add shared_preferences`.
- `patientsProvider` (`FutureProvider<List<Patient>>` from PatientDao.all()).
- `currentPatientIdProvider` — a `StateNotifier`/`Notifier<String?>` backed by SharedPreferences
  (`current_patient_id`). On init: if null or not in the patient list, default to the first patient
  (there is always ≥1 after migration). Setter persists.
- `notesProvider` becomes `FutureProvider<List<CareNote>>` scoped to the current patient
  (`allNewestFirstForPatient(currentPatientId)`). It must `ref.watch(currentPatientIdProvider)` so
  switching patient refreshes the list.
- `currentPatientProvider` — derived `Patient?` (the selected patient object).
**TDD:** the persistence helper (save/load the id via an injectable SharedPreferences — use
`SharedPreferences.setMockInitialValues` in tests) and the "default to first patient when stored id is
missing" fallback logic (extract it as a pure function `resolveCurrentPatient(stored, patients)`).
**Done:** analyze clean, tests pass, apk compiles.

### Task 3: 病人管理 screen + sticky switcher (progressive disclosure)
**Files:** `lib/features/patient/patient_manage_screen.dart`;
`lib/features/patient/patient_switcher.dart`; wire into `note_list_screen.dart`.
- **Switcher** (`patient_switcher.dart`): a widget shown at the TOP of the note list ONLY when
  `patients.length >= 2`. Horizontal selectable chips (or a dropdown) of patient names; tapping sets
  `currentPatientIdProvider`. When `< 2`, it renders `SizedBox.shrink()` (invisible — single-patient
  device sees nothing).
- **病人管理 screen**: reachable from the note-list overflow menu (「病人管理」, add it alongside
  關於與隱私). Lists patients; each row has rename (inline dialog) + delete. 「＋ 新增病人」 prompts a
  name → creates `Patient(id: uuid, name)` via PatientDao + `ref.invalidate(patientsProvider)`.
  **Delete is destructive**: confirm dialog 「刪除『<name>』會一併刪除他的所有紀錄與照片，確定？」→ on
  confirm, call the Task-4 cascade delete (patient + notes + photo files), then if the deleted patient
  was current, switch current to the first remaining patient. Never allow deleting the LAST patient
  (there must always be ≥1) — disable/deny with a message 「至少要保留一位」.
**Done:** analyze clean, tests pass (switcher visibility logic can be a widget test or the
`>=2` predicate extracted + unit-tested), apk compiles.

### Task 4: Make record / review / export / import patient-aware
**Files:** `record_note_screen.dart`, `doctor_review_screen.dart`, `backup.dart`,
`note_list_screen.dart`; a `PatientService`/cascade-delete helper in
`lib/features/patient/patient_service.dart`.
- **Record:** on save, set `CareNote.patientId = currentPatientId`. Show the current patient's name in
  the app bar / a small header ONLY when there are ≥2 patients (so single-patient users see no change).
- **Review + HTML:** already read `notesProvider` (now scoped) — verify they show only the current
  patient; put the current patient's name in the review header + HTML report title when ≥2 patients.
- **Export (`backup.dart`):** `exportZip` now exports the CURRENT patient only: `patient.json`
  (the Patient) + `notes.json` (that patient's notes) + their photos. **Import (`importZip`):** read
  `patient.json`, `PatientDao.insert(patient)` (idempotent-by-id → creates or merges the patient), set
  each imported note's `patientId` to that patient's id, then insert notes. Auto-assigns — no manual
  pick. After import, switch current patient to the imported one and refresh. Update `ImportSummary`
  to also carry the patient name for the confirmation message 「已匯入『<name>』的 N 筆…」.
- **Cascade delete (`patient_service.dart`):** `deletePatient(id)` → delete the patient's photo files
  from disk, then `PatientDao.delete(id)` (removes patient + notes rows in a txn). TDD the file+row
  cascade with temp dirs + ffi.
- **Backward-compat for old ZIPs:** if an imported ZIP has NO `patient.json` (a v2-Plan-2 backup),
  fall back to assigning the notes to the CURRENT patient (don't crash). Note this in the report.
**Done:** analyze clean, all tests pass (backup round-trip now includes patient; old-zip fallback
tested), one apk build compiles.

---

## After all tasks
Final whole-branch review (focus: migration data-safety + single-patient invisibility + export/import
patient identity), then rebuild the release APK + update the GitHub Release for Tom's device smoke:
single patient still looks unchanged → add a 2nd patient → switcher appears → record scopes → export
one patient → import on another instance → that instance is single-patient-simple → delete a patient
(confirm) → data gone, current switches. 
Deferred/again-not-in-scope: biometric lock, encryption, trends, Play Store signing/AAB.
