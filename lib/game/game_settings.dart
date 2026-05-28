import 'package:flutter/material.dart';

class SettingsOverlay extends StatelessWidget {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onMusicChanged;
  final ValueChanged<bool> onVibrationChanged;
  final VoidCallback onBack;

  const SettingsOverlay({
    super.key,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.vibrationEnabled,
    required this.onSoundChanged,
    required this.onMusicChanged,
    required this.onVibrationChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withAlpha(80), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('设置', style: TextStyle(
              color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 24),
            _SettingsRow(label: '音效', value: soundEnabled, onChanged: onSoundChanged),
            const SizedBox(height: 12),
            _SettingsRow(label: '音乐', value: musicEnabled, onChanged: onMusicChanged),
            const SizedBox(height: 12),
            _SettingsRow(label: '震动', value: vibrationEnabled, onChanged: onVibrationChanged),
            const SizedBox(height: 24),
            _SettingsButton(label: '返回', onTap: onBack),
          ]),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withAlpha(120), width: 1),
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(
          color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold,
        )),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amber,
      ),
    ]);
  }
}