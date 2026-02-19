import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pitch_sample.dart';
import '../../domain/entities/instrument_preset_profile.dart';
import '../../domain/entities/tuner_settings.dart';
import '../bloc/tuner_bloc.dart';
import '../bloc/tuner_event.dart';
import '../bloc/tuner_state.dart';

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Afinador MVP')),
      body: BlocBuilder<TunerBloc, TunerState>(
        builder: (context, state) {
          final sample = state.sample;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(state: state, sample: sample),
                  const SizedBox(height: 16),
                  _NoteCard(sample: sample),
                  const SizedBox(height: 16),
                  _CentsCard(sample: sample),
                  const SizedBox(height: 16),
                  _A4CalibrationCard(state: state),
                  const SizedBox(height: 16),
                  _PresetCard(state: state),
                  const SizedBox(height: 16),
                  _Controls(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final currentPreset = state.settings.instrumentPreset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Preset', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: currentPreset,
              isExpanded: true,
              items: kMvpInstrumentPresets
                  .map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset.id,
                      child: Text(preset.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                context.read<TunerBloc>().add(SelectPreset(value));
              },
            ),
            const SizedBox(height: 6),
            Text(
              'noiseGate ${state.settings.noiseGateDb.toStringAsFixed(1)} dB | smoothing ${state.settings.smoothing.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _A4CalibrationCard extends StatelessWidget {
  const _A4CalibrationCard({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final a4 = state.settings.a4Hz;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('A4'),
                const Spacer(),
                Text('${a4.toStringAsFixed(1)} Hz'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.read<TunerBloc>().add(const UpdateA4(TunerSettings.defaultA4Hz));
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            Slider(
              value: a4,
              min: TunerSettings.minA4Hz,
              max: TunerSettings.maxA4Hz,
              divisions: (TunerSettings.maxA4Hz - TunerSettings.minA4Hz).toInt() * 2,
              label: a4.toStringAsFixed(1),
              onChanged: (value) {
                context.read<TunerBloc>().add(UpdateA4(value));
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('430 Hz'),
                Text('440 Hz'),
                Text('450 Hz'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.sample,
  });

  final TunerState state;
  final PitchSample? sample;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      InTune() => Colors.green,
      OutOfTune() => Colors.orange,
      ErrorState() => Colors.red,
      _ => Colors.blueGrey,
    };
    final label = switch (state) {
      InTune() => 'IN TUNE',
      OutOfTune() => 'OUT OF TUNE',
      Listening() => 'LISTENING',
      ErrorState() => 'ERROR',
      _ => 'IDLE',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  'Conf ${((sample?.confidence ?? 0) * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (state is ErrorState) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  (state as ErrorState).message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.sample});

  final PitchSample? sample;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(
              sample?.note ?? '--',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(sample?.hz ?? 0).toStringAsFixed(2)} Hz',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CentsCard extends StatelessWidget {
  const _CentsCard({required this.sample});

  final PitchSample? sample;

  @override
  Widget build(BuildContext context) {
    final cents = sample?.cents ?? 0.0;
    final normalized = ((cents + 50.0) / 100.0).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)} cents',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: normalized),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('-50'), Text('0'), Text('+50')],
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final isListening = state is Listening || state is InTune || state is OutOfTune;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isListening ? null : () => context.read<TunerBloc>().add(const StartListening()),
          child: const Text('Start'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: isListening ? () => context.read<TunerBloc>().add(const StopListening()) : null,
          child: const Text('Stop'),
        ),
      ],
    );
  }
}
