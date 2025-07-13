import processing.serial.*;
import java.util.ArrayList;
import ddf.minim.*;

Serial myport;
PFont f;
int Angle = 0, Distance = 0;
String data;
float radarRadius = 600;
float angleRad, x, y;
ArrayList<TrailSegment> redTrail = new ArrayList<TrailSegment>();
//mahdi sound effects idk
Minim minim;
AudioPlayer beepSound;

class TrailSegment {
  float x, y, prevX, prevY, alpha;
  float timestamp;
  TrailSegment(float x, float y, float prevX, float prevY, float timestamp) {
    this.x = x;
    this.y = y;
    this.prevX = prevX;
    this.prevY = prevY;
    this.timestamp = timestamp;
    this.alpha = 128;
  }
  void update() {
    float elapsedTime = millis() - timestamp;
    alpha = max(0, 128 - (elapsedTime / 1500) * 128);
  }
  void lerpToPosition(float targetX, float targetY, float lerpFactor) {
    x = lerp(prevX, targetX, lerpFactor);
    y = lerp(prevY, targetY, lerpFactor);
  }
}

void setup() {
  size(1300, 700);
  smooth();
  f = createFont("David Bold", 30);
  textFont(f);
  minim = new Minim(this);//mahdi asound
  beepSound = minim.loadFile("high-beep-sound-fx_[cut_0sec] (1).mp3");
  myport = new Serial(this, Serial.list()[0], 9600);
  myport.bufferUntil('.');
}

// Simulated radar sweeping angle and pulsing effect
boolean increasing = true; // Indicates whether the angle is increasing or decreasing
int sweepSpeed = 2; // Adjust the speed of the sweep
int pulseAlpha = 0; // Alpha value for the pulsing effect
boolean pulsingOut = true; // Indicates whether the pulse is expanding or fading

void draw() {
  background(0);
  gradientBackground();
  pushMatrix();
  translate(width / 2, height - 50);

  if (Distance < 26 && Distance > -1) {
    playBeep();
  }

  radarArea();
  glowingLineAtAngle();
  greenSector();
  horizontalLine();
  drawRedTrail();
  words();
  drawRadarOrigin();
  
  // Call the pulsing effect here (this will affect the background/pulsing area)
  pulsingEffect();
  
  // Now draw the degree labels after the pulse
  drawDegreeLabels();
  
  popMatrix();
}


void drawDegreeLabels() {
  // Set text color to white (opaque) to ensure labels are not affected by the pulse
  fill(255);  // Opaque white
  textAlign(CENTER, CENTER);
  
  // Radar angles and labels
  for (int angle = 30; angle <= 150; angle += 30) {
    float angleRad = radians(angle);
    float smallRadarRadius = radarRadius * 0.8;  // Use the same size for consistency
    float labelDistanceFactor = 1.15; // Increase spacing for labels
    float labelX = smallRadarRadius * labelDistanceFactor * cos(angleRad);
    float labelY = -smallRadarRadius * labelDistanceFactor * sin(angleRad);

    text(angle + "'", labelX, labelY); // Place the angle labels
  }

  // Draw the 0 and 180 labels separately
  float smallRadarRadius = radarRadius * 0.8;
  textAlign(CENTER, CENTER);
  text("0'", smallRadarRadius * 1.15, -20); // Move slightly above the green line for 0 degrees
  text("180'", -smallRadarRadius * 1.15, -20); // Move slightly above the green line for 180 degrees
}


 //<>//


void gradientBackground() {
  // Set a dark background with a slight gradient
  for (int i = 0; i < height; i++) {
    stroke(lerpColor(color(0, 0, 50), color(0, 0, 0), map(i, 0, height, 0, 1)));
    line(0, i, width, i);
  }

  // Set gridline properties (light color for a subtle effect)
  stroke(0, 255, 0, 50); // Light green color for gridlines (adjust opacity as needed)
  strokeWeight(1); // Thin lines for the grid

  // Draw vertical gridlines
  for (int x = 0; x < width; x += 50) {  // 50px spacing for vertical lines
    line(x, 0, x, height);
  }

  // Draw horizontal gridlines
  for (int y = 0; y < height; y += 50) {  // 50px spacing for horizontal lines
    line(0, y, width, y);
  }
}


float prevX = 0, prevY = 0;

