public class NoteTask extends TimerTask { 
 Thread thread;
 NoteTask(Thread thread) {
   this.thread = thread;
 } 
 
 public void run() {
   thread.setDaemon(true);
   thread.start();
 }
}
