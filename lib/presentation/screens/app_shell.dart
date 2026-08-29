import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_localizations.dart';
import '../../app/we_band_theme.dart';
import '../bloc/metronome_bloc.dart';
import '../bloc/metronome_event.dart';
import '../bloc/tuner_bloc.dart';
import '../bloc/tuner_event.dart';
import 'app_audio_lifecycle.dart';
import 'metronome_screen.dart';
import 'tuner_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldStopAudioForLifecycle(state)) {
      context.read<TunerBloc>().add(const StopListening());
      context.read<MetronomeBloc>().add(const MetronomeStopped());
    }
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) {
      return;
    }
    if (_selectedIndex == 0) {
      context.read<TunerBloc>().add(const StopListening());
    } else {
      context.read<MetronomeBloc>().add(const MetronomeStopped());
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WeBandTheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TunerScreen(),
          MetronomeScreen(),
        ],
      ),
      bottomNavigationBar: _AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectDestination,
      ),
    );
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171B23), Color(0xFF11151B)],
        ),
        border: Border(top: BorderSide(color: WeBandTheme.outlineMuted)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavigationDestination(
              key: const ValueKey('nav-tuner'),
              icon: Icons.graphic_eq_rounded,
              label: l10n.tuner,
              active: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _NavigationDestination(
              key: const ValueKey('nav-metronome'),
              icon: Icons.timer_outlined,
              label: l10n.metronome,
              active: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? WeBandTheme.brandRed : WeBandTheme.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 132,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? WeBandTheme.brandRed.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
