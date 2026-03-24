import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';

/// Service for scraping website data to auto-populate card fields
class WebsiteScraperService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));
  
  final _unescape = HtmlUnescape();
  
  /// Extract domain from email address
  String? extractDomainFromEmail(String email) {
    if (!email.contains('@')) return null;
    final domain = email.split('@').last;
    // Skip common personal email domains
    final personalDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'aol.com', 'icloud.com', 'me.com', 'qq.com', '163.com',
      'protonmail.com', 'zoho.com', 'yandex.com', 'mail.com',
      'live.com', 'msn.com', 'ymail.com'
    ];
    if (personalDomains.contains(domain.toLowerCase())) return null;
    return domain;
  }
  
  /// Extract company name from email domain
  String? extractCompanyFromDomain(String domain) {
    // Remove common TLDs and subdomains
    String company = domain.toLowerCase();
    
    // Remove www. prefix
    if (company.startsWith('www.')) {
      company = company.substring(4);
    }
    
    // Remove subdomains (e.g., mail.google.com -> google.com)
    final parts = company.split('.');
    if (parts.length > 2) {
      // Check if last two parts form a known TLD
      final tld = parts.sublist(parts.length - 2).join('.');
      final commonTlds = ['co.uk', 'co.jp', 'co.in', 'com.au', 'com.br', 'com.mx'];
      if (commonTlds.contains(tld)) {
        company = parts.sublist(parts.length - 3, parts.length - 2).join('.');
      } else {
        company = parts.sublist(parts.length - 2, parts.length - 1).join('.');
      }
    } else if (parts.length == 2) {
      company = parts[0];
    }
    
    // Capitalize first letter of each word
    return company.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  /// Scrape website metadata
  Future<WebsiteMetadata> scrapeWebsite(String url) async {
    // Ensure URL has protocol
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    try {
      final response = await _dio.get(url);
      final html = response.data as String;
      
      return WebsiteMetadata(
        title: _extractTitle(html),
        description: _extractDescription(html),
        logoUrl: await _extractLogoUrl(html, url),
        brandColors: _extractBrandColors(html),
        companyName: _extractCompanyName(html, url),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw WebsiteScraperException('Connection timeout. Please try again.');
      }
      throw WebsiteScraperException('Failed to fetch website: ${e.message}');
    } catch (e) {
      throw WebsiteScraperException('Failed to scrape website: $e');
    }
  }
  
  /// Extract title from HTML
  String? _extractTitle(String html) {
    // Try og:title first
    final ogTitle = _extractMetaTag(html, 'og:title');
    if (ogTitle != null && ogTitle.isNotEmpty) return _cleanText(ogTitle);
    
    // Try standard title tag
    final titleMatch = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
        .firstMatch(html);
    if (titleMatch != null) {
      final title = _cleanText(titleMatch.group(1) ?? '');
      if (title.isNotEmpty) return title;
    }
    
    return null;
  }
  
  /// Extract description from HTML
  String? _extractDescription(String html) {
    // Try og:description
    final ogDesc = _extractMetaTag(html, 'og:description');
    if (ogDesc != null && ogDesc.isNotEmpty) return _cleanText(ogDesc);
    
    // Try description meta tag
    final desc = _extractMetaTag(html, 'description');
    if (desc != null && desc.isNotEmpty) return _cleanText(desc);
    
    return null;
  }
  
  /// Extract logo URL from HTML
  Future<String?> _extractLogoUrl(String html, String baseUrl) async {
    // Try og:image first
    String? logoUrl = _extractMetaTag(html, 'og:image');
    
    // Try schema.org logo
    if (logoUrl == null) {
      final schemaMatch = RegExp(
        r'"logo"\s*:\s*"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(html);
      if (schemaMatch != null) {
        logoUrl = schemaMatch.group(1);
      }
    }
    
    // Try common logo selectors
    if (logoUrl == null) {
      final patterns = [
        r'<img[^>]*class="[^"]*logo[^"]*"[^>]*src="([^"]+)"',
        r'<img[^>]*src="([^"]*logo[^"]*)"',
        r'<a[^>]*class="[^"]*brand[^"]*"[^>]*>\s*<img[^>]*src="([^"]+)"',
      ];
      
      for (final pattern in patterns) {
        final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
        if (match != null) {
          logoUrl = match.group(1);
          break;
        }
      }
    }
    
    // Try favicon
    if (logoUrl == null) {
      final faviconMatch = RegExp(
        r'<link[^>]*rel="(?:shortcut\s+)?icon"[^>]*href="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(html);
      if (faviconMatch != null) {
        logoUrl = faviconMatch.group(1);
      }
    }
    
    // Convert relative URLs to absolute
    if (logoUrl != null && !logoUrl.startsWith('http')) {
      final uri = Uri.parse(baseUrl);
      if (logoUrl.startsWith('/')) {
        logoUrl = '${uri.scheme}://${uri.host}$logoUrl';
      } else {
        logoUrl = '$baseUrl/$logoUrl';
      }
    }
    
    // Validate the logo URL is accessible
    if (logoUrl != null) {
      final isValid = await _validateImageUrl(logoUrl);
      if (!isValid) return null;
    }
    
    return logoUrl;
  }
  
  /// Extract brand colors from HTML
  List<String> _extractBrandColors(String html) {
    final colors = <String>{};
    
    // Try theme-color meta tag
    final themeColor = _extractMetaTag(html, 'theme-color');
    if (themeColor != null && themeColor.isNotEmpty) {
      colors.add(themeColor);
    }
    
    // Try msapplication-TileColor
    final msColor = _extractMetaTag(html, 'msapplication-TileColor');
    if (msColor != null && msColor.isNotEmpty) {
      colors.add(msColor);
    }
    
    // Extract colors from CSS
    final cssColorPattern = RegExp(
      r'(?:background|color|border-color)\s*:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|rgb\([^)]+\))',
      caseSensitive: false,
    );
    
    final matches = cssColorPattern.allMatches(html);
    for (final match in matches) {
      final color = match.group(1);
      if (color != null && !color.contains('255,255,255') && !color.contains('000000')) {
        colors.add(color);
      }
    }
    
    return colors.toList();
  }
  
  /// Extract company name from HTML or URL
  String? _extractCompanyName(String html, String url) {
    // Try og:site_name first
    final siteName = _extractMetaTag(html, 'og:site_name');
    if (siteName != null && siteName.isNotEmpty) {
      return _cleanText(siteName);
    }
    
    // Try application-name
    final appName = _extractMetaTag(html, 'application-name');
    if (appName != null && appName.isNotEmpty) {
      return _cleanText(appName);
    }
    
    // Extract from domain
    final uri = Uri.parse(url);
    return extractCompanyFromDomain(uri.host);
  }
  
  /// Extract meta tag content
  String? _extractMetaTag(String html, String property) {
    // Try property attribute (Open Graph)
    var pattern = RegExp(
      '<meta[^>]*property="$property"[^>]*content="([^"]*)"',
      caseSensitive: false,
    );
    var match = pattern.firstMatch(html);
    if (match != null) return match.group(1);
    
    // Try name attribute
    pattern = RegExp(
      '<meta[^>]*name="$property"[^>]*content="([^"]*)"',
      caseSensitive: false,
    );
    match = pattern.firstMatch(html);
    if (match != null) return match.group(1);
    
    // Try content first, then property/name
    pattern = RegExp(
      '<meta[^>]*content="([^"]*)"[^>]*(?:property|name)="$property"',
      caseSensitive: false,
    );
    match = pattern.firstMatch(html);
    if (match != null) return match.group(1);
    
    return null;
  }
  
  /// Clean and decode HTML text
  String _cleanText(String text) {
    return _unescape
        .convert(text)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  /// Validate if image URL is accessible
  Future<bool> _validateImageUrl(String url) async {
    try {
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Metadata extracted from a website
class WebsiteMetadata {
  final String? title;
  final String? description;
  final String? logoUrl;
  final List<String> brandColors;
  final String? companyName;
  
  const WebsiteMetadata({
    this.title,
    this.description,
    this.logoUrl,
    this.brandColors = const [],
    this.companyName,
  });
  
  bool get hasData => 
      title != null || 
      description != null || 
      logoUrl != null || 
      companyName != null;
}

/// Exception for website scraping errors
class WebsiteScraperException implements Exception {
  final String message;
  WebsiteScraperException(this.message);
  
  @override
  String toString() => 'WebsiteScraperException: $message';
}
