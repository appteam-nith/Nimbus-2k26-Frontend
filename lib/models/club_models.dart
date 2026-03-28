import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Department enum
// ─────────────────────────────────────────────────────────────────────────────

enum Department {
  all,
  cse,
  ece,
  mech,
  civil,
  arch,
  chem,
  ee,
  mnc,
  physics,
  material;

  String get label {
    switch (this) {
      case Department.all:      return 'All';
      case Department.cse:      return 'CSE';
      case Department.ece:      return 'ECE';
      case Department.mech:     return 'Mech';
      case Department.civil:    return 'Civil';
      case Department.arch:     return 'Arch';
      case Department.chem:     return 'Chem';
      case Department.ee:       return 'Electrical';
      case Department.mnc:      return 'MNC';
      case Department.physics:  return 'Physics';
      case Department.material: return 'Material';
    }
  }

  String get fullName {
    switch (this) {
      case Department.all:      return 'All Departments';
      case Department.cse:      return 'Computer Science';
      case Department.ece:      return 'Electronics & Communication';
      case Department.mech:     return 'Mechanical Engineering';
      case Department.civil:    return 'Civil Engineering';
      case Department.arch:     return 'Architecture';
      case Department.chem:     return 'Chemical Engineering';
      case Department.ee:       return 'Electrical Engineering';
      case Department.mnc:      return 'Mathematics & Computing';
      case Department.physics:  return 'Physics';
      case Department.material: return 'Materials Science';
    }
  }

  Color get badgeBg {
    switch (this) {
      case Department.cse:      return const Color(0xFFEEF5FF);
      case Department.ece:      return const Color(0xFFFFF9ED);
      case Department.mech:     return const Color(0xFFF0F0F5);
      case Department.civil:    return const Color(0xFFEFE8F8);
      case Department.arch:     return const Color(0xFFF8E8F5);
      case Department.chem:     return const Color(0xFFF0FBEF);
      case Department.ee:       return const Color(0xFFE0FFF7);
      case Department.mnc:      return const Color(0xFFEEF5FF);
      case Department.physics:  return const Color(0xFFE8F5E0);
      case Department.material: return const Color(0xFFF5F8C0);
      default:                  return const Color(0xFFF1F5F9);
    }
  }

