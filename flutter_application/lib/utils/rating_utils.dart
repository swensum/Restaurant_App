import 'package:flutter/material.dart';

class AverageRatingWidget extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> reviewsFuture;
  final double iconSize;
  final Color iconColor;
  final TextStyle? ratingTextStyle;
  final bool showFiveStars;

  const AverageRatingWidget({
    super.key,
    required this.reviewsFuture,
    this.iconSize = 18,
    this.iconColor = Colors.orange,
    this.ratingTextStyle,
    this.showFiveStars = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        double avgRating = 0.0;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final reviews = snapshot.data!;
          avgRating = reviews.map((r) => r['rating'] as num).reduce((a, b) => a + b) / reviews.length;
        }

        return Row(
          children: [
            if (showFiveStars)
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < avgRating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
              )
            else
              Icon(Icons.star, color: iconColor, size: iconSize),
            const SizedBox(width: 4),
            Text(
             '(${avgRating.toStringAsFixed(1)})',
              style: ratingTextStyle ??
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