void glowingLineAtAngle() {
  // Define maxPulseRadius locally within the function
  float maxPulseRadius = radarRadius * 0.8;  // Constrain to 80% of radarRadius

  angleRad = radians(Angle);
  x = maxPulseRadius * cos(angleRad); // Use maxPulseRadius instead of radarRadius
  y = -maxPulseRadius * sin(angleRad); // Constrain the y coordinate as well

  float lerpFactor = 0.1;
  float lerpedX = lerp(prevX, x, lerpFactor);
  float lerpedY = lerp(prevY, y, lerpFactor);
  prevX = lerpedX;
  prevY = lerpedY;
  
  if (Distance < 26) {
    float scaledDistance = map(Distance, 0, 26, 0, maxPulseRadius); // Scale to maxPulseRadius
    float dotX = scaledDistance * cos(angleRad);
    float dotY = -scaledDistance * sin(angleRad);
    if (redTrail.size() > 0) {
      TrailSegment lastSegment = redTrail.get(redTrail.size() - 1);
      redTrail.add(new TrailSegment(dotX, dotY, lastSegment.x, lastSegment.y, millis()));
    } else {
      redTrail.add(new TrailSegment(dotX, dotY, dotX, dotY, millis()));
    }
    stroke(255, 0, 0, 200);
  } else {
    stroke(0, 255, 0, 200);
  }
  
  strokeWeight(6);
  line(0, 0, lerpedX, lerpedY); // Red line constrained to maxPulseRadius
}


void horizontalLine() {
  stroke(98, 245, 31);
  strokeWeight(2);
  
  // Set the smaller radar radius (radarRadius * 0.8 as per your radar area)
  float smallRadarRadius = radarRadius * 0.8; // You can adjust this to the desired size of the last arc
  
  // Draw the horizontal line up to the last arc
  line(-smallRadarRadius, 0, smallRadarRadius, 0);
}


void radarArea() {
  noFill();
  stroke(98, 245, 31, 180); // Green color with transparency
  strokeWeight(2);

  // Set the smaller radar radius (let's reduce it)
  float smallRadarRadius = radarRadius * 0.8; // 80% of the original size, adjust as needed

  // Radar arcs
  arc(0, 0, smallRadarRadius * 2, smallRadarRadius * 2, PI, TWO_PI); // Outer arc
  arc(0, 0, smallRadarRadius, smallRadarRadius, PI, TWO_PI); // Inner arc

  // Radar lines
  for (int angle = 30; angle <= 150; angle += 30) {
    angleRad = radians(angle);
    x = smallRadarRadius * cos(angleRad);
    y = -smallRadarRadius * sin(angleRad);
    line(0, 0, x, y); // Draw line from center to the radar boundary

    // Adjust labels to be spaced away from the visible radar area
    float labelDistanceFactor = 1.15; // Increase spacing for labels
    float labelX = smallRadarRadius * labelDistanceFactor * cos(angleRad);
    float labelY = -smallRadarRadius * labelDistanceFactor * sin(angleRad);

    textAlign(CENTER, CENTER);
    text(angle + "'", labelX, labelY); // Place the angle labels
  }

  // Draw the 0 and 180 labels separately with additional spacing
  textAlign(CENTER, CENTER);
  text("0'", smallRadarRadius * 1.15, -20); // Move slightly above the green line for 0 degrees
  text("180'", -smallRadarRadius * 1.15, 1-20); // Move slightly above the green line for 180 degrees
}
// Pulsing wave effect variables
float pulseRadius = 0;         // Current radius of the pulse
float pulseSpeed = 4;          // Speed of the pulse expansion
float maxPulseRadius = radarRadius * 0.8; // Maximum pulse radius (80% of radarRadius)

void pulsingEffect() {
  noStroke();

  // Set the pulse alpha value to a fixed, full alpha for visibility
  fill(0, 255, 0, 60); // Green color with some transparency
  
  // Draw the pulsing effect within the semi-circle, confined to the maxPulseRadius
  beginShape();
  vertex(0, 0); // Center point of the radar
  for (float a = 0; a <= 180; a += 1) { // Loop to draw only in the semi-circle
    float angleRad = radians(a);
    float x = pulseRadius * cos(angleRad); // Use pulseRadius for expanding wave
    float y = -pulseRadius * sin(angleRad);
    vertex(x, y);
  }
  vertex(0, 0); // Close the shape back at the center
  endShape(CLOSE);

  // Animate pulse radius: expand outward without shrinking
  pulseRadius += pulseSpeed; // Increase radius to simulate expansion

  // Reset pulse once it reaches maxPulseRadius
  if (pulseRadius >= maxPulseRadius) {
    pulseRadius = 0;  // Reset the pulse to start again
  }
}


