class IconService {
  static const Map<String, String> _iconUrls = {
    'google': 'https://img.icons8.com/color/48/google-logo.png',
    'microsoft': 'https://img.icons8.com/color/48/microsoft.png',
    'discord': 'https://img.icons8.com/color/48/discord-logo.png',
    'tiktok': 'https://img.icons8.com/color/48/tiktok.png',
    'facebook': 'https://img.icons8.com/color/48/facebook-new.png',
    'twitter': 'https://img.icons8.com/color/48/twitter.png',
    'instagram': 'https://img.icons8.com/color/48/instagram-new.png',
    'github': 'https://img.icons8.com/color/48/github.png',
    'linkedin': 'https://img.icons8.com/color/48/linkedin.png',
    'amazon': 'https://img.icons8.com/color/48/amazon.png',
    'apple': 'https://img.icons8.com/color/48/mac-os.png',
    'netflix': 'https://img.icons8.com/color/48/netflix.png',
    'spotify': 'https://img.icons8.com/color/48/spotify.png',
  };

  static String? getIconUrl(String accountType) {
    return _iconUrls[accountType.toLowerCase()];
  }

  static bool hasCustomIcon(String accountType) {
    return _iconUrls.containsKey(accountType.toLowerCase());
  }
}