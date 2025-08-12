import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:uuid/uuid.dart';

class GetStreamScreenIO extends StatefulWidget {
  final String userName;
  const GetStreamScreenIO({super.key, required this.userName});

  @override
  State<GetStreamScreenIO> createState() => _GetStreamScreenIOState();
}

class _GetStreamScreenIOState extends State<GetStreamScreenIO> {
  late final StreamVideo client;
  Call? call;

  // Replace these with your actual credentials
  final String apiKey = 't6hyshg2tdm3';
  final String userToken = 'REPLACE_WITH_A_TOKEN';
  final String callId = 'Test Room';

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    final userId = widget.userName.isNotEmpty
        ? widget.userName
        : 'user-${const Uuid().v4().substring(0, 8)}';

    client = StreamVideo(
      apiKey,
      user: User.regular(userId: userId, name: userId),
      userToken: userToken,
    );

    final theCall = client.makeCall(
      callType: StreamCallType.defaultType(),
      id: callId,
    );

    await theCall.getOrCreate();
    await theCall.join();

    setState(() => call = theCall);
  }

  @override
  void dispose() {
    call?.leave();
    client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (call == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return  Scaffold(
  appBar: AppBar(title: Text('Room: $callId')),
  body: StreamCallContainer(
    call: call!,
    pictureInPictureConfiguration: PictureInPictureConfiguration(
      enablePictureInPicture: true,
    
    ),
    // customize the "active call" UI
    callContentBuilder: (context, call, callState) {
      return StreamCallContent(
        call: call,
        callState: callState,
        // optional: override layout, controls, participants if needed
      );
    },
    // optional: handle leaving via callback
    onLeaveCallTap: () async {
      await call!.leave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the call')),
        );
      }
    },
  ),
);
  }
}
