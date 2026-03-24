import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 24, backgroundImage: AssetImage("assets/images/user1.png")),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Morning,", style: TextStyle(fontSize: 12)),
              Text("Ayush", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
      ],
    );
  }
}
