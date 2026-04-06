import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';  
import 'timeline/controller/timeline_controller.dart';
import 'timeline/screens/timeline_screen.dart';
=======
import 'theme.dart';
import 'screens/home_screen.dart';
>>>>>>> fbd980c (Home page)

void main() {
  runApp(ChangeNotifierProvider(
      create: (_) => TimelineController(),  
      child: const MyApp(),                 
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const TimelineScreen(),
=======
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(), 
>>>>>>> fbd980c (Home page)
    );
  }
}


