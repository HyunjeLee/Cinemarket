import 'package:carousel_slider/carousel_slider.dart';
import 'package:cinemarket/core/theme/app_colors.dart';
import 'package:cinemarket/core/theme/app_text_style.dart';
import 'package:cinemarket/features/home/model/tmdb_movie.dart';
import 'package:cinemarket/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class BoxOfficeRankingWidget extends StatefulWidget {
  const BoxOfficeRankingWidget({super.key});

  @override
  State<BoxOfficeRankingWidget> createState() => _BoxOfficeRankingWidgetState();
}

class _BoxOfficeRankingWidgetState extends State<BoxOfficeRankingWidget> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HomeViewModel>();
      String formatDate(DateTime dt) {
        return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      }

      vm.loadMovies(formatDate(DateTime.now().subtract(const Duration(days: 1))));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // 1. Determine Viewport Fraction (Item Width Ratio)
        // Web: 25% of screen width, Mobile: 60% of screen width
        final viewportFraction = kIsWeb ? 0.25 : 0.6;
        
        // 2. Calculate Item Width
        final itemWidth = screenWidth * viewportFraction;
        
        // 3. Calculate Carousel Height
        // Aspect Ratio 2:3 -> Height = Width * 1.5
        // Add 60px for text content below the image (Title + Date + Padding)
        final carouselHeight = itemWidth * 1.5 + 60;

        if (vm.isLoading) {
          return SizedBox(
            height: carouselHeight,
            child: Center(child: _LoadingSkeleton(itemWidth: itemWidth)),
          );
        }

        if (vm.errorMessage != null) {
          return Center(child: Text(vm.errorMessage!));
        }

        if (vm.movies.isEmpty) {
          return const Center(child: Text('데이터가 없습니다.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('박스오피스 순위', style: AppTextStyle.headline),
            const SizedBox(height: 20),
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: vm.movies.length,
              options: CarouselOptions(
                height: carouselHeight,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                enlargeFactor: kIsWeb ? 0.1 : 0.15,
                viewportFraction: viewportFraction,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return _MovieCarouselItem(
                  movie: vm.movies[index],
                  isCenter: index == _currentPage,
                );
              },
            ),
            _PageIndicator(
              itemCount: vm.movies.length,
              currentPage: _currentPage,
            ),
          ],
        );
      },
    );
  }
}

class _MovieCarouselItem extends StatelessWidget {
  const _MovieCarouselItem({
    required this.movie,
    required this.isCenter,
  });

  final TmdbMovie movie;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
        : 'https://via.placeholder.com/300x450?text=No+Image';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kIsWeb ? 8.0 : 4.0),
      child: GestureDetector(
        onTap: () {
          context.push('/movies/${movie.id}');
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCenter ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            movie.title,
                            style: AppTextStyle.section,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_border, size: 20, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.releaseDate,
                      style: AppTextStyle.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.itemCount,
    required this.currentPage,
  });

  final int itemCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 12 : 8,
          height: currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index
                ? AppColors.pointAccent
                : AppColors.textPrimary,
          ),
        );
      }),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.itemWidth});

  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final imageHeight = itemWidth * 1.5;

    return Shimmer.fromColors(
      baseColor: AppColors.widgetBackground,
      highlightColor: AppColors.innerWidget,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: itemWidth,
            height: imageHeight,
            decoration: BoxDecoration(
              color: AppColors.widgetBackground,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: itemWidth * 0.6, height: 20, color: AppColors.widgetBackground),
          const SizedBox(height: 6),
          Container(width: itemWidth * 0.3, height: 16, color: AppColors.widgetBackground),
        ],
      ),
    );
  }
}
