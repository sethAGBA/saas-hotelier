import 'package:flutter/material.dart';
import 'time_tracking_attendance_screen.dart';
import 'leave_management_screen.dart';

class TimeAndLeaveScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const TimeAndLeaveScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<TimeAndLeaveScreen> createState() => _TimeAndLeaveScreenState();
}

class _TimeAndLeaveScreenState extends State<TimeAndLeaveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            tabs: const [
              Tab(icon: Icon(Icons.fingerprint), text: 'Présence'),
              Tab(icon: Icon(Icons.beach_access), text: 'Congés'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              TimeTrackingAttendanceScreen(
                fadeAnimation: widget.fadeAnimation,
                gradient: widget.gradient,
              ),
              LeaveManagementScreen(
                fadeAnimation: widget.fadeAnimation,
                gradient: widget.gradient,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