float sweepProgress = 0;  // Variable to control the progression of the sweep animation

void greenSector() {
  // Define maxPulseRadius to limit the green sector's sweep
  float maxPulseRadius = radarRadius * 0.8;  // Constrained radius (80% of radarRadius)

  smoothedAngle = lerp(smoothedAngle, Angle, smoothingFactor);
  smoothedAngle = constrain(smoothedAngle, 0, 180);
  boolean isCounterClockwise = smoothedAngle > prevAngle;
  prevAngle = smoothedAngle;

  // Animate sweepProgress: control how much of the sector is visible
  if (sweepProgress < 1) {
    sweepProgress += 0.02;  // Increase the sweepProgress for expanding the sector
  } else {
    sweepProgress = 1;  // Stop expanding once fully expanded
  }

  // Adjust the start and end angles for the arc
  float startAngle = smoothedAngle - trailLength;
  float endAngle = smoothedAngle + trailLength;

  // Ensure the start and end angles are within the 0 to 180 degree range
  startAngle = constrain(startAngle, 0, 180);
  endAngle = constrain(endAngle, 0, 180);

  // Create a smooth animation where the arc collapses into a line and expands again
  float sectorWidth = maxPulseRadius * sweepProgress;  // Control the width of the arc based on sweepProgress

  // Draw the green sector, constrained by maxPulseRadius
  noStroke();
  fill(0, 255, 0, 100);  // Green color with transparency

  beginShape();
  vertex(0, 0);  // Start at the center of the radar
  for (float a = startAngle; a <= endAngle; a += 1) {
    float angleRad = radians(a);
    float x = sectorWidth * cos(angleRad);  // Constrained width of the sector based on sweepProgress
    float y = -sectorWidth * sin(angleRad); // Constrained height of the sector based on sweepProgress
    vertex(x, y);  // Add points to form the arc
  }
  vertex(0, 0);  // Close the shape back at the center
  endShape(CLOSE);  // Complete the sector shape
}

void playBeep() {
  if (!beepSound.isPlaying()) {
    beepSound.rewind();
    beepSound.play();
  }
}




void drawRadarOrigin() {
  // Highlight the origin with a glowing effect
  noStroke();
  fill(0, 255, 0, 255);  // Green color for the glowing effect
  ellipse(0, 0, 15, 15);  // Origin marker

  // Optional: Add a smaller white cross or marker at the origin
  stroke(255);  // White color for the cross
  strokeWeight(3);
  line(-10, 0, 10, 0); // Horizontal line
  line(0, -10, 0, 10); // Vertical line
}


void drawRedTrail() {
  for (int i = redTrail.size() - 1; i >= 0; i--) {
    TrailSegment trail = redTrail.get(i);
    trail.update();
    if (trail.alpha <= 0) {
      redTrail.remove(i);
    } else {
      trail.lerpToPosition(trail.x, trail.y, 0.1);
      stroke(255, 0, 0, trail.alpha);
      strokeWeight(10);
      point(trail.x, trail.y);
    }
  }
}

void words() {
  fill(98, 245, 31);
  textAlign(LEFT);
  text("CS Project", -605, -600);
  fill(255);
  textAlign(LEFT);
  text("Angle -- " + int(Angle) + " '", -605, -550);
  textAlign(RIGHT);
  if (Distance == 26) {
    text("No object detected", 625 - 20, -550);
  } else {
    text("Distance -- " + int(Distance) + " cm", 625 - 20, -550);
  }
}

void serialEvent(Serial myport) {
  data = myport.readStringUntil('.');
  data = data.substring(0, data.length() - 1);
  int index1 = data.indexOf(",");
  Angle = int(data.substring(0, index1));
  Distance = min(26, int(data.substring(index1 + 1)));
  

}

float smoothedAngle = 0;
float smoothingFactor = 0.1;
int trailLength = 20;
float prevAngle = 0;
