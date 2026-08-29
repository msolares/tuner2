import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_localizations.dart';
import '../../app/we_band_theme.dart';
import '../../app/app_version.dart';
import '../../domain/entities/instrument_preset_profile.dart';
import '../../domain/entities/song_tuning_result.dart';
import '../../domain/entities/tuner_settings.dart';
import '../bloc/song_tuning_bloc.dart';
import '../bloc/song_tuning_event.dart';
import '../bloc/song_tuning_state.dart';
import '../bloc/tuner_bloc.dart';
import '../bloc/tuner_event.dart';
import '../bloc/tuner_state.dart';
import 'tuning_display_strings.dart';

const _weBandLogoAsset = 'doc/LOGOS/LOGO_WeBand_LETRAS_BLANCAS-1155x245px.png';
const _weBandBoltAsset = 'doc/LOGOS/SOLO-rayo-ROJO-500x500px.png';
const _isSongTuningVisible = false;

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TunerBloc, TunerState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final sample = state.sample;
        final isListening =
            state is Listening || state is InTune || state is OutOfTune;
        final isInTune = state is InTune;
        final tone = _toneForState(state, l10n);
        final displayNote = _extractPitchClass(sample?.note) ?? '--';
        final currentHz = sample?.hz ?? 0.0;
        final targetHz = _targetHzForNote(sample?.note, state.settings.a4Hz);
        final cents = sample?.cents ?? 0.0;
        final presetLabel = _presetLabelFor(
          state.settings.instrumentPreset,
          l10n,
        );
        final songTuningState = context.watch<SongTuningBloc>().state;
        final useSongTuningResult = _isSongTuningVisible &&
            songTuningState.status == SongTuningStatus.success &&
            songTuningState.result != null;
        final displayStrings = resolveHeaderTuningStrings(
          presetId: state.settings.instrumentPreset,
          songTuningResult: songTuningState.result,
          useSongTuningResult: useSongTuningResult,
        );

        return Scaffold(
          backgroundColor: WeBandTheme.background,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton.large(
            key: const ValueKey('tuner-primary-action'),
            elevation: 0,
            onPressed: () {
              final bloc = context.read<TunerBloc>();
              if (isListening) {
                bloc.add(const StopListening());
              } else {
                bloc.add(const StartListening());
              }
            },
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 34,
            ),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WeBandTheme.background,
                  Color(0xFF0C1015),
                  Color(0xFF08090C),
                ],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -160,
                  right: -120,
                  child: _BackdropGlow(
                    size: 360,
                    color: Color(0x44FF2750),
                  ),
                ),
                const Positioned(
                  bottom: 120,
                  left: -160,
                  child: _BackdropGlow(
                    size: 320,
                    color: Color(0x2220D693),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                        children: [
                          _Header(
                            tone: tone,
                            activePresetId: state.settings.instrumentPreset,
                            presetLabel: presetLabel,
                            a4Hz: state.settings.a4Hz,
                            onPresetSelected: (presetId) {
                              context
                                  .read<TunerBloc>()
                                  .add(SelectPreset(presetId));
                              context
                                  .read<SongTuningBloc>()
                                  .add(const SongTuningResultCleared());
                            },
                          ),
                          const SizedBox(height: 18),
                          _StringSelector(
                            activeNote: displayNote,
                            strings: displayStrings,
                            presetLabel: presetLabel,
                          ),
                          const SizedBox(height: 18),
                          _TunerCore(
                            note: displayNote,
                            hz: currentHz,
                            cents: cents,
                            isInTune: isInTune,
                            tone: tone,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  title: l10n.cents,
                                  value:
                                      '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)}',
                                  accentColor: tone.accentColor,
                                  textColor: tone.noteColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoCard(
                                  title: l10n.target,
                                  value: targetHz == null
                                      ? '-- Hz'
                                      : '${targetHz.toStringAsFixed(2)} Hz',
                                  accentColor: WeBandTheme.brandRed,
                                  textColor: WeBandTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (state is ErrorState) ...[
                            const SizedBox(height: 12),
                            _ErrorBanner(
                              message: l10n.localizeError(state.message),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _SettingsPanel(state: state),
                          if (_isSongTuningVisible) ...[
                            const SizedBox(height: 14),
                            const _SongTuningPanel(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tone,
    required this.activePresetId,
    required this.presetLabel,
    required this.a4Hz,
    required this.onPresetSelected,
  });

  final _TunerTone tone;
  final String activePresetId;
  final String presetLabel;
  final double a4Hz;
  final ValueChanged<String> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final brandIcon = Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: WeBandTheme.surfaceStrong.withOpacity(0.88),
        border: Border.all(color: WeBandTheme.outline),
      ),
      child: Image.asset(
        _weBandBoltAsset,
        filterQuality: FilterQuality.high,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          _weBandLogoAsset,
          key: const ValueKey('tuner-brand-logo'),
          height: 24,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetSelectorChip(
              activePresetId: activePresetId,
              activePresetLabel: presetLabel,
              onSelected: onPresetSelected,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          tone.helperLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: WeBandTheme.textSecondary,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
    final modeBadge = _ModeBadge(a4Hz: a4Hz);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brandIcon,
                    const Spacer(),
                    modeBadge,
                  ],
                ),
                const SizedBox(height: 14),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              brandIcon,
              const SizedBox(width: 14),
              Expanded(child: details),
              const SizedBox(width: 12),
              modeBadge,
            ],
          );
        },
      ),
    );
  }
}

