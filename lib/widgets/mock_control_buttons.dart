import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show AppColors;

class MockControlButtons extends StatefulWidget {
  final bool isMocking;
  final bool isLoading;
  final VoidCallback onStartMock;
  final VoidCallback onStopMock;
  final VoidCallback onOpenRouteSimulation;

  const MockControlButtons({
    super.key,
    required this.isMocking,
    required this.isLoading,
    required this.onStartMock,
    required this.onStopMock,
    required this.onOpenRouteSimulation,
  });

  @override
  State<MockControlButtons> createState() => _MockControlButtonsState();
}

class _MockControlButtonsState extends State<MockControlButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Start / Stop row
        Row(children: [
          Expanded(child: _StartButton(
            isMocking: widget.isMocking,
            isLoading: widget.isLoading,
            glow: _glow,
            onPressed: widget.isLoading || widget.isMocking ? null : widget.onStartMock,
          )),
          const SizedBox(width: 10),
          Expanded(child: _StopButton(
            isMocking: widget.isMocking,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading || !widget.isMocking ? null : widget.onStopMock,
          )),
        ]),
        const SizedBox(height: 10),
        // Route Simulation button
        _RouteButton(onTap: widget.onOpenRouteSimulation),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool isMocking;
  final bool isLoading;
  final Animation<double> glow;
  final VoidCallback? onPressed;

  const _StartButton({
    required this.isMocking,
    required this.isLoading,
    required this.glow,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        return GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: enabled ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled ? Colors.transparent : AppColors.border,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glow.value),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (isLoading && !isMocking)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(
                  isMocking ? Icons.radar_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: enabled ? Colors.white : AppColors.textSecondary,
                ),
              const SizedBox(width: 8),
              Text(
                isMocking ? 'Running' : 'Start Mock',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _StopButton extends StatelessWidget {
  final bool isMocking;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _StopButton({
    required this.isMocking,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.error.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? AppColors.error.withValues(alpha: 0.6)
                : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading && isMocking)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: enabled ? AppColors.error : AppColors.textSecondary,
              ),
            )
          else
            Icon(
              Icons.stop_rounded,
              size: 18,
              color: enabled ? AppColors.error : AppColors.textSecondary,
            ),
          const SizedBox(width: 8),
          Text(
            'Stop',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: enabled ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ]),
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RouteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ).createShader(r),
            child: const Icon(Icons.route_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ).createShader(r),
            child: Text(
              'Route Simulation',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
