import themidibus.*;
import java.util.Collections;
import java.util.Timer;
import java.util.TimerTask;
import javax.sound.midi.*;
import de.voidplus.leapmotion.*;

LeapMotion leap;
MidiBus bus;
NoteTask task;
Timer timer;

int PITCH_MIN = 21;
int PITCH_MAX = 108;
int VELOCITY_MIN = 1;
int VELOCITY_MAX = 127;
int NUM_CHANNELS = 10;
int HISTORY_LENGTH = 2;
int FINGER_SENSITIVITY = 10;

ArrayList<ArrayList<PVector>> finger_vectors = new ArrayList<ArrayList<PVector>>();

void setup() {
  size(1024, 768, P3D);

  leap = new LeapMotion(this); 
  bus = new MidiBus(this, -1, "Ableton");
  timer = new Timer();

  for ( int x = 0; x < NUM_CHANNELS; x++ ) {
    finger_vectors.add(new ArrayList<PVector>());
  }

  addShutdownHook();
}

void draw() {
  noCursor();
  background(230);
  int fps = leap.getFrameRate();

  frameRate(fps);
  int x = 0;
  for (Hand hand : leap.getHands ()) {
    hand.draw();
    
    float hand_pitch = hand.getPitch();
    
    // Hand flat
    if (abs(hand_pitch) <= 20) {
      for (Finger finger : hand.getFingers ()) {
        PVector position = finger.getPosition();
        PVector tip = finger.getPositionOfJointTip();
        ArrayList<PVector> finger_history = finger_vectors.get(x);

        if (finger_history.size() >= HISTORY_LENGTH) {
          finger_history.remove(0);
        }

        finger_history.add(tip);

        if (finger_history.size() == HISTORY_LENGTH) {
          PVector previous = finger_history.get(0);
          PVector current = finger_history.get(finger_history.size()-1);
          float diff = current.y-previous.y;

          if (diff > FINGER_SENSITIVITY) {
            Note note = new Note(bus);
            note.channel = 0;
            note.velocity = int(map(diff, FINGER_SENSITIVITY, height/7, VELOCITY_MIN, VELOCITY_MAX));
            note.pitch = int(map(position.x, 0, width, PITCH_MIN, PITCH_MAX));
            note.duration = 200;

            task = new NoteTask(note);
            timer.schedule(task, 0);
            finger_history.clear();
          }
        }
        x++;
      }
    }
  }
}

void addShutdownHook () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      System.out.println("Shutting Down");
      try {
        for (int x = 0; x <= NUM_CHANNELS; x++) {
          bus.sendMessage(ShortMessage.CONTROL_CHANGE, x, 0x7B, 0);
        }

        bus.close();
        System.out.println("Daisy, Daisy, give me your answer do. I'm half crazy, all for the love of you.");
      }
      catch(Exception ex) {
      }
    }
  }
  ));
}
