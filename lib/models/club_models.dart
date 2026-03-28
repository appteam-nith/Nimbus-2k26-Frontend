import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Department enum – drives the filter chip colours and labels
// ─────────────────────────────────────────────────────────────────────────────

enum Department {
  all,
  cse,
  ece,
  mech,
  civil,
  arch,
  chem,
  ee;

  String get label {
    switch (this) {
      case Department.all:  return 'All';
      case Department.cse:  return 'CSE';
      case Department.ece:  return 'ECE';
      case Department.mech: return 'Mech';
      case Department.civil:return 'Civil';
      case Department.arch: return 'Arch';
      case Department.chem: return 'Chemical';
      case Department.ee:   return 'Electrical';
    }
  }

  String get fullName {
    switch (this) {
      case Department.all:  return 'All Departments';
      case Department.cse:  return 'Computer Science';
      case Department.ece:  return 'Electronics & Comm';
      case Department.mech: return 'Mechanical Engineering';
      case Department.civil:return 'Civil Engineering';
      case Department.arch: return 'Architecture';
      case Department.chem: return 'Chemical Engineering';
      case Department.ee:   return 'Electrical Engineering';
    }
  }

  Color get badgeBg {
    switch (this) {
      case Department.cse:  return const Color(0xFFEFF6FF);
      case Department.ece:  return const Color(0xFFFFFBEB);
      case Department.mech: return const Color(0xFFF1F5F9);
      case Department.chem: return const Color(0xFFF0FDF4);
      case Department.ee:   return const Color(0xFFFEFCE8);
      default:              return const Color(0xFFF1F5F9);
    }
  }

  Color get badgeText {
    switch (this) {
      case Department.cse:  return const Color(0xFF1D4ED8);
      case Department.ece:  return const Color(0xFFB45309);
      case Department.mech: return const Color(0xFF334155);
      case Department.chem: return const Color(0xFF15803D);
      case Department.ee:   return const Color(0xFFA16207);
      default:              return const Color(0xFF64748B);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ProjectStatus
// ─────────────────────────────────────────────────────────────────────────────

enum ProjectStatus { live, inProgress, beta, archived }

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.live:       return 'Live';
      case ProjectStatus.inProgress: return 'In Progress';
      case ProjectStatus.beta:       return 'Beta';
      case ProjectStatus.archived:   return 'Archived';
    }
  }

  Color get bg {
    switch (this) {
      case ProjectStatus.live:       return const Color(0xFFF0FDF4);
      case ProjectStatus.inProgress: return const Color(0xFFFEFCE8);
      case ProjectStatus.beta:       return const Color(0xFFEFF6FF);
      case ProjectStatus.archived:   return const Color(0xFFF1F5F9);
    }
  }

