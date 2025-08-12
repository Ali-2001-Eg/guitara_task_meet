# WebRTC Video Call Application

This is a Flutter WebRTC application that allows users to make video calls with each other using WebRTC technology.

## Features

- Video calling between two users
- Audio mute/unmute
- Video enable/disable
- Camera switching (front/back)
- Real-time signaling using WebSocket

## Setup Instructions

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Run the Signaling Server

The application requires a WebSocket signaling server to coordinate the WebRTC connection between peers.

1. Install Node.js dependencies:
   ```bash
   npm install
   ```

2. Start the signaling server:
   ```bash
   npm start
   ```

   The server will run on `ws://localhost:8080`

### 3. Run the Flutter Application

1. Make sure you have at least two devices or emulators running
2. Start the Flutter application on both devices:
   ```bash
   flutter run
   ```

### 4. Testing with Two Devices

1. On the first device:
   - Enter a name and tap "Join Call"
   - You'll see your local camera feed

2. On the second device:
   - Enter a different name and tap "Join Call"
   - You should see both local and remote video feeds

## Release APK Testing

To test the release APK:

1. Build the release APK:
   ```bash
   flutter build apk --release
   ```

2. Install the APK on two Android devices

3. Make sure both devices are on the same network

4. Run the signaling server on a machine accessible to both devices

5. Update the WebSocket URL in `lib/feature/web_rtc/web_rtc_example_screen.dart` line 60 to point to your signaling server:
   ```dart
   await _signalingService.connect('ws://YOUR_SERVER_IP:8080');
   ```

## Troubleshooting

### Camera/Microphone Permissions

Make sure to grant camera and microphone permissions when prompted.

### Network Issues

- Ensure both devices can reach the signaling server
- For local testing, make sure devices are on the same network
- For remote testing, ensure the signaling server is accessible from both devices

### Audio/Video Not Working

- Check that both devices have working cameras and microphones
- Ensure no other applications are using the camera/microphone
- Check device-specific permissions in settings

## Architecture

### WebRTC Flow

1. User joins a room with a unique name
2. Signaling server coordinates connection between peers
3. Peer connections are established using STUN servers for NAT traversal
4. Media streams are exchanged directly between peers

### Components

- `WebRtcExampleScreen`: Main screen handling WebRTC functionality
- `WebSocketSignalingService`: WebSocket-based signaling implementation
- `signaling_server.js`: Node.js WebSocket signaling server

## Dependencies

### Flutter Dependencies

- `flutter_webrtc`: WebRTC implementation for Flutter
- `web_socket_channel`: WebSocket client for signaling
- `go_router`: Navigation and routing
- `permission_handler`: Camera/microphone permissions

### Server Dependencies

- `ws`: WebSocket server implementation for Node.js

## Customization

### Changing STUN Servers

You can modify the STUN servers in `lib/feature/web_rtc/web_rtc_example_screen.dart`:

```dart
final List<Map<String, dynamic>> _iceServers = [
  {
    'urls': ['stun:stun.l.google.com:19302'],
    'username': '',
    'credential': '',
  },
  // Add more STUN/TURN servers as needed
];
```

### Changing Room Name

The default room name is "test-room". You can change this in the `_joinSignalingRoom()` method.

## License

This project is licensed under the MIT License.
