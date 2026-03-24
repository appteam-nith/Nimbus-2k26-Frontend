import '../models/timeline_event.dart';

class TimelineApi {
  Future<List<TimelineEvent>> fetchTimeline() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();

    return [
      // ======================
      // DAY 1
      // ======================
      TimelineEvent(
        id: '1',
        title: 'Opening Ceremony',
        description: 'Main inauguration of Nimbus 2K26',
        startTime: DateTime(now.year, now.month, now.day, 9, 30),
        location: 'Main Stage',
        isLive: false,
        day: 1,
      ),

      TimelineEvent(
        id: '2',
        title: 'Hackathon Kickoff',
        description: '48 hour national hackathon begins ',
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        location: 'Mini Auditorium',
        isLive: true,
        day: 1,
      ),

      // ======================
      // DAY 2
      // ======================
      TimelineEvent(
        id: '3',
        title: 'Tech Talk',
        description: 'AI & Future of Software',
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 30),
        location: 'Seminar Hall',
        isLive: false,
        day: 2,
      ),

      TimelineEvent(
        id: '4',
        title: 'Workshop',
        description: 'Flutter for Production Apps',
        startTime: DateTime(now.year, now.month, now.day + 1, 14, 0),
        location: 'Lab 2',
        isLive: false,
        day: 2,
      ),

      // ======================
      // DAY 3
      // ======================
      TimelineEvent(
        id: '5',
        title: 'Final Presentations',
        description: 'Hackathon project demos',
        startTime: DateTime(now.year, now.month, now.day + 2, 11, 0),
        location: 'Main Auditorium',
        isLive: false,
        day: 3,
      ),

      TimelineEvent(
        id: '6',
        title: 'Closing Ceremony',
        description: 'Results and prize distribution',
        startTime: DateTime(now.year, now.month, now.day + 2, 17, 0),
        location: 'Main Stage',
        isLive: false,
        day: 3,
      ),
      // ======================
      // ➕ NEW – DAY 1
      // ======================
      TimelineEvent(
        id: '7',
        title: 'UI/UX Design Sprint',
        description: 'Rapid design challenge for beginners',
        startTime: DateTime(now.year, now.month, now.day, 12, 30),
        location: 'Design Lab',
        isLive: false,
        day: 1,
      ),
      TimelineEvent(
        id: '8',
        title: 'Web Dev Bootcamp',
        description: 'Hands-on session on modern web stack',
        startTime: DateTime(now.year, now.month, now.day, 13, 30),
        location: 'Lab 1',
        isLive: false,
        day: 1,
      ),
      TimelineEvent(
        id: '9',
        title: 'Startup Pitch Arena',
        description: 'Students pitch their startup ideas',
        startTime: DateTime(now.year, now.month, now.day, 15, 0),
        location: 'Conference Hall',
        isLive: false,
        day: 1,
      ),
      TimelineEvent(
        id: '10',
        title: 'Coding Relay',
        description: 'Team based coding challenge',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        location: 'Lab 3',
        isLive: false,
        day: 1,
      ),
      TimelineEvent(
        id: '11',
        title: 'Tech Quiz',
        description: 'Live technical quiz competition',
        startTime: DateTime(now.year, now.month, now.day, 17, 0),
        location: 'Seminar Hall',
        isLive: false,
        day: 1,
      ),
      TimelineEvent(
        id: '12',
        title: 'Networking Session',
        description: 'Meet seniors and industry mentors',
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
        location: 'Open Lounge',
        isLive: false,
        day: 1,
      ),
      // ======================
      // ➕ NEW – DAY 2
      // ======================
      TimelineEvent(
        id: '13',
        title: 'DSA Contest ht jhlva rhlav htswvk htwvk jhtwkvhtbsk shb skh c h ds',
        description: 'Competitive programming round iurht kjhtf eijhtf ierushf ihf ehf ekjhf ehjtf ',
        startTime: DateTime(now.year, now.month, now.day + 1, 9, 30),
        location: 'Online Arena',
        isLive: true,
        day: 2,
      ),
      TimelineEvent(
        id: '14',
        title: 'System Design Talk',
        description: 'How real scalable systems are built',
        startTime: DateTime(now.year, now.month, now.day + 1, 11, 30),
        location: 'Main Auditorium',
        isLive: false,
        day: 2,
      ),
      TimelineEvent(
        id: '15',
        title: 'App Dev Workshop',
        description: 'Flutter app architecture session',
        startTime: DateTime(now.year, now.month, now.day + 1, 13, 0),
        location: 'Lab 4',
        isLive: false,
        day: 2,
      ),
      TimelineEvent(
        id: '16',
        title: 'Debugging Battle',
        description: 'Fix bugs faster than other teams',
        startTime: DateTime(now.year, now.month, now.day + 1, 15, 0),
        location: 'Lab 2',
        isLive: false,
        day: 2,
      ),
      TimelineEvent(
        id: '17',
        title: 'Open Source Meetup kjnf cjwfbc kjbc kch ishb hjgtvk ajhrihf vhgcj',
        description: 'How to start contributing to OSS  rhi eusrhf kieh kiejh cekhekljshfk e hkej fkes kjf hktebkjf bhekhtbkjh bkt fehfehjsrkjth kbthf tslekjf ekerktf ebtkjn',
        startTime: DateTime(now.year, now.month, now.day + 1, 16, 30),
        location: 'Seminar Hall',
        isLive: false,
        day: 2,
      ),
      TimelineEvent(
        id: '18',
        title: 'Gaming & VR Zone',
        description: 'Experience VR and multiplayer games',
        startTime: DateTime(now.year, now.month, now.day + 1, 18, 0),
        location: 'Experience Zone',
        isLive: false,
        day: 2,
      ),
      // ======================
      // ➕ NEW – DAY 3
      // ======================
      TimelineEvent(
        id: '19',
        title: 'Mock Interviews',
        description: 'Technical and HR mock interviews',
        startTime: DateTime(now.year, now.month, now.day + 2, 9, 30),
        location: 'Placement Cell',
        isLive: false,
        day: 3,
      ),
      TimelineEvent(
        id: '20',
        title: 'Resume Review Camp',
        description: 'Get your resume reviewed by mentors',
        startTime: DateTime(now.year, now.month, now.day + 2, 10, 30),
        location: 'Conference Room',
        isLive: false,
        day: 3,
      ),
      TimelineEvent(
        id: '21',
        title: 'Startup Founder Talk',
        description: 'Journey from college to startup',
        startTime: DateTime(now.year, now.month, now.day + 2, 12, 30),
        location: 'Main Auditorium',
        isLive: false,
        day: 3,
      ),
      TimelineEvent(
        id: '22',
        title: 'Hackathon Final Evaluation',
        description: 'Jury evaluates final projects',
        startTime: DateTime(now.year, now.month, now.day + 2, 14, 0),
        location: 'Innovation Hall',
        isLive: false,
        day: 3,
      ),
      TimelineEvent(
        id: '23',
        title: 'Award Rehearsal',
        description: 'Stage rehearsal for winners',
        startTime: DateTime(now.year, now.month, now.day + 2, 15, 30),
        location: 'Main Stage',
        isLive: false,
        day: 3,
      ),
      TimelineEvent(
        id: '24',
        title: 'After Party & DJ Night',
        description: 'Celebration night for all participants',
        startTime: DateTime(now.year, now.month, now.day + 2, 19, 0),
        location: 'Open Ground',
        isLive: true,
        day: 3,
      ),
    ];
  }
}
