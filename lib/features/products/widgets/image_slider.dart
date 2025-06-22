import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/index.dart';
import 'package:dots_indicator/dots_indicator.dart';

class ImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double aspectRatio;

  const ImageSlider({
    super.key,
    required this.imageUrls,
    this.aspectRatio = 1.0,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  double _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: ColorPalette.placeholder,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Image Slider
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index.toDouble();
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: ColorPalette.placeholder,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: ColorPalette.placeholder,
                  child: const Icon(Icons.error),
                ),
              );
            },
          ),
        ),
        
        // Dots Indicator
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            child: DotsIndicator(
              dotsCount: widget.imageUrls.length,
              position: _currentPage,
              decorator: DotsDecorator(
                color: ColorPalette.placeholder,
                activeColor: ColorPalette.primary,
                size: const Size.square(8.0),
                activeSize: const Size(16.0, 8.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 