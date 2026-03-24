import 'package:flutter/material.dart';

class TopPerformers extends StatelessWidget {
  const TopPerformers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Top Performers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "View All",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            _Performer(
              name: "John",
              points: "4200",
              image: "assets/images/user1.png",
              rank: 2,
              isTop: false,
            ),
            _Performer(
              name: "John Doe",
              points: "4500",
              image: "assets/images/user2.png",
              rank: 1,
              isTop: true,
            ),
            _Performer(
              name: "Alex",
              points: "3900",
              image: "assets/images/user3.png",
              rank: 3,
              isTop: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _Performer extends StatelessWidget {
  final String name;
  final String points;
  final String image;
  final int rank;
  final bool isTop;

  const _Performer({
    required this.name,
    required this.points,
    required this.image,
    required this.rank,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = isTop ? 34 : 26;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Gold ring for top performer
            if (isTop)
              Container(
                width: avatarRadius * 2 + 10,
                height: avatarRadius * 2 + 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD54F),
                ),
              ),

            // Avatar
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: avatarRadius - 3,
                backgroundImage: AssetImage(image),
              ),
            ),

            // Crown icon
            if (isTop)
              const Positioned(
                top: -14,
                child: Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFC107),
                  size: 22,
                ),
              ),

            // Rank badge
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFFFFC107) : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isTop ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          "$points pts",
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

