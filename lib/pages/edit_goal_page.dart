import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/utils/currency_input_formatter.dart';

/// Halaman untuk menyunting data target tabungan.
///
/// Memungkinkan pembaruan nama target, target nominal, dana terkumpul, deadline,
/// dan tingkat prioritas langsung ke SQLite via [DatabaseHelper.updateGoal].
class EditGoalPage extends StatefulWidget {
  final GoalModel goal;

  const EditGoalPage({super.key, required this.goal});

  @override
  State<EditGoalPage> createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  late TextEditingController nameController;
  late TextEditingController targetController;
  late TextEditingController currentController;
  late TextEditingController deadlineController;

  String? selectedPriority;

  String formatNominal(double value) {
    final digits = value.round().toString();

    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.goal.name);

    targetController = TextEditingController(
      text: formatNominal(widget.goal.targetAmount),
    );

    currentController = TextEditingController(
      text: formatNominal(widget.goal.currentAmount),
    );

    deadlineController = TextEditingController(
      text: widget.goal.deadline ?? '',
    );

    selectedPriority = widget.goal.priority;
  }

  @override
  void dispose() {
    nameController.dispose();
    targetController.dispose();
    currentController.dispose();
    deadlineController.dispose();

    super.dispose();
  }

  // ============================================================
  // UPDATE GOAL
  // ============================================================

  Future<void> updateGoal() async {
    final name = nameController.text.trim();

    final target = double.tryParse(
      targetController.text.replaceAll('.', '').trim(),
    );

    final current = double.tryParse(
      currentController.text.replaceAll('.', '').trim(),
    );

    final deadline = deadlineController.text.trim();

    // ----------------------------------------------------------
    // VALIDASI DASAR
    // ----------------------------------------------------------

    if (name.isEmpty || target == null || current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi data dengan benar.')),
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDASI NOMINAL
    // ----------------------------------------------------------

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target nominal harus lebih dari 0.')),
      );

      return;
    }

    if (current < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabungan saat ini tidak boleh negatif.')),
      );

      return;
    }

    if (current > target) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tabungan saat ini tidak boleh '
            'lebih besar dari target.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // BUAT DATA GOAL BARU
    // ----------------------------------------------------------

    final updatedGoal = GoalModel(
      id: widget.goal.id,

      // PENTING:
      // Pemilik target tidak berubah
      // ketika target diedit.
      userId: widget.goal.userId,

      name: name,
      targetAmount: target,
      currentAmount: current,

      deadline: deadline.isEmpty ? null : deadline,

      priority: selectedPriority,
    );

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------

    final result = await DatabaseHelper.instance.updateGoal(updatedGoal);

    debugPrint('HASIL UPDATE GOAL: $result');

    debugPrint('USER ID: ${updatedGoal.userId}');

    if (!mounted) return;

    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target berhasil diperbarui.')),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Target gagal diperbarui.')));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Target')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Edit Target Tabungan',

              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Perbarui informasi target tabunganmu.',

              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // NAMA
            // =================================================
            const SizedBox(height: 16),

            // ==================================================
            // TARGET
            // ==================================================
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Target Nominal',
                hintText: 'Contoh: 15000000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CURRENT AMOUNT
            // ==================================================
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Tabungan Saat Ini',
                hintText: 'Contoh: 5000000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DEADLINE
            // ==================================================
            TextField(
              controller: deadlineController,
              readOnly: true,

              decoration: InputDecoration(
                labelText: 'Deadline',
                hintText: 'Pilih tanggal deadline',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: deadlineController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus deadline',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            deadlineController.clear();
                          });
                        },
                      )
                    : null,
              ),

              onTap: () async {
                DateTime initialDate = DateTime.now();

                // Jika sudah ada deadline sebelumnya,
                // gunakan tanggal tersebut sebagai tanggal awal kalender.
                if (deadlineController.text.isNotEmpty) {
                  final parsedDate = DateTime.tryParse(deadlineController.text);

                  if (parsedDate != null) {
                    initialDate = parsedDate;
                  }
                }

                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  helpText: 'Pilih Deadline',
                  cancelText: 'Batal',
                  confirmText: 'Pilih',
                );

                if (pickedDate != null) {
                  setState(() {
                    deadlineController.text =
                        '${pickedDate.year.toString().padLeft(4, '0')}-'
                        '${pickedDate.month.toString().padLeft(2, '0')}-'
                        '${pickedDate.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PRIORITAS
            // ==================================================
            DropdownButtonFormField<String>(
              initialValue: selectedPriority,

              decoration: const InputDecoration(
                labelText: 'Prioritas',

                border: OutlineInputBorder(),
              ),

              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),

                DropdownMenuItem(value: 'Medium', child: Text('Medium')),

                DropdownMenuItem(value: 'High', child: Text('High')),
              ],

              onChanged: (value) {
                setState(() {
                  selectedPriority = value;
                });
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SIMPAN
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: updateGoal,

                icon: const Icon(Icons.save_outlined),

                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),

                  child: Text(
                    'Simpan Perubahan',

                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
