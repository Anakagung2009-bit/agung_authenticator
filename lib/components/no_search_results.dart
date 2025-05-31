import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NoSearchResults extends StatefulWidget {
  const NoSearchResults({Key? key}) : super(key: key);

  @override
  State<NoSearchResults> createState() => _NoSearchResultsState();
}

class _NoSearchResultsState extends State<NoSearchResults> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Symbols.search_off_rounded, 
                  size: 48, 
                  color: colorScheme.onSurfaceVariant,
                  weight: 300,
                  fill: 1,
                ),
              ),
            ),
            SizedBox(height: 24),
            AnimatedOpacity(
              opacity: _animationController.value,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'No matching results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _animationController.value,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Try using different keywords',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}