  Color get badgeText {
    switch (this) {
      case Department.cse:      return const Color(0xFF1D4ED8);
      case Department.ece:      return const Color(0xFFB45309);
      case Department.mech:     return const Color(0xFF334155);
      case Department.civil:    return const Color(0xFF6B21A8);
      case Department.arch:     return const Color(0xFF9D174D);
      case Department.chem:     return const Color(0xFF15803D);
      case Department.ee:       return const Color(0xFF0F766E);
      case Department.mnc:      return const Color(0xFF1D4ED8);
      case Department.physics:  return const Color(0xFF3D6B21);
      case Department.material: return const Color(0xFF7A6B00);
      default:                  return const Color(0xFF64748B);
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
  final String? imageAsset;   // local asset path e.g. 'assets/clubs/EXE.jpg'
  final String? imageUrl;     // remote image URL
  final int memberCount;
  final int foundedYear;
  final List<ClubProject> projects;
  final List<ClubAchievement> achievements;

  const Club({
    required this.id,
    required this.name,
    required this.department,
    required this.description,
    this.imageAsset,
    this.imageUrl,
    required this.memberCount,
    required this.foundedYear,
    required this.projects,
    required this.achievements,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sample / mock data  — matches departmental_clubs_page.dart club list
// ─────────────────────────────────────────────────────────────────────────────

final List<Club> kSampleClubs = [
  // ── CSE ──────────────────────────────────────────────────────────────────
  Club(
    id: 'team-exe',
    name: 'Team .EXE',
    department: Department.cse,
    description:
        'The official technical club of CSE, focusing on web dev, competitive coding, open source contributions, and cutting-edge AI projects.',
    imageAsset: 'assets/clubs/EXE.jpg',
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

  // ── Chemical ──────────────────────────────────────────────────────────────
  Club(
    id: 'hermetica',
    name: 'Hermetica',
    department: Department.chem,
    description:
        'Innovating in process design and sustainable chemical solutions for the future.',
    imageAsset: 'assets/clubs/Hermetica.jpg',
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

  // ── ECE ───────────────────────────────────────────────────────────────────
  Club(
    id: 'vibhav',
    name: 'Vibhav',
    department: Department.ece,
    description:
        'Exploring the frontiers of embedded systems, VLSI, and signal processing.',
    imageAsset: 'assets/clubs/Vibhav.jpg',
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

  // ── Electrical ────────────────────────────────────────────────────────────
  Club(
    id: 'ojas',
    name: 'Ojas',
    department: Department.ee,
    description:
        'Lighting up the campus with innovation in power systems and renewable energy.',
    imageAsset: 'assets/clubs/Ojas.jpg',
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

  // ── Mechanical ────────────────────────────────────────────────────────────
  Club(
    id: 'medextrous',
    name: 'Medextrous',
    department: Department.mech,
    description: 'Designing and manufacturing the machines of tomorrow.',
    imageAsset: 'assets/clubs/Medextrous.jpg',
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

  // ── Civil ─────────────────────────────────────────────────────────────────
  Club(
    id: 'c-helix',
    name: 'C-Helix',
    department: Department.civil,
    description:
        'Exploring infrastructure, structural design, and sustainable civil engineering projects.',
    imageAsset: 'assets/clubs/CHelix.jpg',
    memberCount: 26,
    foundedYear: 2019,
    projects: const [
      ClubProject(
        title: 'SmartBridge Monitor',
        techStack: 'Arduino · IoT',
        description: 'Real-time structural health monitoring system for bridges.',
        status: ProjectStatus.beta,
        year: 2024,
        stars: 17,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🏗',
        title: 'ASCE Student Challenge 2024',
        subtitle: 'Regional finalists in sustainable design track',
      ),
    ],
  ),

  // ── MNC ───────────────────────────────────────────────────────────────────
  Club(
    id: 'matcom',
    name: 'Matcom',
    department: Department.mnc,
    description:
        'Bridging mathematics and computation through algorithms, data science, and theoretical computing.',
    imageAsset: 'assets/clubs/Matcom.jpg',
    memberCount: 24,
    foundedYear: 2020,
    projects: const [
      ClubProject(
        title: 'AlgoViz',
        techStack: 'React · D3.js',
        description: 'Interactive algorithm visualizer for sorting and graph problems.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 33,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '📐',
        title: 'Inter-NIT Math Olympiad 2024',
        subtitle: '2nd place in competitive mathematics',
      ),
    ],
  ),

  // ── Materials Science ─────────────────────────────────────────────────────
  Club(
    id: 'metamorph',
    name: 'Metamorph',
    department: Department.material,
    description:
        'Transforming materials science through research, innovation, and advanced material applications.',
    imageAsset: 'assets/clubs/Metamorph.jpg',
    memberCount: 22,
    foundedYear: 2021,
    projects: const [
      ClubProject(
        title: 'NanoCoat Analyzer',
        techStack: 'Python · TensorFlow',
        description: 'ML model to predict properties of nano-coating materials.',
        status: ProjectStatus.inProgress,
        year: 2025,
        stars: 14,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🔬',
        title: 'Materials Research Symposium 2024',
        subtitle: 'Best student paper award',
      ),
    ],
  ),

  // ── Architecture ──────────────────────────────────────────────────────────
  Club(
    id: 'design-o-crafts',
    name: 'Design O Crafts',
    department: Department.arch,
    description:
        'Creating innovative architectural designs and sustainable urban planning solutions.',
    imageAsset: 'assets/clubs/DesignOCrafts.jpg',
    memberCount: 20,
    foundedYear: 2018,
    projects: const [
      ClubProject(
        title: 'Campus Redesign 2050',
        techStack: 'AutoCAD · Revit',
        description: 'Sustainable campus master plan proposal for NIT Hamirpur.',
        status: ProjectStatus.inProgress,
        year: 2025,
        stars: 28,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🏛',
        title: 'NASA Design Competition 2024',
        subtitle: 'Top 10 nationally in sustainable architecture',
      ),
    ],
  ),

  // ── Physics ───────────────────────────────────────────────────────────────
  Club(
    id: 'team-abraxas',
    name: 'Team Abraxas',
    department: Department.physics,
    description:
        'Exploring quantum mechanics, astrophysics, and experimental physics research.',
    imageAsset: 'assets/clubs/Abraxas.jpg',
    memberCount: 18,
    foundedYear: 2022,
    projects: const [
      ClubProject(
        title: 'StarMap App',
        techStack: 'Flutter · NASA API',
        description: 'Mobile app for real-time star and satellite tracking.',
        status: ProjectStatus.live,
        year: 2024,
        stars: 41,
      ),
    ],
    achievements: const [
      ClubAchievement(
        icon: '🔭',
        title: 'ISRO Space Challenge 2024',
        subtitle: 'Shortlisted among top 20 student teams',
      ),
    ],
  ),
];