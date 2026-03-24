/// Story 3.5: 22+ social/contact platform definitions
class SocialPlatform {
  final String id;
  final String name;
  final String icon; // Material icon name for reference
  final String baseUrl;
  final String placeholder;

  const SocialPlatform({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUrl,
    required this.placeholder,
  });
}

const List<SocialPlatform> socialPlatforms = [
  SocialPlatform(
    id: 'phone',
    name: 'Phone',
    icon: 'phone',
    baseUrl: 'tel:',
    placeholder: '+1 234 567 8900',
  ),
  SocialPlatform(
    id: 'email',
    name: 'Email',
    icon: 'email',
    baseUrl: 'mailto:',
    placeholder: 'you@example.com',
  ),
  SocialPlatform(
    id: 'link',
    name: 'Link',
    icon: 'link',
    baseUrl: '',
    placeholder: 'https://',
  ),
  SocialPlatform(
    id: 'address',
    name: 'Address',
    icon: 'location_on',
    baseUrl: '',
    placeholder: '123 Street, City',
  ),
  SocialPlatform(
    id: 'website',
    name: 'Website',
    icon: 'language',
    baseUrl: '',
    placeholder: 'https://yourwebsite.com',
  ),
  SocialPlatform(
    id: 'linkedin',
    name: 'LinkedIn',
    icon: 'work',
    baseUrl: 'https://linkedin.com/in/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'instagram',
    name: 'Instagram',
    icon: 'photo_camera',
    baseUrl: 'https://instagram.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'calendly',
    name: 'Calendly',
    icon: 'calendar_today',
    baseUrl: 'https://calendly.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'x',
    name: 'X (Twitter)',
    icon: 'close',
    baseUrl: 'https://x.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'facebook',
    name: 'Facebook',
    icon: 'facebook',
    baseUrl: 'https://facebook.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'threads',
    name: 'Threads',
    icon: 'chat',
    baseUrl: 'https://threads.net/@',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'snapchat',
    name: 'Snapchat',
    icon: 'camera',
    baseUrl: 'https://snapchat.com/add/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'tiktok',
    name: 'TikTok',
    icon: 'music_note',
    baseUrl: 'https://tiktok.com/@',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'youtube',
    name: 'YouTube',
    icon: 'play_circle',
    baseUrl: 'https://youtube.com/@',
    placeholder: 'channel',
  ),
  SocialPlatform(
    id: 'github',
    name: 'GitHub',
    icon: 'code',
    baseUrl: 'https://github.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'yelp',
    name: 'Yelp',
    icon: 'store',
    baseUrl: 'https://yelp.com/biz/',
    placeholder: 'business',
  ),
  SocialPlatform(
    id: 'venmo',
    name: 'Venmo',
    icon: 'payments',
    baseUrl: 'https://venmo.com/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'paypal',
    name: 'PayPal',
    icon: 'payment',
    baseUrl: 'https://paypal.me/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'cashapp',
    name: 'Cash App',
    icon: 'attach_money',
    baseUrl: 'https://cash.app/\$',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'discord',
    name: 'Discord',
    icon: 'headset_mic',
    baseUrl: '',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'signal',
    name: 'Signal',
    icon: 'shield',
    baseUrl: '',
    placeholder: 'phone number',
  ),
  SocialPlatform(
    id: 'skype',
    name: 'Skype',
    icon: 'video_call',
    baseUrl: 'skype:',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'telegram',
    name: 'Telegram',
    icon: 'send',
    baseUrl: 'https://t.me/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'twitch',
    name: 'Twitch',
    icon: 'tv',
    baseUrl: 'https://twitch.tv/',
    placeholder: 'username',
  ),
  SocialPlatform(
    id: 'whatsapp',
    name: 'WhatsApp',
    icon: 'chat',
    baseUrl: 'https://wa.me/',
    placeholder: '+1234567890',
  ),
];
