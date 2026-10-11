import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double emojiSize;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.emoji = '🌿',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.emojiSize = 34,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback = Center(
      child: Text(
        emoji.isNotEmpty ? emoji : '🌿',
        style: TextStyle(fontSize: emojiSize),
      ),
    );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _clip(fallback);
    }

    final url = imageUrl!.trim();
    Widget imgWidget;

    try {
      if (url.startsWith('data:image/') && url.contains(';base64,')) {
        final base64String = url.split(';base64,').last;
        final bytes = base64Decode(base64String);
        imgWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        imgWidget = Image.network(
          url,
          headers: AppConfig.defaultHeaders,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else if (url.startsWith('/uploads') ||
          url.startsWith('/products') ||
          url.startsWith('/shops') ||
          url.startsWith('/avatars')) {
        final fullUrl = '${AppConfig.baseUrl}$url';
        imgWidget = Image.network(
          fullUrl,
          headers: AppConfig.defaultHeaders,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else if (url.startsWith('/') ||
          url.startsWith('file://') ||
          (url.length > 2 && url[1] == ':')) {
        final cleanPath =
            url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
        final file = File(cleanPath);
        if (file.existsSync()) {
          imgWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback,
          );
        } else {
          final fullUrl = '${AppConfig.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
          imgWidget = Image.network(
            fullUrl,
            headers: AppConfig.defaultHeaders,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback,
          );
        }
      } else {
        final fullUrl = '${AppConfig.baseUrl}/$url';
        imgWidget = Image.network(
          fullUrl,
          headers: AppConfig.defaultHeaders,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    } catch (_) {
      imgWidget = fallback;
    }

    return _clip(imgWidget);
  }

  Widget _clip(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}
