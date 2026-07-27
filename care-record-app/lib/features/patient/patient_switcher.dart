import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../record/providers.dart';

/// The sole visibility rule: single-patient devices (the common case) never
/// see a switcher — it only earns screen space once there's an actual choice.
bool showSwitcher(int patientCount) => patientCount >= 2;

/// A horizontal row of patient chips, shown only when there's more than one
/// patient on this device — invisible on the common single-patient device so
/// existing UI is unchanged for most caregivers.
class PatientSwitcher extends ConsumerWidget {
  const PatientSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);
    final patients = patientsAsync.valueOrNull ?? const [];
    if (!showSwitcher(patients.length)) return const SizedBox.shrink();

    final currentId = ref.watch(currentPatientProvider).valueOrNull?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final patient = patients[index];
            final selected = patient.id == currentId;
            return ChoiceChip(
              label: Text(
                patient.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF222222),
                ),
              ),
              selected: selected,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              selectedColor: const Color(0xFF2C5D80).withValues(alpha: 0.25),
              backgroundColor: const Color(0xFFEDEDED),
              onSelected: (_) {
                ref.read(currentPatientIdProvider.notifier).select(patient.id);
              },
            );
          },
        ),
      ),
    );
  }
}
