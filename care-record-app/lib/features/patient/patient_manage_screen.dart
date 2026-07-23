import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../record/model/patient.dart';
import '../record/providers.dart';
import 'patient_service.dart';

/// Add / rename / delete patients on this device.
///
/// Reachable from the note list's overflow menu. Deleting the last patient
/// is blocked — the app always needs at least one patient to record against.
class PatientManageScreen extends ConsumerWidget {
  const PatientManageScreen({super.key});

  Future<String?> _promptName(BuildContext context, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(initial.isEmpty ? '新增病人' : '重新命名'),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: '姓名',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  setState(() => errorText = '請輸入姓名');
                  return;
                }
                Navigator.of(context).pop(name);
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPatient(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context);
    if (name == null) return;
    final dao = await ref.read(patientDaoProvider.future);
    await dao.insert(Patient(id: const Uuid().v4(), name: name));
    ref.invalidate(patientsProvider);
  }

  Future<void> _renamePatient(BuildContext context, WidgetRef ref, Patient patient) async {
    final name = await _promptName(context, initial: patient.name);
    if (name == null) return;
    final dao = await ref.read(patientDaoProvider.future);
    await dao.insert(Patient(id: patient.id, name: name)); // replace = rename
    ref.invalidate(patientsProvider);
  }

  Future<void> _deletePatient(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
    List<Patient> patients,
  ) async {
    if (patients.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少要保留一位病人')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除病人'),
        content: Text('刪除『${patient.name}』會一併刪除他的所有紀錄與照片，確定？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final noteDao = await ref.read(noteDaoProvider.future);
    final patientDao = await ref.read(patientDaoProvider.future);
    final photosDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );
    await PatientService().deletePatient(
      id: patient.id,
      noteDao: noteDao,
      patientDao: patientDao,
      photosDir: photosDir,
    );
    ref.invalidate(patientsProvider);
    ref.invalidate(notesProvider);

    final currentId = ref.read(currentPatientIdProvider);
    if (currentId == patient.id) {
      final remaining = patients.where((p) => p.id != patient.id).toList();
      if (remaining.isNotEmpty) {
        ref.read(currentPatientIdProvider.notifier).select(remaining.first.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('病人管理')),
      body: SafeArea(
        child: patientsAsync.when(
          data: (patients) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final patient = patients[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                title: Text(
                  patient.name,
                  style: const TextStyle(fontSize: 22, color: Color(0xFF222222)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: '重新命名',
                      onPressed: () => _renamePatient(context, ref, patient),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: '刪除',
                      onPressed: () => _deletePatient(context, ref, patient, patients),
                    ),
                  ],
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('讀取失敗：$e', style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPatient(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增病人'),
      ),
    );
  }
}
