// This Audio Visualizer works together with MIDI device which outputs CC MIDI messages on channel 0 and controller number 0 - 4. 

//Short description_______________________________________________________________________________________________________________________________
// This deliverable for the academic study ‘Creative Programming’ shows an Audio Visualizer which feeds on the internal sound flowing
// through your computer! Various settings can be changed by the Arduino MIDI controller or literally any other device capable of sending
// MIDI messages (See the Maschine MK2 drum controller in the video). If you do not have access of a MIDI device, hit the ’s’ key to get
// a preview of the possibilities of the Audio Visualizer. 

//How it works____________________________________________________________________________________________________________________________________
// Processing uses the Minim library to analyse the incoming audio for amplitude, spectrum frequencies and beat detection. Certain parameters 
// are linked to these analyses to make the sound appear visually on your screen. With the Arduino (or other MIDI devices) it is possible to 
// change certain parameters to make the Audio Visualizer more appealing.

//Requirements to run the Audio Visualizer_________________________________________________________________________________________________________
//- Processing 3.0
//- Internal audio routing possibilities (I used SoundFlower for OS X)
//- For best performance, play a song with a noticeable bass drum.

// © Copyright by Bas van Straaten

// Import some necessary library's
import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;
import themidibus.*;

// Modify to your needs
String deviceNameOne = "MIDI/MOCO for LUFA"; // find your MIDI device using MidiBus.list() in the setup
String deviceNameTwo = "Maschine MK2 Virtual Input";
float borderAroundCircles = 25;
float boxSize = 4;

// Do not modify following classes/ variables!
AudioInput audioIn;
BeatDetect beat;  
MidiBus midi1;
MidiBus midi2;
Minim minim;
FFT fft;
boolean amplitudeMultiplier;
boolean autoChangeColor;
int numberOfCircles = 1;
float smoothFactor = 1;
float increaseRotate;
float multiplier = 3;
float increaser = 0;
float alpha = 255;
float rgbr2 = 255;
float rgbg2 = 255;
float rgbb2 = 255;
float smoother;
float rotator;
float rgbr;
float rgbg;
float rgbb;
float amp;

//_______________________________________________________________________________________________________________________________
void setup() {
  fullScreen(OPENGL); // Sketch will always be fullscreen
  midi1 = new MidiBus(this, deviceNameOne, deviceNameOne); // Initialize the MIDI devices..
  midi2 = new MidiBus(this, deviceNameTwo, deviceNameTwo);
  minim = new Minim(this); // Create a new Minim class for sound input
  audioIn = minim.getLineIn(Minim.STEREO);  // Get the system audio
  fft = new FFT(audioIn.bufferSize(), audioIn.sampleRate()); // Create a new FFT class for Fast Fourier Transformation
  beat = new BeatDetect();
  strokeWeight(4);
  rectMode(CENTER);
}

//_______________________________________________________________________________________________________________________________
void draw () {
  background(rgbr, rgbg, rgbb, 50); // Reset the background for every loop
  beatDetection();
  audioVisualizer();
}

//_______________________________________________________________________________________________________________________________
void beatDetection() {
  beat.detect(audioIn.mix); // Detect the beat of the system audio
  lights(); // enable 3D lights
  fill(rgbr2, rgbg2, rgbb2, 100);
  noStroke();
  if (beat.isOnset()) { // If beat detected, draw some 3D boxes and rotate them around their own axis
    for (int x = 0; x <= width; x+= 40) {
      for (int y = 0; y <= height; y+= 40) {     
        pushMatrix(); 
        translate(x, y);
        rotateX(increaseRotate);
        rotateY(increaseRotate);
        rotateZ(increaseRotate);
        box(boxSize);
        popMatrix();
      }
    }
    if (autoChangeColor) {
      rgbr = random(255);
      rgbg = random(255);
      rgbb = random(255);
      rgbr2 = random(255);
      rgbg2 = random(255);
      rgbb2 = random(255);
    }
  }
  increaseRotate += .4;
}

//_______________________________________________________________________________________________________________________________
void audioVisualizer() {
  fft.forward(audioIn.mix); // Execute a FFT on the increaseroming audio
  if (amplitudeMultiplier) {
    amp = map(audioIn.mix.level(), 0, 1, 1, 1.2);
  } else {
    amp = 1;
  }
  stroke(rgbr2, rgbg2, rgbb2, alpha); 
  translate(width/2, height/2); // Get the middle point to rotate around
  for (int size = int(100*multiplier); size <= int(100*multiplier+(10*numberOfCircles)); size += borderAroundCircles) {
    for (int deg = 0; deg <= 360; deg++) { // Draw two full reacting circles 
      pushMatrix();
      smoother +=  ((fft.getBand(deg+20)/100 - smoother) * smoothFactor); // Smooth out the frequenty amplitude
      float Cx = size*cos(radians(deg+90+increaser*(map(size, 150, 250, -1, 2)))) * amp * (1 + smoother);
      float Cy = size*sin(radians(deg+90+increaser*(map(size, 150, 250, -2, 2)))) * amp * (1 + smoother); 
      translate(0, 0, smoother*200);
      point(Cx, Cy);
      point(-Cx, Cy);
      popMatrix();
    }
  }
  increaser = increaser + rotator;
}

//_______________________________________________________________________________________________________________________________
void controllerChange(int channel, int controlNumber, int value) { // Get incoming MIDI messages and map them to variables
  if (controlNumber == 16) { // If turning knob 0, change the alpha value of the audio visualizer
    alpha = map(value, 0, 127, 0, 255);
  }
  if (controlNumber == 0 || controlNumber == 17) { // If turning knob 1, change the background
    rgbr = random(255);
    rgbg = random(255);
    rgbb = random(255);
  }
  if (controlNumber == 1 || controlNumber == 18) { // If turning knob 2, increase/ decrease the number of circles in the audio visualizer
    numberOfCircles = int(map(value, 0, 127, 0, 10));
  }
  if (controlNumber == 2 || controlNumber == 19) { // If turning knob 3, increase/ decrease the smoothness of the audio visualizer
    smoothFactor = map(value, 0, 127, 1, 0.001);
  }
  if (controlNumber == 3 || controlNumber == 20) { // If turning knob 3, increase/ decrease the size of circles in the audio visualizer
    multiplier = map(value, 0, 127, 1, 4);
  }
  if (controlNumber == 4 || controlNumber == 21) { // If turning knob 4, rotate the audio visualizer
    rotator = map(value, 0, 127, -1, 1);
  }
}

//_______________________________________________________________________________________________________________________________
void noteOn(int channel, int pitch, int volume) { // Get incoming MIDI messages and map them to variables
  if (pitch == 12) { // If selected, change background color automatically
    if (autoChangeColor) {
      autoChangeColor = false;
    } else {
      autoChangeColor =true;
    }
  }
  if (pitch == 13) {
    if (amplitudeMultiplier) {
      amplitudeMultiplier = false;
    } else {
      amplitudeMultiplier =true;
    }
  }
  if (pitch == 14) { // If selected, change color of audio visualizer
    rgbr2 = random(255);
    rgbg2 = random(255);
    rgbb2 = random(255);
  }
  if (pitch == 15) { // If selected, change background color automatically
    rgbr = random(255);
    rgbg = random(255);
    rgbb = random(255);
  }
}

//_______________________________________________________________________________________________________________________________
void keyPressed() {
  if (key == 's' || key == 'S') {
    autoChangeColor =true;
    smoothFactor = 0.01;
    numberOfCircles = 10;
    rotator = 0.2;
  }  
}