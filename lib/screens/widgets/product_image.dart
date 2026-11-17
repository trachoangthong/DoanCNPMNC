import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';

class ProductImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final String imageSource = source.trim();
    final Uri? uri = Uri.tryParse(imageSource);
    final bool isNetworkImage =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    final Widget image = isNetworkImage
        ? Image.network(
            imageSource,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder:
                (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  final int? expectedBytes = loadingProgress.expectedTotalBytes;
                  return SizedBox(
                    width: width,
                    height: height,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: expectedBytes == null
                            ? null
                            : loadingProgress.cumulativeBytesLoaded /
                                  expectedBytes,
                      ),
                    ),
                  );
                },
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  debugPrint(
                    'Failed to load product image "$imageSource": $error',
                  );
                  return _buildFallback(context, error, stackTrace);
                },
          )
        : Image.asset(
            AppAssets.getImage(imageSource),
            fit: fit,
            width: width,
            height: height,
            errorBuilder: _buildFallback,
          );
    return image;
  }

  Widget _buildFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}
