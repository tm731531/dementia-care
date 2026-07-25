# care-record-app — Plan 2: Photo, Doctor Review Screen, HTML export, ZIP sync

> **For agentic workers:** executed via superpowers:subagent-driven-development, task-by-task with review.

**Goal:** Complete the lean family app: attach a photo to a note, a good-looking in-app date-grouped
"doctor review" screen, a single-file HTML export a doctor can open on any phone, and ZIP export/import
so a second phone (外勞) can receive and merge the family's records.

**Scope (Tom, 2026-07-23):** lean. NO 12 structured tap-items, NO trend charts, NO biometric lock.

**Tech:** Flutter, Riverpod, sqflite (existing). Add `image_picker` (photo), `archive` (zip),
`share_plus` (OS share sheet), `path_provider` (existing).

## Global Constraints (carry over from Plan 1)
- Fully offline, zero cloud, local-only storage, no account backend.
- All UI Traditional Chinese; low-vision theme (`careTheme`: off-white bg, dark text, ≥24px, never pure B/W).
- `CareNote` is append-only, author-tagged, UTC-stored / local-displayed; insert idempotent-by-id.
- Git on `dev`, English commit messages. Never touch the pre-existing unrelated dirty files.
- 寧缺勿錯: a failed sub-step (photo pick cancelled, share cancelled) must not lose or corrupt data.

---

### Task 1: Attach an optional photo to a note
**Files:** modify `record_note_screen.dart`; add a small `PhotoStore` helper in `lib/features/record/data/photo_store.dart`; `pubspec.yaml` (`image_picker`).
**Behavior:** On the record screen, a 「📷 加照片（選填）」 button → `image_picker` (camera OR gallery). Copy the picked file into app-documents (`getApplicationDocumentsDirectory()/photos/<uuid>.jpg`) via `PhotoStore.save(File) -> String path`; hold the path in screen state; show a thumbnail + a 「移除」 option. On 儲存, pass the saved path as `CareNote.photoPath`. Cancelling the picker leaves the note photoless (no crash). Guard all async setState with `if (!mounted) return`.
**Test:** unit-test `PhotoStore` path/copy logic against a temp dir (pure Dart / IO — no device). Photo picking itself is device-verified in the final smoke.
**Done:** analyze clean, `flutter test` all pass, one `flutter build apk --debug` compiles.

### Task 2: Doctor review screen (the "好看的整理畫面")
**Files:** `lib/features/record/view/doctor_review_screen.dart`; a pure builder `lib/features/record/view/review_model.dart` that groups notes by local date; add an entry point (an icon button on the note list appbar / home). 
**Behavior:** A read-only, date-grouped review: a header (patient-agnostic title + date range covered + total note count + optional date-range filter with two date pickers defaulting to last 30 days), then per **local calendar date** a date header (e.g. `2026-07-21（週一）`), and under it each note as a clean card — shift+time, author chip (家屬/照顧者), text, and a photo thumbnail if present (tap → full-screen view). Newest date first; within a date, chronological. Large readable type (careTheme). This is the screen 外勞 shows the doctor.
**Pure logic to unit-test:** `groupNotesByLocalDate(List<CareNote>, {DateTime? from, DateTime? to}) -> List<DateGroup>` where `DateGroup { DateTime date; List<CareNote> notes; }`, filtered to [from,to], dates DESC, notes within a date ASC by time. TDD this.
**Done:** analyze clean, tests pass (grouping test), build compiles.

### Task 3: Single-file HTML export for the doctor
**Files:** `lib/features/record/service/html_report.dart`; wire a 「產出給醫生（HTML）」 button on the doctor review screen; `pubspec.yaml` (`share_plus`).
**Behavior:** `buildHtmlReport(List<DateGroup>, {DateTime from, DateTime to}) -> String` produces ONE self-contained HTML string: inline CSS (same low-vision palette), a header (date range + count), date sections mirroring the review screen, each note with time/author/text, and photos embedded as `data:image/jpeg;base64,...` (read the file, base64-encode). No external CSS/JS/fonts (offline, opens anywhere). Write it to a temp `.html` file and hand to `share_plus`'s `Share.shareXFiles` so the user picks the channel (LINE/USB/…). 
**Pure logic to unit-test:** `buildHtmlReport` — assert the returned string contains the date headers, the note texts, is a single `<html>` doc, and has no `http://`/`https://` external resource references (offline guarantee). TDD this (photos can be tested with a tiny fake image bytes → data: URI substring).
**Done:** analyze clean, tests pass, build compiles.

### Task 4: ZIP export / import (one-directional merge)
**Files:** `lib/features/record/service/backup.dart`; wire 「匯出備份（ZIP）」 + 「匯入他人紀錄」 buttons (on note list appbar or a small menu); `pubspec.yaml` (`archive`, `file_picker` for import).
**Behavior:**
- **Export:** `exportZip(NoteDao, PhotoStore) -> File` — collect all notes as JSON (`notes.json` = list of `CareNote.toJson()`), add every referenced photo file under `photos/` in the archive, write a `.zip` to temp, hand to `share_plus`.
- **Import:** user picks a `.zip` (`file_picker`) → `importZip(File, NoteDao, PhotoStore)` — unzip, read `notes.json`, copy photos into the local photo dir (rewriting each note's `photoPath` to the new local path, keyed by the note id so re-import is stable), then `dao.insert(note)` for each (insert is idempotent-by-id → union merge, no duplicates; newest-write-wins is out of scope for v1 since ids are globally unique per note). Show a summary ("匯入 N 筆，其中 M 筆是新的").
**Pure logic to unit-test:** round-trip — build some CareNotes → `exportZip` → `importZip` into a fresh DAO/dir → assert all notes present and deduped on double-import. Use `sqflite_common_ffi` + temp dirs (no device).
**Done:** analyze clean, tests pass, build compiles.

---

## After all tasks
- Final whole-branch review, then rebuild ONE arm64 debug APK + update/create a GitHub Release so Tom
  can device-smoke the WHOLE app: record(+photo) → save → review screen → HTML export → ZIP export →
  import on a 2nd phone → merged view.
- Known deferred (not in this plan): biometric lock + at-rest encryption (Tom deferred), 12 structured
  items + trends (Tom cut), punctuation-model size optimisation, date-grouping already added to list.
