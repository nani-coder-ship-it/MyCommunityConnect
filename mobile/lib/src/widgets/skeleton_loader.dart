import 'package:flutter/material.dart';

/// Shimmer skeleton loader for better loading states
class SkeletonLoader extends StatefulWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Post card skeleton
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                const SkeletonLoader(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.3,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      SkeletonLoader(
                        height: 12,
                        width: MediaQuery.of(context).size.width * 0.2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            SkeletonLoader(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.9,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.7,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            // Image placeholder
            SkeletonLoader(
              height: 200,
              width: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            // Like/Comment buttons
            Row(
              children: [
                SkeletonLoader(
                  height: 32,
                  width: 80,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  height: 32,
                  width: 80,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Event card skeleton
class EventSkeleton extends StatelessWidget {
  const EventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date box skeleton
            Container(
              width: 60,
              height: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonLoader(
                    height: 20,
                    width: 30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    height: 14,
                    width: 40,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.7,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List skeleton (for contacts, visitors, etc)
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonLoader(
        height: 40,
        width: 40,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      title: SkeletonLoader(
        height: 14,
        width: MediaQuery.of(context).size.width * 0.4,
        borderRadius: BorderRadius.circular(4),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SkeletonLoader(
          height: 12,
          width: MediaQuery.of(context).size.width * 0.6,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
