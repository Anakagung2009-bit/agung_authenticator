import 'package:flutter/material.dart';

class TimerHeader extends StatefulWidget {
  final int timeLeft;

  const TimerHeader({
    Key? key,
    required this.timeLeft,
  }) : super(key: key);

  @override
  State<TimerHeader> createState() => _TimerHeaderState();
}

class _TimerHeaderState extends State<TimerHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.timeLeft < 10) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TimerHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.timeLeft < 10 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.timeLeft >= 10 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowTime = widget.timeLeft < 10;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Authentication Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowTime
                          ? Color.lerp(
                              colorScheme.errorContainer,
                              colorScheme.error,
                              _pulseController.value,
                            )
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isLowTime
                          ? [
                              BoxShadow(
                                color: colorScheme.error.withOpacity(0.3 * _pulseController.value),
                                blurRadius: 4 * _pulseController.value,
                                spreadRadius: 1 * _pulseController.value,
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      '${widget.timeLeft} s',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLowTime
                            ? colorScheme.onError
                            : colorScheme.onTertiaryContainer,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: widget.timeLeft / 30,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.timeLeft < 5
                      ? Color.lerp(
                          colorScheme.error,
                          colorScheme.errorContainer,
                          _pulseController.value,
                        )!
                      : colorScheme.primary
                  ),
                  minHeight: 4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}