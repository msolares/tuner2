import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_localizations.dart';
import '../../app/app_theme.dart';
import '../../domain/entities/metronome_settings.dart';
import '../../domain/entities/time_signature.dart';
import '../../domain/services/time_signature_catalog.dart';
import '../bloc/metronome_bloc.dart';
import '../bloc/metronome_event.dart';
import '../bloc/metronome_state.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  int _selectedBeat = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetronomeBloc, MetronomeState>(
      builder: (context, state) {
        final settings = state.settings;
        final selectedBeat = _selectedBeat.clamp(0, settings.beats.length - 1);
        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton.large(
            key: const ValueKey('metronome-primary-action'),
            elevation: 0,
            onPressed: () => context.read<MetronomeBloc>().add(
                  state.isPlaying
                      ? const MetronomeStopped()
                      : const MetronomeStarted(),
                ),
            child: Icon(
              state.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 34,
            ),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF071A2A),
                  Color(0xFF04111D),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    key: const ValueKey('metronome-scroll'),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                    children: [
                      _Header(isPlaying: state.isPlaying),
                      const SizedBox(height: 18),
                      _TempoCard(state: state),
                      const SizedBox(height: 18),
                      _SignatureCard(
                        signature: settings.timeSignature,
                        onCustomRequested: () => _showCustomSignature(
                          context,
                          settings.timeSignature,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _BeatSequence(
                        settings: settings,
                        activeBeatIndex: state.activeBeatIndex,
                        activeSubdivisionIndex: state.activeSubdivisionIndex,
                        selectedBeatIndex: selectedBeat,
                        onSelected: (index) {
                          setState(() => _selectedBeat = index);
                        },
                      ),
                      const SizedBox(height: 18),
                      _BeatEditor(
                        beatIndex: selectedBeat,
                        beat: settings.beats[selectedBeat],
                        denominator: settings.timeSignature.denominator,
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: state.errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomSignature(
    BuildContext context,
    TimeSignature current,
  ) async {
    final l10n = AppLocalizations.of(context);
    var numerator = current.numerator;
    var denominator = current.denominator;
    final result = await showDialog<TimeSignature>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.customTimeSignature),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: numerator,
                  decoration: InputDecoration(labelText: l10n.beats),
                  items: [
                    for (var value = 1; value <= 16; value++)
                      DropdownMenuItem(value: value, child: Text('$value')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => numerator = value);
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('/', style: TextStyle(fontSize: 30)),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: denominator,
                  decoration: InputDecoration(labelText: l10n.noteValue),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 4, child: Text('4')),
                    DropdownMenuItem(value: 8, child: Text('8')),
                    DropdownMenuItem(value: 16, child: Text('16')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => denominator = value);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                TimeSignature(
                  numerator: numerator,
                  denominator: denominator,
                ),
              ),
              child: Text(l10n.apply),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      context.read<MetronomeBloc>().add(TimeSignatureChanged(result));
      setState(() => _selectedBeat = 0);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isPlaying});
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surfaceStrong.withValues(alpha: 0.88),
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppTheme.tuneBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.metronome,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.2,
                      ),
                ),
                Text(
                  isPlaying ? l10n.playingPattern : l10n.readyToPractice,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isPlaying ? AppTheme.tuneGreen : AppTheme.surfaceStrong)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPlaying ? l10n.playing : l10n.ready,
              style: TextStyle(
                color: isPlaying ? AppTheme.tuneGreen : AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempoCard extends StatelessWidget {
  const _TempoCard({required this.state});
  final MetronomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bpm = state.settings.bpm;
    return Container(
      key: const ValueKey('metronome-tempo-card'),
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            l10n.tempo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 1.8,
                ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: l10n.decreaseTempo,
                onPressed: () =>
                    context.read<MetronomeBloc>().add(TempoChanged(bpm - 1)),
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Semantics(
                    label: l10n.bpmSemantics(bpm),
                    child: Text(
                      '$bpm',
                      key: const ValueKey('metronome-bpm'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 92,
                            height: 1,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: l10n.increaseTempo,
                onPressed: () =>
                    context.read<MetronomeBloc>().add(TempoChanged(bpm + 1)),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Text(
            'BPM',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.brandRed,
                  letterSpacing: 1.4,
                ),
          ),
          Slider(
            value: bpm.toDouble(),
            min: MetronomeSettings.minBpm.toDouble(),
            max: MetronomeSettings.maxBpm.toDouble(),
            divisions: MetronomeSettings.maxBpm - MetronomeSettings.minBpm,
            label: '$bpm BPM',
            onChanged: (value) =>
                context.read<MetronomeBloc>().add(TempoChanged(value.round())),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('tap-tempo-button'),
              onPressed: () =>
                  context.read<MetronomeBloc>().add(const TapTempoPressed()),
              icon: const Icon(Icons.touch_app_rounded),
              label: Text(l10n.tapTempo),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.signature,
    required this.onCustomRequested,
  });

  final TimeSignature signature;
  final VoidCallback onCustomRequested;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presets = const DefaultTimeSignatureCatalog().presets;
    final isPreset = presets.contains(signature);
    final values = isPreset ? presets : [signature, ...presets];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.timeSignature,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final selector = DropdownButtonFormField<TimeSignature>(
                key: ValueKey('time-signature-selector-$signature'),
                initialValue: signature,
                decoration: InputDecoration(
                  labelText: l10n.timeSignatureField,
                ),
                items: values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<MetronomeBloc>()
                        .add(TimeSignatureChanged(value));
                  }
                },
              );
              final customButton = OutlinedButton(
                key: const ValueKey('custom-signature-button'),
                onPressed: onCustomRequested,
                child: Text(l10n.customize),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    selector,
                    const SizedBox(height: 10),
                    customButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: selector),
                  const SizedBox(width: 12),
                  customButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BeatSequence extends StatelessWidget {
  const _BeatSequence({
    required this.settings,
    required this.activeBeatIndex,
    required this.activeSubdivisionIndex,
    required this.selectedBeatIndex,
    required this.onSelected,
  });

  final MetronomeSettings settings;
  final int? activeBeatIndex;
  final int? activeSubdivisionIndex;
  final int selectedBeatIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.measurePattern,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < settings.beats.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _BeatTile(
                      index: index,
                      beat: settings.beats[index],
                      denominator: settings.timeSignature.denominator,
                      selected: selectedBeatIndex == index,
                      active: activeBeatIndex == index,
                      activeSubdivision: activeBeatIndex == index
                          ? activeSubdivisionIndex
                          : null,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeatTile extends StatelessWidget {
  const _BeatTile({
    required this.index,
    required this.beat,
    required this.denominator,
    required this.selected,
    required this.active,
    required this.activeSubdivision,
    required this.onTap,
  });

  final int index;
  final BeatConfig beat;
  final int denominator;
  final bool selected;
  final bool active;
  final int? activeSubdivision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isStrong = beat.accent == BeatAccent.strong;
    final isMuted = beat.accent == BeatAccent.muted;
    final borderColor = active
        ? AppTheme.tuneGreen
        : selected
            ? AppTheme.brandRed
            : AppTheme.outline;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.beatSemantics(
        index + 1,
        _accentLabel(beat.accent, l10n),
        _figureLabel(beat.subdivision, denominator, l10n),
      ),
      child: InkWell(
        key: ValueKey('metronome-beat-$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 82,
          height: 132,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.tuneGreen.withValues(alpha: 0.16)
                : AppTheme.surfaceStrong,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: active ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    isStrong
                        ? Icons.bolt_rounded
                        : isMuted
                            ? Icons.volume_off_rounded
                            : Icons.circle,
                    size: isStrong ? 20 : 13,
                    color: isStrong ? AppTheme.brandRed : AppTheme.textMuted,
                  ),
                ],
              ),
              Text(
                _figureSymbol(beat.subdivision, denominator),
                style: TextStyle(
                  fontSize: 28,
                  color: isMuted ? AppTheme.textMuted : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var pulse = 0; pulse < beat.subdivision.pulses; pulse++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeSubdivision == pulse
                            ? AppTheme.tuneGreen
                            : AppTheme.outlineMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeatEditor extends StatelessWidget {
  const _BeatEditor({
    required this.beatIndex,
    required this.beat,
    required this.denominator,
  });

  final int beatIndex;
  final BeatConfig beat;
  final int denominator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isStrong = beat.accent == BeatAccent.strong;
    final isMuted = beat.accent == BeatAccent.muted;
    return Container(
      key: const ValueKey('beat-editor'),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.beat(beatIndex + 1),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                key: const ValueKey('strong-beat-control'),
                selected: isStrong,
                avatar: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(l10n.strongBeat),
                onSelected: (_) => context
                    .read<MetronomeBloc>()
                    .add(StrongBeatChanged(beatIndex)),
              ),
              FilterChip(
                selected: isMuted,
                avatar: const Icon(Icons.volume_off_rounded, size: 18),
                label: Text(l10n.silence),
                onSelected: isStrong
                    ? null
                    : (selected) => context
                        .read<MetronomeBloc>()
                        .add(BeatMutedChanged(beatIndex, selected)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.figureSubdivision,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BeatSubdivision.values
                .map(
                  (subdivision) => ChoiceChip(
                    selected: beat.subdivision == subdivision,
                    label: Text(
                      _figureLabel(subdivision, denominator, l10n),
                    ),
                    onSelected: (_) => context.read<MetronomeBloc>().add(
                          BeatSubdivisionChanged(beatIndex, subdivision),
                        ),
                  ),
                )
                .toList(),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.localizeError(message))),
        ],
      ),
    );
  }
}

String _accentLabel(BeatAccent accent, AppLocalizations l10n) =>
    switch (accent) {
      BeatAccent.strong => l10n.accentLabel('strong'),
      BeatAccent.normal => l10n.accentLabel('normal'),
      BeatAccent.muted => l10n.accentLabel('muted'),
    };

String _figureLabel(
  BeatSubdivision subdivision,
  int denominator,
  AppLocalizations l10n,
) {
  return switch (subdivision) {
    BeatSubdivision.single => l10n.noteName(denominator, plural: false),
    BeatSubdivision.duplet => l10n.noteName(denominator * 2, plural: true),
    BeatSubdivision.triplet =>
      l10n.triplet(l10n.noteName(denominator * 2, plural: true)),
    BeatSubdivision.quadruplet => l10n.noteName(denominator * 4, plural: true),
  };
}

String _figureSymbol(BeatSubdivision subdivision, int denominator) {
  final base = switch (denominator) {
    2 => '𝅗𝅥',
    4 => '♩',
    8 => '♪',
    _ => '♬',
  };
  return switch (subdivision) {
    BeatSubdivision.single => base,
    BeatSubdivision.duplet => '$base×2',
    BeatSubdivision.triplet => '$base×3',
    BeatSubdivision.quadruplet => '$base×4',
  };
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.surface.withValues(alpha: 0.86),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: AppTheme.outline),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  );
}