class _PresetSelectorChip extends StatelessWidget {
  const _PresetSelectorChip({
    required this.activePresetId,
    required this.activePresetLabel,
    required this.onSelected,
  });

  final String activePresetId;
  final String activePresetLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticsLabel = l10n.changeTuning(activePresetLabel);
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: PopupMenuButton<String>(
        key: const ValueKey('header-preset-selector'),
        tooltip: semanticsLabel,
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
        color: WeBandTheme.surfaceStrong,
        onSelected: onSelected,
        itemBuilder: (context) => kMvpInstrumentPresets.map((preset) {
          final isActive = preset.id == activePresetId;
          return PopupMenuItem<String>(
            key: ValueKey('preset-option-${preset.id}'),
            value: preset.id,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: isActive
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('active-preset-check'),
                          size: 20,
                          color: WeBandTheme.brandRed,
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    l10n.presetName(
                      preset.id,
                      fallback: preset.displayName,
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: WeBandTheme.textPrimary,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: WeBandTheme.surfaceStrong,
              border: Border.all(
                color: WeBandTheme.textPrimary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    activePresetLabel.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: WeBandTheme.textPrimary,
                          fontSize: 13,
                        ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: WeBandTheme.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.a4Hz});

  final double a4Hz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WeBandTheme.surfaceStrong.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WeBandTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'AUTO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WeBandTheme.brandRed,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'A4 ${a4Hz.toStringAsFixed(1)} Hz',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WeBandTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            appVersionLabel,
            key: ValueKey('app-version-label'),
            style: TextStyle(
              color: WeBandTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StringSelector extends StatelessWidget {
  const _StringSelector({
    required this.activeNote,
    required this.strings,
    required this.presetLabel,
  });

  final String activeNote;
  final List<String> strings;
  final String presetLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('string-selector-card'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                l10n.stringMap,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: WeBandTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              );
              final preset = Text(
                presetLabel.toUpperCase(),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WeBandTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    preset,
                  ],
                );
              }

              return Row(
                children: [
                  title,
                  const Spacer(),
                  Flexible(child: preset),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(strings.length, (index) {
              final item = strings[index];
              final isActive = activeNote.toUpperCase() == item.toUpperCase();
              return Expanded(
                child: _StringNode(
                  index: index + 1,
                  label: item,
                  isActive: isActive,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StringNode extends StatelessWidget {
  const _StringNode({
    required this.index,
    required this.label,
    required this.isActive,
  });

  final int index;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$index',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WeBandTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [WeBandTheme.tuneGreen, Color(0xFF0FAE78)],
                  )
                : null,
            color: isActive ? null : WeBandTheme.surfaceStrong,
            border: Border.all(
              color: isActive ? WeBandTheme.tuneGreen : WeBandTheme.outline,
            ),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x551CDA97),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isActive
                      ? WeBandTheme.background
                      : WeBandTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
          ),
        ),
      ],
    );
  }
}

class _TunerCore extends StatelessWidget {
  const _TunerCore({
    required this.note,
    required this.hz,
    required this.cents,
    required this.isInTune,
    required this.tone,
  });

  final String note;
  final double hz;
  final double cents;
  final bool isInTune;
  final _TunerTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSignal = note != '--';
    return Container(
      key: const ValueKey('tuner-core-card'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF181D24),
            Color(0xFF0F1319),
          ],
        ),
        border: Border.all(color: WeBandTheme.outline),
        boxShadow: [
          BoxShadow(
            color: tone.glowColor.withOpacity(0.18),
            blurRadius: 40,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -80,
            child: _BackdropGlow(
              size: 230,
              color: Color(0x33FF2750),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                child: Image.asset(
                  _weBandBoltAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                l10n.liveTuner,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: WeBandTheme.textMuted,
                      fontSize: 12,
                      letterSpacing: 1.8,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                note,
                key: const ValueKey('current-note-text'),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 132,
                      height: 0.9,
                      color: hasSignal ? tone.noteColor : WeBandTheme.textMuted,
                      shadows: hasSignal
                          ? [
                              Shadow(
                                color: tone.glowColor.withOpacity(0.35),
                                blurRadius: 26,
                              ),
                            ]
                          : null,
                    ),
              ),
              Text(
                '${hz.toStringAsFixed(1)} Hz',
                key: const ValueKey('current-frequency-text'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 44,
                      color: WeBandTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: tone.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tone.statusLabel,
                  key: const ValueKey('tuner-status-text'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tone.statusTextColor,
                        fontSize: 16,
                        letterSpacing: 2.2,
                      ),
                ),
              ),
              const SizedBox(height: 22),
              _SmoothCentsMeter(
                cents: cents,
                hasSignal: hasSignal,
                isInTune: isInTune,
                accentColor: tone.accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmoothCentsMeter extends StatefulWidget {
  const _SmoothCentsMeter({
    required this.cents,
    required this.hasSignal,
    required this.isInTune,
    required this.accentColor,
  });

  final double cents;
  final bool hasSignal;
  final bool isInTune;
  final Color accentColor;

  @override
  State<_SmoothCentsMeter> createState() => _SmoothCentsMeterState();
}

class _SmoothCentsMeterState extends State<_SmoothCentsMeter> {
  static const int _barCount = 29;
  static const double _maxCents = 50.0;
  static const double _inTuneHalfWindowCents = 5.0;
  static const double _lockReleaseCents = 6.5;
  double _animationStart = 0.0;
  double _animationEnd = 0.0;
  double _lastPaintedValue = 0.0;
  int _durationMs = 110;
  bool _centerLock = false;

  @override
  void initState() {
    super.initState();
    _centerLock = widget.hasSignal && widget.isInTune;
    _animationEnd = _visualTarget(widget.cents.clamp(-_maxCents, _maxCents));
    _lastPaintedValue = _animationEnd;
  }

  @override
  void didUpdateWidget(covariant _SmoothCentsMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCenterLock();
    final target = _visualTarget(widget.cents.clamp(-_maxCents, _maxCents));
    final reference = _lastPaintedValue;
    final delta = (target - reference).abs();
    final crossedCenter =
        reference.sign != target.sign && reference != 0.0 && target != 0.0;
    final alpha = switch (delta) {
      < 4.0 => 0.32,
      < 12.0 => 0.48,
      < 24.0 => 0.66,
      _ => 0.88,
    };
    final effectiveAlpha = crossedCenter ? alpha.clamp(0.66, 0.92) : alpha;
    final filtered = reference + (target - reference) * effectiveAlpha;
    final durationMs = switch (delta) {
      < 4.0 => 110,
      < 12.0 => 90,
      < 24.0 => 72,
      _ => 56,
    };
    setState(() {
      _animationStart = reference;
      _animationEnd = filtered;
      _durationMs = durationMs;
    });
  }

  void _updateCenterLock() {
    if (!widget.hasSignal) {
      _centerLock = false;
      return;
    }
    if (widget.isInTune) {
      _centerLock = true;
      return;
    }
    if (_centerLock && widget.cents.abs() <= _lockReleaseCents) {
      return;
    }
    _centerLock = false;
  }

  double _visualTarget(double cents) {
    if (!widget.hasSignal) {
      return 0.0;
    }
    if (_centerLock) {
      return 0.0;
    }
    final absCents = cents.abs();
    final scale = switch (absCents) {
      <= _inTuneHalfWindowCents => 0.26,
      <= 12.0 => 0.52,
      <= 24.0 => 0.76,
      _ => 1.0,
    };
    return cents * scale;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _animationStart, end: _animationEnd),
      duration: Duration(milliseconds: _durationMs),
      curve: Curves.easeOutCubic,
      builder: (context, animatedCents, _) {
        _lastPaintedValue = animatedCents;
        return Column(
          children: [
            SizedBox(
              height: 50,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final markerWidth = _centerLock ? 6.0 : 4.0;
                  final trackWidth = constraints.maxWidth - markerWidth;
                  final ratio = ((animatedCents + _maxCents) / (_maxCents * 2))
                      .clamp(0.0, 1.0);
                  final markerLeft = trackWidth * ratio;
                  final centerBandWidth =
                      trackWidth * (_inTuneHalfWindowCents / _maxCents);
                  final activeColor =
                      _centerLock ? WeBandTheme.tuneGreen : widget.accentColor;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: const Alignment(0, 0.8),
                          child: Container(
                            height: 1,
                            color: WeBandTheme.outlineMuted,
                          ),
                        ),
                      ),
                      Positioned(
                        key: const ValueKey('cents-center-band'),
                        left: (constraints.maxWidth / 2) - centerBandWidth,
                        top: 6,
                        bottom: 6,
                        child: Container(
                          width: centerBandWidth * 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: (_centerLock
                                    ? WeBandTheme.tuneGreen
                                    : Colors.white)
                                .withOpacity(_centerLock ? 0.18 : 0.05),
                            border: Border.all(
                              color: (_centerLock
                                      ? WeBandTheme.tuneGreen
                                      : Colors.white)
                                  .withOpacity(_centerLock ? 0.42 : 0.1),
                            ),
                            boxShadow: _centerLock
                                ? const [
                                    BoxShadow(
                                      color: Color(0x551CDA97),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_barCount, (index) {
                            final mid = (_barCount - 1) / 2;
                            final distanceFromMid = (index - mid).abs();
                            final centsAtBar = -_maxCents +
                                (_maxCents * 2) * (index / (_barCount - 1));
                            final proximity =
                                (1 - ((centsAtBar - animatedCents).abs() / 8))
                                    .clamp(0.0, 1.0);
                            final isCenterBand =
                                centsAtBar.abs() <= _inTuneHalfWindowCents;
                            final baseHeight =
                                11 + (1 - (distanceFromMid / mid)) * 12;
                            final height = baseHeight + proximity * 5;
                            final barColor = switch ((
                              isCenterBand,
                              _centerLock,
                              proximity
                            )) {
                              (true, true, _) => WeBandTheme.tuneGreen,
                              (_, _, > 0.32) => activeColor,
                              (true, _, _) => Colors.white,
                              _ => WeBandTheme.outlineMuted,
                            };
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 4,
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: barColor
                                    .withOpacity(0.2 + (0.6 * proximity)),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ),
                      Positioned(
                        left: (constraints.maxWidth / 2) - 1,
                        top: 8,
                        bottom: 6,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: (_centerLock
                                    ? WeBandTheme.tuneGreen
                                    : Colors.white)
                                .withOpacity(
                              _centerLock ? 0.72 : 0.16,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        key: const ValueKey('cents-marker'),
                        left: markerLeft,
                        top: 1,
                        bottom: 4,
                        child: Container(
                          width: markerWidth,
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor
                                    .withOpacity(_centerLock ? 0.56 : 0.42),
                                blurRadius: _centerLock ? 14 : 10,
                                spreadRadius: _centerLock ? 2 : 1,
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '-50',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WeBandTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WeBandTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '+50',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WeBandTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
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
    required this.accentColor,
    required this.textColor,
  });

  final String title;
  final String value;
  final Color accentColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WeBandTheme.textMuted,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WeBandTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WeBandTheme.danger.withOpacity(0.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: WeBandTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFFFB8C2),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a4 = state.settings.a4Hz;
    return _PanelShell(
      title: l10n.tunerSetup,
      subtitle: 'A4 ${a4.toStringAsFixed(1)} Hz',
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text(
            l10n.calibration,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WeBandTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            '${l10n.noiseGate} '
            '${state.settings.noiseGateDb.toStringAsFixed(1)} dB · '
            '${l10n.smoothing} '
            '${state.settings.smoothing.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WeBandTheme.textMuted,
                ),
          ),
          children: [
            Row(
              children: [
                Text(
                  '${a4.toStringAsFixed(1)} Hz',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 34,
                        color: WeBandTheme.textPrimary,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context
                        .read<TunerBloc>()
                        .add(const UpdateA4(TunerSettings.defaultA4Hz));
                  },
                  child: Text(l10n.resetA4),
                ),
              ],
            ),
            Slider(
              value: a4,
              min: TunerSettings.minA4Hz,
              max: TunerSettings.maxA4Hz,
              divisions:
                  (TunerSettings.maxA4Hz - TunerSettings.minA4Hz).toInt() * 2,
              label: a4.toStringAsFixed(1),
              onChanged: (value) =>
                  context.read<TunerBloc>().add(UpdateA4(value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: WeBandTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WeBandTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SongTuningPanel extends StatelessWidget {
  const _SongTuningPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SongTuningBloc, SongTuningState>(
      builder: (context, state) {
        return _PanelShell(
          title: l10n.songTuning,
          subtitle: l10n.songTuningSubtitle,
          child: Padding(
            key: const ValueKey('song-tuning-panel'),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => context
                      .read<SongTuningBloc>()
                      .add(SongNameChanged(value)),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: WeBandTheme.textPrimary,
                      ),
                  decoration: InputDecoration(
                    labelText: l10n.songName,
                    hintText: l10n.songHint,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.canSubmit
                        ? () => context
                            .read<SongTuningBloc>()
                            .add(const SongTuningSubmitted())
                        : null,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: WeBandTheme.textPrimary,
                            ),
                          )
                        : Text(l10n.queryTuning),
                  ),
                ),
                if (state.status == SongTuningStatus.success &&
                    state.result != null) ...[
                  const SizedBox(height: 12),
                  _SongTuningResultCard(result: state.result!),
                ],
                if (state.status == SongTuningStatus.error &&
                    state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: WeBandTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: WeBandTheme.danger.withOpacity(0.28)),
                    ),
                    child: Text(
                      l10n.localizeError(state.errorMessage!),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFFFB8C2),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SongTuningResultCard extends StatelessWidget {
  const _SongTuningResultCard({required this.result});

  final SongTuningResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WeBandTheme.tuneGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WeBandTheme.tuneGreen.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recommendedTuning,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFBCF4DE),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${result.primaryTuning.displayName}: ${result.primaryTuning.stringsLowToHigh.join(' ')}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFE7FFF4),
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (result.hasAlternatives) ...[
            const SizedBox(height: 8),
            Text(
              l10n.alternatives,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFBCF4DE),
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 4),
            ...result.alternativeTunings.map(
              (alternative) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${alternative.displayName}: ${alternative.stringsLowToHigh.join(' ')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE7FFF4),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _TunerTone {
  const _TunerTone({
    required this.statusLabel,
    required this.helperLabel,
    required this.accentColor,
    required this.noteColor,
    required this.glowColor,
    required this.statusTextColor,
  });

  final String statusLabel;
  final String helperLabel;
  final Color accentColor;
  final Color noteColor;
  final Color glowColor;
  final Color statusTextColor;
}

_TunerTone _toneForState(TunerState state, AppLocalizations l10n) {
  return switch (state) {
    InTune() => _TunerTone(
        statusLabel: l10n.inTune,
        helperLabel: l10n.inTuneHelper,
        accentColor: WeBandTheme.tuneGreen,
        noteColor: WeBandTheme.tuneGreen,
        glowColor: WeBandTheme.tuneGreen,
        statusTextColor: WeBandTheme.background,
      ),
    OutOfTune() => _TunerTone(
        statusLabel: l10n.adjust,
        helperLabel: l10n.adjustHelper,
        accentColor: WeBandTheme.tuneAmber,
        noteColor: WeBandTheme.textPrimary,
        glowColor: WeBandTheme.brandRed,
        statusTextColor: WeBandTheme.background,
      ),
    Listening() => _TunerTone(
        statusLabel: l10n.listening,
        helperLabel: l10n.listeningHelper,
        accentColor: WeBandTheme.brandRed,
        noteColor: WeBandTheme.textPrimary,
        glowColor: WeBandTheme.brandRed,
        statusTextColor: WeBandTheme.textPrimary,
      ),
    ErrorState() => _TunerTone(
        statusLabel: l10n.error,
        helperLabel: l10n.errorHelper,
        accentColor: WeBandTheme.danger,
        noteColor: WeBandTheme.danger,
        glowColor: WeBandTheme.danger,
        statusTextColor: WeBandTheme.textPrimary,
      ),
    _ => _TunerTone(
        statusLabel: l10n.ready,
        helperLabel: l10n.readyHelper,
        accentColor: WeBandTheme.brandRed,
        noteColor: WeBandTheme.textPrimary,
        glowColor: WeBandTheme.brandRed,
        statusTextColor: WeBandTheme.textPrimary,
      ),
  };
}

String _presetLabelFor(String presetId, AppLocalizations l10n) {
  final fallback = kMvpInstrumentPresets
          .where((preset) => preset.id == presetId)
          .map((preset) => preset.displayName)
          .firstOrNull ??
      'Chromatic';
  return l10n.presetName(presetId, fallback: fallback);
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: WeBandTheme.surface.withOpacity(0.86),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: WeBandTheme.outline),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  );
}