  Color get text {
    switch (this) {
      case ProjectStatus.live:       return const Color(0xFF15803D);
      case ProjectStatus.inProgress: return const Color(0xFFA16207);
      case ProjectStatus.beta:       return const Color(0xFF1D4ED8);
      case ProjectStatus.archived:   return const Color(0xFF64748B);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ClubProject
// ─────────────────────────────────────────────────────────────────────────────

class ClubProject {
  final String title;
  final String techStack;
  final String description;
  final ProjectStatus status;
  final int year;
  final int stars;
  final String? repoUrl;

  const ClubProject({
    required this.title,
    required this.techStack,
    required this.description,
    required this.status,
    required this.year,
    required this.stars,
    this.repoUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  ClubAchievement
// ─────────────────────────────────────────────────────────────────────────────

class ClubAchievement {
  final String icon;
  final String title;
  final String subtitle;

  const ClubAchievement({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Club
// ─────────────────────────────────────────────────────────────────────────────

class Club {
  final String id;
  final String name;
  final Department department;
  final String description;
  final String? imageUrl;   // remote image; null → show placeholder gradient
  final int memberCount;
  final int foundedYear;
  final List<ClubProject> projects;
  final List<ClubAchievement> achievements;

  const Club({
    required this.id,
    required this.name,
    required this.department,
    required this.description,
    this.imageUrl,
    required this.memberCount,
    required this.foundedYear,
    required this.projects,
    required this.achievements,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sample / mock data
// ─────────────────────────────────────────────────────────────────────────────

final List<Club> kSampleClubs = [
  Club(
    id: 'team-exe',
    name: 'Team .EXE',
    department: Department.cse,
    description:
        'The official technical club of CSE, focusing on web dev, competitive coding, open source contributions, and cutting-edge AI projects.',
    memberCount: 42,
    foundedYear: 2019,
    projects: const [
      ClubProject(
        title: 'Nimbus App',
        techStack: 'Flutter · Firebase',
        description:
            'Official college event app with live leaderboard, registration, and push notifications.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 48,
        repoUrl: 'https://github.com/appteam-nith/Nimbus-2k26-Frontend',
      ),
      ClubProject(
        title: 'ERP Dashboard',
        techStack: 'React · Node.js',
        description:
            'Internal ERP portal used by faculty for attendance tracking and grade management.',
        status: ProjectStatus.inProgress,
        year: 2025,
        stars: 23,
      ),
      ClubProject(
        title: 'CampusMap AR',
        techStack: 'Unity · ARCore',
        description:
            'Augmented reality campus navigation app that overlays directions on live camera feed.',
        status: ProjectStatus.beta,
        year: 2025,
        stars: 61,
      ),
      ClubProject(
        title: 'NIT-GPT',
        techStack: 'Python · LangChain',
        description:
            'Local LLM chatbot trained on college documents, timetables, and hostel rules.',
        status: ProjectStatus.archived,
        year: 2023,
        stars: 134,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🏆',
        title: 'Smart India Hackathon 2024',
        subtitle: 'National Finalists — Campus Sustainability Track',
      ),
      ClubAchievement(
        icon: '🥇',
        title: 'TechNITian Fest Winner',
        subtitle: '1st place in Web Dev challenge, 2023',
      ),
      ClubAchievement(
        icon: '🎖',
        title: 'Open Source Drive',
        subtitle: '200+ commits to public repos in 30 days',
      ),
    ],
  ),
  Club(
    id: 'hermetica',
    name: 'Hermetica',
    department: Department.chem,
    description:
        'Innovating in process design and sustainable chemical solutions for the future.',
    memberCount: 28,
    foundedYear: 2020,
    projects: const [
      ClubProject(
        title: 'WaterPure Sensor',
        techStack: 'Arduino · Python',
        description: 'IoT water quality monitoring sensor with real-time dashboard.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 19,
      ),
      ClubProject(
        title: 'Biodiesel Calc',
        techStack: 'Flutter · SQLite',
        description: 'Mobile app to calculate optimal biodiesel blend ratios.',
        status: ProjectStatus.beta,
        year: 2025,
        stars: 11,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🌱',
        title: 'Green Campus Award 2024',
        subtitle: 'Best sustainability initiative by a student club',
      ),
    ],
  ),
  Club(
    id: 'vibhav',
    name: 'Vibhav',
    department: Department.ece,
    description:
        'Exploring the frontiers of embedded systems, VLSI, and signal processing.',
    memberCount: 35,
    foundedYear: 2018,
    projects: const [
      ClubProject(
        title: 'SmartBot',
        techStack: 'Raspberry Pi · OpenCV',
        description: 'Line-following robot with computer vision obstacle avoidance.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 72,
      ),
      ClubProject(
        title: 'VLSI Sim',
        techStack: 'Verilog · ModelSim',
        description: 'Custom RISC-V core simulation for educational purposes.',
        status: ProjectStatus.archived,
        year: 2022,
        stars: 38,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🤖',
        title: 'Robocon Regional 2024',
        subtitle: 'Top 8 nationally in ABU Robocon qualifiers',
      ),
    ],
  ),
  Club(
    id: 'ojas',
    name: 'Ojas',
    department: Department.ee,
    description:
        'Lighting up the campus with innovation in power systems and renewable energy.',
    memberCount: 31,
    foundedYear: 2021,
    projects: const [
      ClubProject(
        title: 'SolarTracker',
        techStack: 'Arduino · MATLAB',
        description: 'Dual-axis solar panel tracker with efficiency analytics.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 44,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '⚡',
        title: 'Energy Innovation Award',
        subtitle: 'MNRE student challenge — 2nd prize nationwide',
      ),
    ],
  ),
  Club(
    id: 'mech-club',
    name: 'Mech-club',
    department: Department.mech,
    description:
        'Designing and manufacturing the machines of tomorrow, from robotics to automobiles.',
    memberCount: 38,
    foundedYear: 2017,
    projects: const [
      ClubProject(
        title: 'Mini-BAJA',
        techStack: 'SolidWorks · CNC',
        description: 'SAE BAJA off-road vehicle designed and fabricated from scratch.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 91,
      ),
      ClubProject(
        title: 'Exoskeleton v1',
        techStack: 'ANSYS · 3D Print',
        description: 'Assistive lower-limb exoskeleton prototype for rehabilitation.',
        status: ProjectStatus.inProgress,
        year: 2025,
        stars: 55,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🏎',
        title: 'SAE BAJA India 2024',
        subtitle: 'Finished 14th overall out of 380 teams',
      ),
    ],
  ),
];
