import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/utils/currency_input_formatter.dart';

/// Halaman pembuatan target tabungan baru.
///
/// Mengumpulkan data nama target, target nominal dana, nominal terkumpul saat ini,
/// batas waktu (deadline), dan prioritas (Low/Medium/High) untuk disimpan ke SQLite.
class AddGoalPage extends StatefulWidget {
  final UserModel user;

  const AddGoalPage({super.key, required this.user});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final nameController = TextEditingController();
  final targetAmountController = TextEditingController();
  final currentAmountController = TextEditingController();

  String? selectedDeadline;
  String selectedPriority = 'Medium';

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    currentAmountController.dispose();
    super.dispose();
  }

  // ============================================================
  // SIMPAN TARGET
  // ============================================================

  Future<void> saveGoal() async {
    final name = nameController.text.trim();

    final targetAmount = double.tryParse(
      targetAmountController.text.replaceAll('.', '').trim(),
    );
    final currentAmount =
        double.tryParse(
          currentAmountController.text.replaceAll('.', '').trim(),
        ) ??
        0;

    // ----------------------------------------------------------
    // VALIDASI
    // ----------------------------------------------------------

    if (name.isEmpty || targetAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama target dan nominal target wajib diisi.'),
        ),
      );

      return;
    }

    if (targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal target harus lebih dari 0.')),
      );

      return;
    }

    if (currentAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabungan saat ini tidak boleh negatif.')),
      );

      return;
    }

    if (currentAmount > targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tabungan saat ini tidak boleh lebih besar '
            'dari target.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // BUAT GOAL
    // ----------------------------------------------------------

    final goal = GoalModel(
      userId: widget.user.id!,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: selectedDeadline,
      priority: selectedPriority,
    );

    // ----------------------------------------------------------
    // SIMPAN DATABASE
    // ----------------------------------------------------------

    final result = await DatabaseHelper.instance.insertGoal(goal);

    debugPrint('TARGET BERHASIL DISIMPAN');
    debugPrint('USER ID: ${widget.user.id}');
    debugPrint('GOAL ID: $result');

    if (!mounted) return;

    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target berhasil ditambahkan.')),
      );

      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // PILIH DEADLINE
  // ============================================================

  Future<void> selectDeadline() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDeadline =
            '${pickedDate.year}-'
            '${pickedDate.month.toString().padLeft(2, '0')}-'
            '${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Target')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Buat Target Tabungan',

              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tentukan target yang ingin kamu capai.',

              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // NAMA TARGET
            // ==================================================
            TextField(
              controller: nameController,

              decoration: const InputDecoration(
                labelText: 'Nama Target',

                hintText: 'Contoh: Laptop Impian',

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TARGET NOMINAL
            // ==================================================
            TextField(
              controller: targetAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Target Nominal',
                hintText: 'Masukkan nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TABUNGAN SAAT INI
            // ==================================================
            TextField(
              controller: currentAmountController,

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
            InkWell(
              onTap: selectDeadline,

              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline',

                  border: OutlineInputBorder(),
                ),

                child: Text(
                  selectedDeadline ?? 'Pilih tanggal deadline',

                  style: TextStyle(
                    color: selectedDeadline == null ? Colors.grey : null,
                  ),
                ),
              ),
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
                if (value != null) {
                  setState(() {
                    selectedPriority = value;
                  });
                }
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SIMPAN
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: saveGoal,

                icon: const Icon(Icons.flag_outlined),

                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),

                  child: Text('Simpan Target', style: TextStyle(fontSize: 16)),
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
