import 'dart:math' as math;

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
      backgroundColor: const Color(0xFF061A2B),
      body: BlocBuilder<TunerBloc, TunerState>(
        builder: (context, state) {
          final sample = state.sample;
          final isListening = state is Listening || state is InTune || state is OutOfTune;
          final meterColor = switch (state) {
            InTune() => const Color(0xFF1ED49B),
            OutOfTune() => const Color(0xFFFFA726),
            ErrorState() => const Color(0xFFFF6161),
            _ => const Color(0xFF00C7FF),
          };
          final statusLabel = switch (state) {
            InTune() => 'IN TUNE',
            OutOfTune() => 'OUT OF TUNE',
            Listening() => 'LISTENING',
            ErrorState() => 'ERROR',
            _ => 'IDLE',
          };

          final displayNote = _extractPitchClass(sample?.note) ?? '--';
          final currentHz = sample?.hz ?? 0.0;
          final targetHz = _targetHzForNote(sample?.note, state.settings.a4Hz);
          final cents = sample?.cents ?? 0.0;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF071A2A), Color(0xFF04111D)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    children: [
                      _Header(sample: sample, state: state),
                      const SizedBox(height: 18),
                      _StringSelector(activeNote: displayNote),
                      const SizedBox(height: 18),
                      _TunerCore(
                        note: displayNote,
                        hz: currentHz,
                        cents: cents,
                        statusLabel: statusLabel,
                        statusColor: meterColor,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              title: 'CENTS',
                              value: '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              title: 'TARGET',
                              value: targetHz == null ? '-- Hz' : '${targetHz.toStringAsFixed(2)} Hz',
                            ),
                          ),
                        ],
                      ),
                      if (state is ErrorState) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: state.message),
                      ],
                      const SizedBox(height: 14),
                      _SettingsPanel(state: state),
                    ],
                  ),
                  Positioned(
                    right: 20,
                    bottom: 90,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF1A8FFF),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        final bloc = context.read<TunerBloc>();
                        if (isListening) {
                          bloc.add(const StopListening());
                        } else {
                          bloc.add(const StartListening());
                        }
                      },
                      child: Icon(isListening ? Icons.stop : Icons.play_arrow_rounded),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomNav(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.sample,
    required this.state,
  });

  final PitchSample? sample;
  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final confidence = ((sample?.confidence ?? 0.0) * 100).clamp(0, 100).toStringAsFixed(0);
    final label = switch (state) {
      InTune() => 'Standard Tuning',
      OutOfTune() => 'Adjusting Pitch',
      Listening() => 'Listening',
      ErrorState() => 'Error',
      _ => 'Ready',
    };
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2A45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.menu_rounded, color: Color(0xFF33A8FF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHROMATIC TUNER',
                style: TextStyle(
                  letterSpacing: 1.5,
                  color: Color(0xFF8EA5BC),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF16C49A)),
                  const SizedBox(width: 6),
                  Text(
                    '$label | $confidence%',
                    style: const TextStyle(color: Color(0xFFD7E5F2), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF0075E5)),
            color: const Color(0x1A0075E5),
          ),
          child: const Text(
            'AUTO',
            style: TextStyle(color: Color(0xFF33A8FF), fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StringSelector extends StatelessWidget {
  const _StringSelector({required this.activeNote});

  final String activeNote;

  static const List<String> _strings = ['e', 'B', 'G', 'D', 'A', 'E'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_strings.length, (index) {
        final item = _strings[index];
        final isActive = activeNote.toUpperCase() == item.toUpperCase();
        return Expanded(
          child: Column(
            children: [
              Text(
                '${index + 1}',
                style: const TextStyle(color: Color(0xFF567089), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF18D39A) : Colors.transparent,
                  border: Border.all(
                    color: isActive ? const Color(0xFF18D39A) : const Color(0xFF2D4A62),
                  ),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x5520D8A6),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  item,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF063727) : const Color(0xFFD2DEEA),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TunerCore extends StatelessWidget {
  const _TunerCore({
    required this.note,
    required this.hz,
    required this.cents,
    required this.statusLabel,
    required this.statusColor,
  });

  final String note;
  final double hz;
  final double cents;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF11344F), Color(0xFF061D31)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4416E0A6),
            blurRadius: 50,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Column(
        children: [
          Text(
            note,
            style: const TextStyle(
              fontSize: 102,
              height: 0.95,
              color: Color(0xFF14D79C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${hz.toStringAsFixed(1)} Hz',
            style: const TextStyle(
              color: Color(0xFFCFE2F2),
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                color: Color(0xFF062315),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SmoothCentsMeter(cents: cents),
        ],
      ),
    );
  }
}

class _SmoothCentsMeter extends StatefulWidget {
  const _SmoothCentsMeter({required this.cents});

  final double cents;

  @override
  State<_SmoothCentsMeter> createState() => _SmoothCentsMeterState();
}

class _SmoothCentsMeterState extends State<_SmoothCentsMeter> {
  static const int _barCount = 25;
  static const double _alpha = 0.28;
  static const double _maxCents = 50.0;
  double _animationStart = 0.0;
  double _animationEnd = 0.0;
  double _lastPaintedValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationEnd = widget.cents.clamp(-_maxCents, _maxCents);
    _lastPaintedValue = _animationEnd;
  }

  @override
  void didUpdateWidget(covariant _SmoothCentsMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.cents.clamp(-_maxCents, _maxCents);
    final filtered = _animationEnd + (target - _animationEnd) * _alpha;
    setState(() {
      _animationStart = _lastPaintedValue;
      _animationEnd = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _animationStart, end: _animationEnd),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      builder: (context, animatedCents, _) {
        _lastPaintedValue = animatedCents;
        return Column(
          children: [
            SizedBox(
              height: 34,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final range = constraints.maxWidth - 4;
                  final ratio = ((animatedCents + _maxCents) / (_maxCents * 2)).clamp(0.0, 1.0);
                  final markerLeft = range * ratio;
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_barCount, (index) {
                            final mid = (_barCount - 1) / 2;
                            final distanceFromMid = (index - mid).abs();
                            final centsAtBar = -_maxCents + (_maxCents * 2) * (index / (_barCount - 1));
                            final proximity = (1 - ((centsAtBar - animatedCents).abs() / 8)).clamp(0.0, 1.0);
                            final baseHeight = 9 + (1 - (distanceFromMid / mid)) * 11;
                            final height = baseHeight + proximity * 2;
                            final baseColor = _barColorForCents(centsAtBar);
                            return Container(
                              width: 3,
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(0.24 + (0.56 * proximity)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                      Positioned(
                        left: markerLeft,
                        top: 1,
                        bottom: 1,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: const Color(0xFF16D39A),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xAA16D39A),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-50', style: TextStyle(color: Color(0xFF869EB5), fontWeight: FontWeight.w700)),
                Text('0', style: TextStyle(color: Color(0xFF869EB5), fontWeight: FontWeight.w700)),
                Text('+50', style: TextStyle(color: Color(0xFF869EB5), fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162537),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D344A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7F96AA),
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFDDE8F4),
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x33FF5C5C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x88FF8080)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFFB4B4), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final a4 = state.settings.a4Hz;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x80142637),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F364C)),
      ),
      child: ExpansionTile(
        collapsedIconColor: const Color(0xFF86A1B8),
        iconColor: const Color(0xFF86A1B8),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text(
          'Tuner Settings',
          style: TextStyle(color: Color(0xFFD2DFEC), fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'A4 ${a4.toStringAsFixed(1)} Hz | ${state.settings.instrumentPreset}',
          style: const TextStyle(color: Color(0xFF88A2B8)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          Row(
            children: [
              Text(
                '${a4.toStringAsFixed(1)} Hz',
                style: const TextStyle(color: Color(0xFFD2E2F1), fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.read<TunerBloc>().add(const UpdateA4(TunerSettings.defaultA4Hz));
                },
                child: const Text('Reset A4'),
              ),
            ],
          ),
          Slider(
            value: a4,
            min: TunerSettings.minA4Hz,
            max: TunerSettings.maxA4Hz,
            divisions: (TunerSettings.maxA4Hz - TunerSettings.minA4Hz).toInt() * 2,
            label: a4.toStringAsFixed(1),
            onChanged: (value) => context.read<TunerBloc>().add(UpdateA4(value)),
          ),
          DropdownButtonFormField<String>(
            initialValue: state.settings.instrumentPreset,
            decoration: const InputDecoration(
              labelText: 'Preset',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0x66132436),
            ),
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
          const SizedBox(height: 8),
          Text(
            'noiseGate ${state.settings.noiseGateDb.toStringAsFixed(1)} dB | smoothing ${state.settings.smoothing.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF88A2B8)),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Color(0xCC11293E),
        border: Border(top: BorderSide(color: Color(0x332D4B64))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.music_note_rounded, label: 'TUNER', active: true),
          _BottomNavItem(icon: Icons.timer_outlined, label: 'METRONOME'),
          _BottomNavItem(icon: Icons.library_music_outlined, label: 'SONGS'),
          _BottomNavItem(icon: Icons.settings, label: 'SETTINGS'),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1A90FF);
    final idleColor = const Color(0xFF8EA3B6);
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? const Color(0x332091FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: active ? activeColor : idleColor, size: 20),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : idleColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String? _extractPitchClass(String? note) {
  if (note == null || note.isEmpty) {
    return null;
  }
  final match = RegExp(r'^([A-Ga-g])([#b]?)').firstMatch(note);
  if (match == null) {
    return note;
  }
  final letter = match.group(1)!.toUpperCase();
  final accidental = match.group(2)!;
  return '$letter$accidental';
}

double? _targetHzForNote(String? note, double a4Hz) {
  if (note == null || note.isEmpty) {
    return null;
  }
  final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d+)$').firstMatch(note);
  if (match == null) {
    return null;
  }
  final letter = match.group(1)!.toUpperCase();
  final accidental = match.group(2)!;
  final octave = int.tryParse(match.group(3)!);
  if (octave == null) {
    return null;
  }
  const semitones = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };
  final base = semitones[letter];
  if (base == null) {
    return null;
  }
  var midi = (octave + 1) * 12 + base;
  if (accidental == '#') {
    midi += 1;
  } else if (accidental == 'b') {
    midi -= 1;
  }
  return a4Hz * math.pow(2, (midi - 69) / 12).toDouble();
}

Color _barColorForCents(double cents) {
  final distance = cents.abs();
  if (distance <= 8) {
    return const Color(0xFF19D39C);
  }
  if (distance <= 26) {
    return const Color(0xFFF2A341);
  }
  return const Color(0xFFE25555);
}
