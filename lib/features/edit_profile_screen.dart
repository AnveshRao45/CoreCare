import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/models/user_profile.dart';
import 'package:upgrade/providers/user_provider.dart';
import 'package:upgrade/routes/routes.dart';
import 'package:upgrade/services/hive_service.dart';
import 'package:upgrade/services/nutrition_targets_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  static const id = AppRoutes.editProfileScreen;
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _calTargetCtrl = TextEditingController();
  final _stepsTargetCtrl = TextEditingController();
  final _waterTargetCtrl = TextEditingController();
  String _gender = 'Female';
  String _activity = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    if (user != null) _loadUser(user);
    _calTargetCtrl.text =
        NutritionTargetsService.targetCalories(user).toString();
    _stepsTargetCtrl.text =
        NutritionTargetsService.targetSteps().toString();
    _waterTargetCtrl.text =
        NutritionTargetsService.targetWaterGlasses().toString();
  }

  void _loadUser(UserProfile user) {
    _nameCtrl.text = user.name ?? '';
    _ageCtrl.text = user.age?.toString() ?? '';
    _heightCtrl.text = user.height?.toString() ?? '';
    _weightCtrl.text = user.weight?.toString() ?? '';
    _gender = user.gender ?? 'Female';
    _activity = user.activityLevel ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _calTargetCtrl.dispose();
    _stepsTargetCtrl.dispose();
    _waterTargetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(userProfileProvider) ?? UserProfile();
    user.name = _nameCtrl.text.trim();
    user.age = int.tryParse(_ageCtrl.text);
    user.height = double.tryParse(_heightCtrl.text);
    user.weight = double.tryParse(_weightCtrl.text);
    user.gender = _gender;
    user.activityLevel = _activity;
    user.isOnboardingComplete = true;
    user.updatedAt = DateTime.now();

    await HiveService.saveUserProfile(user);
    ref.read(userProfileProvider.notifier).refresh();

    await NutritionTargetsService.saveCustomTargets(
      calories: int.tryParse(_calTargetCtrl.text),
      steps: int.tryParse(_stepsTargetCtrl.text),
      waterGlasses: int.tryParse(_waterTargetCtrl.text),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile and goals updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & goals'),
        backgroundColor: const Color(0xFF9947EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
          ),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Female', 'Male', 'Other']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          TextField(
            controller: _heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
          ),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Daily goal targets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextField(
            controller: _calTargetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calorie intake target (kcal)',
            ),
          ),
          TextField(
            controller: _stepsTargetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Step target'),
          ),
          TextField(
            controller: _waterTargetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Water (glasses)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9947EB),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
