import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';

Future<void> showEqualizerDialog(
  BuildContext context,
  AudioService audioService,
) async {
  try {
    final parameters = await audioService.equalizer.parameters;
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        final gainValues = <int, double>{
          for (final band in parameters.bands) band.index: band.gain,
        };

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 18),
                  const Text('Equalizer', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Adjust the sound bands while music is playing.', style: TextStyle(color: AppColors.white.withValues(alpha: 0.55), fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Equalizer', style: TextStyle(color: AppColors.white)),
                    value: audioService.equalizer.enabled,
                    onChanged: (value) async {
                      if (!value) {
                        setState(() {
                          for (final band in parameters.bands) { gainValues[band.index] = 0; }
                        });
                      } else { setState(() {}); }
                      await audioService.equalizer.setEnabled(value);
                      if (!value) { await Future.wait(parameters.bands.map((band) => band.setGain(0))); }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: parameters.bands.map((band) {
                        final gain = gainValues[band.index] ?? band.gain;
                        return Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    min: parameters.minDecibels,
                                    max: parameters.maxDecibels,
                                    value: gain.clamp(parameters.minDecibels, parameters.maxDecibels),
                                    onChanged: (value) {
                                      setState(() { gainValues[band.index] = value; });
                                      band.setGain(value);
                                    },
                                  ),
                                ),
                              ),
                              Text('${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB', style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('${band.centerFrequency >= 1000 ? (band.centerFrequency / 1000).toStringAsFixed(1) + 'k' : band.centerFrequency.round().toString()}', style: TextStyle(color: AppColors.white.withValues(alpha: 0.65), fontSize: 10)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Text('${parameters.minDecibels.toStringAsFixed(0)} dB   0 dB   +${parameters.maxDecibels.toStringAsFixed(0)} dB', style: TextStyle(color: AppColors.white.withValues(alpha: 0.45), fontSize: 10)),
                ],
              ),
            );
          },
        );
      },
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equalizer is not available on this device.')));
  }
}