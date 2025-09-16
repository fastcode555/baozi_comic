import 'package:baozi_comic/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';

class ComicCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback? onTap;
  final bool showRanking;

  const ComicCard({required this.comic, super.key, this.onTap, this.showRanking = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: column.crossStart.children([
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: stack.children([
              image(comic.coverUrl).cover.mk,
              if (showRanking && comic.ranking != null)
                positioned.l4.t4.child(
                  container.ph6.pv2
                      .color(_getRankingColor(comic.ranking!))
                      .rounded10
                      .child(text('${comic.ranking}').f10.bold.white.mk),
                ),
            ]),
          ),
        ),
        h4,
        text(comic.title).ellipsis.maxLine2.f12.w500.mk,
        if (comic.lastUpdate != null) ...[
          h2,
          text(comic.lastUpdate).ellipsis.maxLine1.f10.grey.mk,
        ] else if (comic.author != null) ...[
          h2,
          text(comic.author).ellipsis.maxLine1.f10.grey.mk,
        ],
      ]),
    );
  }

  Color _getRankingColor(int ranking) {
    switch (ranking) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[700]!;
      default:
        return Colors.red;
    }
  }
}
