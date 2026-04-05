import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:developer';

class PusherService {
  final pusher = PusherChannelsFlutter.getInstance();

  Future<void> initPusher() async {
    try {
      await pusher.init(
        apiKey: "9abb93acdbad87f7e0cb",
        cluster: "ap2",
        onConnectionStateChange: (currentState, previousState) {
          log("Pusher status changed from $previousState to $currentState");
        },
        onError: (message, code, error) {
          log("Pusher Error: $message ($code)");
        },
        onEvent: (event) {
          log("Got event: ${event.eventName} with data: ${event.data}");
        },
      );

      await pusher.subscribe(channelName: "my-channel");
      await pusher.connect();
      
    } catch (e) {
      log("Error initializing Pusher: $e");
    }
  }
}
