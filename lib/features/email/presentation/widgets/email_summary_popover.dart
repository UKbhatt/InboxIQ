import 'package:flutter/material.dart';

class EmailSummaryPopover extends StatelessWidget {
  final String summary;
  final bool isLoading;
  final VoidCallback onDismiss;
  final GlobalKey buttonKey;

  const EmailSummaryPopover({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onDismiss,
    required this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            _PositionedPopover(
              buttonKey: buttonKey,
              child: _PopoverContent(
                summary: summary,
                isLoading: isLoading,
                onDismiss: onDismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PopoverContent extends StatelessWidget {
  final String summary;
  final bool isLoading;
  final VoidCallback onDismiss;

  const _PopoverContent({
    required this.summary,
    required this.isLoading,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Summary',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isLoading)
                const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.3,
                      ),
                ),
            ],
          ),
        ),

        Positioned(
          left: -6,
          top: 22,
          child: CustomPaint(
            size: const Size(12, 16),
            painter: _BubbleTailPainter(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }
}



class _PositionedPopover extends StatelessWidget {
  final GlobalKey buttonKey;
  final Widget child;

  const _PositionedPopover({
    required this.buttonKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return Positioned(top: 80, right: 16, child: child);
    }

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    const popoverHeight = 120.0;
    const gap = 6.0;

    bool showAbove =
        buttonOffset.dy > popoverHeight + 40;

    final double top = showAbove
        ? buttonOffset.dy - popoverHeight - gap
        : buttonOffset.dy + buttonSize.height + gap;

    return Positioned(
      top: top.clamp(8.0, screenHeight - popoverHeight - 8.0),
      right: 16.0,
      child: child,
    );
  }
}



class _BubbleTailPainter extends CustomPainter {
  final Color color;

  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(size.width, size.height / 2 - 6)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2 + 6)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
