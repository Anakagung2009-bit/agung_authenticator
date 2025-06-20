import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeCard extends StatefulWidget {
  final Map<String, dynamic> totp;
  final String code;
  final int timeLeft;
  final VoidCallback onDelete;

  const CodeCard({
    Key? key,
    required this.totp,
    required this.code,
    required this.timeLeft,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<CodeCard> createState() => _CodeCardState();
}

class _CodeCardState extends State<CodeCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _isCopied = true;
    });
    _animationController.forward().then((_) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
          _animationController.reverse();
        }
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Memisahkan kode menjadi dua bagian untuk tampilan yang lebih baik
    final firstHalf = widget.code.substring(0, widget.code.length ~/ 2);
    final secondHalf = widget.code.substring(widget.code.length ~/ 2);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _copyToClipboard(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'icon_${widget.totp['id']}',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.totp['name'].substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.totp['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Code TOTP
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isCopied
                                  ? colorScheme.tertiaryContainer
                                  : colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  firstHalf,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Monospace',
                                    letterSpacing: 1,
                                    color: _isCopied
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  secondHalf,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Monospace',
                                    letterSpacing: 1,
                                    color: _isCopied
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Circular Progress Indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: widget.timeLeft / 30,
                            backgroundColor: colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.timeLeft < 5 ? colorScheme.error : colorScheme.primary,
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        Text(
                          '${widget.timeLeft}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.timeLeft < 5 
                                ? colorScheme.error 
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Authentication Code'),
                            content: Text('Are you sure want to delete "${widget.totp['name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDelete();
                                },
                                child: Text('Delete'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer,
                                  foregroundColor: colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}