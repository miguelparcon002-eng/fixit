import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ratings_service.dart';

class TechRatingsScreen extends ConsumerWidget {
  const TechRatingsScreen({super.key});

  // Helper to check if rating belongs to this technician
  bool _isRatingForTechnician(String ratingTechnician, String userName) {
    final userNameLower = userName.toLowerCase();
    final ratingTechLower = ratingTechnician.toLowerCase();

    if (ratingTechLower == userNameLower) return true;
    if (userNameLower.contains(ratingTechLower)) return true;

    final nameParts = userName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts.last.toLowerCase();
      if (lastName == ratingTechLower) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(ratingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    return ratingsAsync.when(
      data: (allRatings) {
        // Filter ratings for this technician
        final ratings = allRatings.where((r) => _isRatingForTechnician(r.technician, userName)).toList();

        // Calculate average rating
        final averageRating = ratings.isEmpty
            ? 0.0
            : ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length;

        return _buildRatingsScreen(context, ratings, averageRating);
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.primaryCyan,
        appBar: AppBar(
          backgroundColor: AppTheme.deepBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Ratings & Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.deepBlue,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppTheme.primaryCyan,
        appBar: AppBar(
          backgroundColor: AppTheme.deepBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Ratings & Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Error loading ratings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsScreen(BuildContext context, List ratings, double averageRating) {

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Ratings & Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Rating Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rate,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : (index < averageRating ? Icons.star_half : Icons.star_border),
                      color: Colors.amber,
                      size: 28,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '${ratings.length} Reviews',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Reviews List
          Expanded(
            child: ratings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete jobs to receive reviews',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: ratings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rating = ratings[index];
                      return _ReviewCard(rating: rating);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Rating rating;

  const _ReviewCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with customer name and stars
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.lightBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                rating.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Service info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_android, size: 16, color: AppTheme.lightBlue),
                const SizedBox(width: 8),
                Text(
                  rating.device,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rating.service,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Review text
            Text(
              rating.review,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
