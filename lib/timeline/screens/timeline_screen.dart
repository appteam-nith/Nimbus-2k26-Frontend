import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/timeline_controller.dart';
import '../widgets/event_card.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TimelineController>().loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 32,
        title: const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          _daySelector(),
          const Divider(height: 1),
          Expanded(
            child: Consumer<TimelineController>(
              builder: (context, controller, _) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error != null) {
                  return Center(child: Text(controller.error!));
                }
                if (controller.events.isEmpty) {
                  return const Center(child: Text('No events available'));
                }
                return Stack(
                  children: [
                    Positioned(
                      left: 15,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: const Color(0xFF135BEC),
                      ),
                    ),
                    // EVENT LIST
                    ListView.builder(
                      itemCount: controller.events.length,
                      itemBuilder: (context, index) {
                        return TimelineEventCard(
                          event: controller.events[index],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _daySelector() {
    final selectedDay = context.watch<TimelineController>().selectedDay - 1;

    return SizedBox(
      height: 62,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              Row(
                children: [
                  _dayTab(title: 'Day 1', date: '10 Apr', index: 0),
                  _dayTab(title: 'Day 2', date: '11 Apr', index: 1),
                  _dayTab(title: 'Day 3', date: '12 Apr', index: 2),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: tabWidth * selectedDay,
                bottom: 0,
                child: Container(
                  width: tabWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dayTab({
    required String title,
    required String date,
    required int index,
  }) {
    final selectedDay = context.watch<TimelineController>().selectedDay - 1;
    final bool isSelected = selectedDay == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<TimelineController>().changeDay(index + 1);
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF135BEC)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF374151)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}