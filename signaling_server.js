const WebSocket = require('ws');

// Create WebSocket server on port 8080
const wss = new WebSocket.Server({ port: 8080 });

// Store rooms and participants
const rooms = new Map();

console.log('WebSocket signaling server running on ws://localhost:8080');

wss.on('connection', (ws) => {
  console.log('New client connected');
  
  // Handle incoming messages
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('Received message:', data);
      
      switch (data.type) {
        case 'join':
          handleJoin(ws, data);
          break;
        case 'leave':
          handleLeave(ws, data);
          break;
        default:
          // Forward message to room participants
          forwardMessage(data);
          break;
      }
    } catch (error) {
      console.error('Error parsing message:', error);
    }
  });
  
  // Handle client disconnect
  ws.on('close', () => {
    console.log('Client disconnected');
    // Remove client from all rooms
    for (const [roomId, room] of rooms.entries()) {
      const index = room.participants.indexOf(ws);
      if (index !== -1) {
        room.participants.splice(index, 1);
        console.log(`Client removed from room ${roomId}`);
        
        // Notify others that participant left
        const leaveMessage = {
          type: 'participant_left',
          roomId: roomId,
          participantId: room.participantIds[index],
          timestamp: Date.now()
        };
        
        room.participants.forEach(participant => {
          if (participant.readyState === WebSocket.OPEN) {
            participant.send(JSON.stringify(leaveMessage));
          }
        });
        
        // Remove participant ID
        room.participantIds.splice(index, 1);
      }
    }
  });
});

function handleJoin(ws, data) {
  const { roomId, participantId } = data;
  
  // Create room if it doesn't exist
  if (!rooms.has(roomId)) {
    rooms.set(roomId, {
      participants: [],
      participantIds: []
    });
  }
  
  const room = rooms.get(roomId);
  
  // Add participant to room
  room.participants.push(ws);
  room.participantIds.push(participantId);
  
  console.log(`Participant ${participantId} joined room ${roomId}`);
  
  // Notify others that a new participant joined
  const joinMessage = {
    type: 'participant_joined',
    roomId: roomId,
    participantId: participantId,
    timestamp: Date.now()
  };
  
  room.participants.forEach(participant => {
    if (participant !== ws && participant.readyState === WebSocket.OPEN) {
      participant.send(JSON.stringify(joinMessage));
    }
  });
}

function handleLeave(ws, data) {
  const { roomId, participantId } = data;
  
  if (rooms.has(roomId)) {
    const room = rooms.get(roomId);
    const index = room.participants.indexOf(ws);
    
    if (index !== -1) {
      // Remove participant
      room.participants.splice(index, 1);
      room.participantIds.splice(index, 1);
      
      console.log(`Participant ${participantId} left room ${roomId}`);
      
      // Notify others that participant left
      const leaveMessage = {
        type: 'participant_left',
        roomId: roomId,
        participantId: participantId,
        timestamp: Date.now()
      };
      
      room.participants.forEach(participant => {
        if (participant.readyState === WebSocket.OPEN) {
          participant.send(JSON.stringify(leaveMessage));
        }
      });
      
      // Clean up empty room
      if (room.participants.length === 0) {
        rooms.delete(roomId);
        console.log(`Room ${roomId} deleted`);
      }
    }
  }
}

function forwardMessage(data) {
  const { roomId } = data;
  
  if (rooms.has(roomId)) {
    const room = rooms.get(roomId);
    
    // Send message to all participants in the room except sender
    room.participants.forEach(participant => {
      if (participant.readyState === WebSocket.OPEN) {
        participant.send(JSON.stringify(data));
      }
    });
  }
}

// Handle server shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  wss.close(() => {
    console.log('WebSocket server closed');
    process.exit(0);
  });
});