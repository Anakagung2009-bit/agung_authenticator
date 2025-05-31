import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);
  final TextEditingController searchController;
  final VoidCallback onMenuPressed;

  const CustomAppBar({
    Key? key,
    required this.searchController,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _searchFocusController;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus != _isSearchFocused) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
        if (_isSearchFocused) {
          _searchFocusController.forward();
        } else {
          _searchFocusController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchFocusController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final hasValidPhoto = user?.photoURL != null &&
                         user!.photoURL!.isNotEmpty &&
                         (user.photoURL!.startsWith('http://') || user.photoURL!.startsWith('https://'));

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: false,
      titleSpacing: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Symbols.menu_rounded,
            color: colorScheme.onSurface,
            weight: 500,
            size: 28,
            fill: 0.2,
          ),
          onPressed: widget.onMenuPressed,
          tooltip: 'Menu',
          iconSize: 28,
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            backgroundColor: Colors.transparent,
            hoverColor: colorScheme.onSurface.withOpacity(0.08),
            highlightColor: colorScheme.onSurface.withOpacity(0.12),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: AnimatedBuilder(
          animation: _searchFocusController,
          builder: (context, child) {
            return SearchBar(
              controller: widget.searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search Authentication Code',
              leading: Icon(
                Symbols.search_rounded,
                color: _isSearchFocused
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
                weight: 500,
                fill: _isSearchFocused ? 1 : 0,
              ),
              padding: MaterialStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              elevation: MaterialStateProperty.all<double>(0),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.focused)) {
                    return colorScheme.surfaceContainerHigh;
                  }
                  return colorScheme.surfaceContainerLow;
                },
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: _isSearchFocused
                        ? colorScheme.primary.withOpacity(0.5)
                        : colorScheme.outline.withOpacity(0.2),
                    width: _isSearchFocused ? 1.5 : 1.0,
                  ),
                ),
              ),
              overlayColor: MaterialStateProperty.all<Color>(
                colorScheme.onSurface.withOpacity(0.05),
              ),
            );
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // Handle profile tap
              },
              splashColor: colorScheme.primary.withOpacity(0.1),
              highlightColor: colorScheme.primary.withOpacity(0.05),
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: hasValidPhoto
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoURL!),
                        radius: 20,
                      )
                    : CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        radius: 20,
                        child: Icon(
                          Symbols.account_circle_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 24,
                          weight: 500,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}