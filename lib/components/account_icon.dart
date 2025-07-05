import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/icon_service.dart';

class AccountIcon extends StatelessWidget {
  final String accountType;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AccountIcon({
    Key? key,
    required this.accountType,
    this.size = 28,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconUrl = IconService.getIconUrl(accountType);

    if (iconUrl != null) {
      return CachedNetworkImage(
        imageUrl: iconUrl,
        width: size,
        height: size,
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor ?? colorScheme.onSecondaryContainer,
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          _getFallbackIcon(accountType),
          size: size,
          color: iconColor ?? colorScheme.onSecondaryContainer,
        ),
      );
    }

    return Icon(
      _getFallbackIcon(accountType),
      size: size,
      color: iconColor ?? colorScheme.onSecondaryContainer,
    );
  }

  IconData _getFallbackIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'microsoft':
        return Icons.window;
      case 'discord':
        return Icons.discord;
      case 'tiktok':
        return Icons.music_note;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'github':
        return Icons.code;
      case 'linkedin':
        return Icons.work;
      case 'amazon':
        return Icons.shopping_cart;
      case 'apple':
        return Icons.apple;
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      default:
        return Icons.lock;
    }
  }
}