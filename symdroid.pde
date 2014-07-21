import ketai.sensors.KetaiSensor;
import ketai.ui.KetaiGesture;
import java.io.File;
import android.view.MotionEvent;
import java.lang.System;
import android.os.Environment;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import java.io.FileOutputStream;
import android.view.Menu;
import android.view.MenuItem;

  KetaiGesture gesture;
  KetaiSensor sensor;
  
  boolean DEBUG = false;
  int WIDTH = 450;
  int HEIGHT = 300;
  float ANGLE = TWO_PI/6;
  PVector CENTER = new PVector(0,0);
  float MIN_VEL = 0;
  float MAX_VEL = 2;
  float MIN_SIZE = 75;
  float MAX_SIZE = 250;
  int framerate = 30;
  
  float circAngle = 0;
  float size = 75;
  //calc height of the triangles
  float cellSize = sqrt(3) * (size/2);
  float colStep = 2 * cellSize;
  float rowStep = 1.5f * size - 1;
  float posX = 0;
  float posY = 0;
  float velocity = 0.0f;
  int step = 0;
  boolean rotate = true;
  int direction = 1;
  int imgInd = 0;
  boolean saveImg = false;
  
  ArrayList<String> imgs;
  PImage img;
  
  PVector firstPoint;  
  PVector circleCenter;
  String[] filenames;
  boolean first = true;
  
  final int SWIPE_MIN_DISTANCE = 100;
  final int SWIPE_MAX_OFF_PATH = 120;
  final int SWIPE_THRESHOLD_VELOCITY = 1000;
  
  public static final int SAVE_ID = Menu.FIRST;
  
  
  void setup() 
  {
    orientation(PORTRAIT);
    //frameRate(framerate);
    gesture = new KetaiGesture(this);
    sensor = new KetaiSensor(this);
    sensor.start();
    
    try 
    {
      filenames = getAssets().list("");
      for (String f : filenames) println(f);
      img = requestImage(filenames[0]);
    }
    catch(Exception e)
    {
      if (DEBUG) println(e);
    }
  }
  
  public int sketchWidth() {
    return displayWidth;
  }
 
  public int sketchHeight() {
    return displayHeight;
  }
 
  public String sketchRenderer() {
    return P3D; 
  }
  
  void draw() 
  {
    if (saveImg) saveImg();
    noStroke();
    
    posX = mouseX;
    posY = mouseY;  
    
    circleCenter = new PVector(mouseX, mouseY);
    moveCircular();


    cellSize = sqrt(3) * (size/2);
    colStep = 2 * cellSize;
    rowStep = 1.5f * size - 1;
    
    if (img.width < 1 && first) 
    {
      background(255);
      first = false;
    }
    else if(img.width > 0)
    {
      drawColumns();
    }
  }
  
  void drawColumns()
  {
    for (int ix=0; ix<=ceil(displayWidth/rowStep); ix++)
    {
      pushMatrix();
      translate(ix*rowStep,-(ix%2)*(colStep*0.5f));
      drawColumn();
      popMatrix();
    }
  }
  
  void drawColumn()
  {
    pushMatrix();
    for (int iy=0; iy<=ceil(displayHeight/colStep); iy++)
    {
        drawCell();
        translate(0, colStep);
    }
    popMatrix();
  }

  void drawCell()
  {
    firstPoint = new PVector(
          (CENTER.x + size * cos(ANGLE)),
          (CENTER.y + size * sin(ANGLE)));
      
    for (int j=6; j>0; j--) 
    {
        PVector secondPoint = new PVector(
            (CENTER.x + size * cos(ANGLE*j)),
            (CENTER.y + size * sin(ANGLE*j)));
        
        beginShape();
        scale(-1, 1);
        texture(img);
        vertex(CENTER.x, CENTER.y, posX, posY);
        vertex(firstPoint.x, firstPoint.y, posX+(size), posY+(size));
        vertex(secondPoint.x, secondPoint.y, posX-(size), posY+(size));
        endShape();
        
        firstPoint = secondPoint;
      }
  }
    
  void moveCircular()
  {
    circAngle  = (circAngle + direction * ((TWO_PI / framerate) * velocity)) % TWO_PI;
    PVector newPostition = new PVector(
          (circleCenter.x + size * cos(circAngle)),
          (circleCenter.y + size * sin(circAngle)));
    posX = newPostition.x;
    posY = newPostition.y;
  }
  
  /* IMAGE LOADER */  
  public boolean listAssetFiles(String path) 
  {
      imgs = new ArrayList<String>();
      String [] list;
      try 
      {
          list = getAssets().list(path);
          if (list.length > 0) 
          {
              // folder
              for (String file : list) {
                  if (!listAssetFiles(path + "/" + file))
                  {
                  return false;
                  }
              }
          } 
          else 
          {
            // file
              imgs.add(path);
          }
      } 
      catch (IOException e) 
      {
          return false;
      }
      return true; 
  }
  
  /* GESTURES & SENSORS */
  public void onPinch(float x, float y, float d) 
  {
    size += d/4;
    if (size < MIN_SIZE) size = MIN_SIZE;
    if (size > MAX_SIZE) size = MAX_SIZE;
  }
  
  public void onOrientationEvent(float x, float y, float z)
  {
    if ( z > -20 && z < 20) rotate = true;
    if ( y > -20 && y < 20) rotate = true;
    
    if (!rotate) return;
    
    // portrait 
    if (y < -25 && y > -90)
    {
      // rotate left or right
      if ((z > 20 && z < 35) || (z < -20 && z > -35))
      {
        if (velocity != 0)
        {
          velocity = 0;
          rotate = false;
        }
        else
        {
          velocity = 0.15f; 
          rotate = false;
        }
      }
    }
    // landscape 
    else if (z > 25 && z < 90)
    {
      // rotate left or right
      if ((y > 20 && y < 35) || (y < -20 && y > -35))
      {
        if (velocity != 0)
        {
          velocity = 0;
          rotate = false;
        }
        else
        {
          velocity = 0.075f; 
          rotate = false;
        }
      }
    }
    
  }
  //the coordinates of the start of the gesture, 
  //end of gesture and velocity in pixels/sec
  public void onFlick( float x, float y, float px, float py, float v) 
  {
    try 
    {
      if (abs(y - py) > SWIPE_MAX_OFF_PATH)
      {
        return;
      }
      
      // right to left swipe
      if (x - px > SWIPE_MIN_DISTANCE && abs(v) > SWIPE_THRESHOLD_VELOCITY) {
        imgInd--;
      } 
      // left to right swipe
        else if (px - x > SWIPE_MIN_DISTANCE && abs(v) > SWIPE_THRESHOLD_VELOCITY) {
        imgInd++;
      }
    } 
    catch (Exception e) 
    {
      if (DEBUG) println(e);
    }
        
    // check boundaries
    if (imgInd >= filenames.length-4) imgInd = 0;
    if (imgInd < 0) imgInd = filenames.length-4;
    
    try
    {
      img = loadImage(filenames[imgInd]);
    }
    catch (Exception e)
    {
      if (DEBUG) println(e);
    }
  }
  //these still work if we forward MotionEvents below
  public void mouseDragged()  {}
  public void mousePressed()  {}
  public void onDoubleTap(float x, float y) {}
  public void onTap(float x, float y) {}
  public void saveImg()
  {  
     saveFrame(Environment.getExternalStorageDirectory().getAbsolutePath() + "/symdroid/symdroid_" + System.currentTimeMillis() + ".png");
     img.save(Environment.getExternalStorageDirectory().getAbsolutePath() + "/symdroid/sym.png"); 
     saveImg = false;
  }
  public void onLongPress(float x, float y) 
  {
  }
  public void onRotate(float x, float y, float ang) 
  {
  }
  
  public boolean surfaceTouchEvent(MotionEvent event) {
    //call to keep mouseX, mouseY, etc updated
    super.surfaceTouchEvent(event);
    //forward event to class for processing
    return gesture.surfaceTouchEvent(event);
  }

/* MENU */

@Override
public boolean onCreateOptionsMenu(Menu menu) {
 // hier werden die einzelnen Menüeinträge erzeugt
 menu.add(0, SAVE_ID, Menu.NONE, "Save");
 return super.onCreateOptionsMenu(menu);
}

//wird aufgerufen, wenn ein Menüpunkt ausgewählt worden ist
@Override
public boolean onOptionsItemSelected(MenuItem item) {
 //die Auswahl wird über die ItemId des Menüpunktes überprüft
 switch (item.getItemId()) {
 case SAVE_ID:
   saveImg = true;
   break;
 }
 return super.onOptionsItemSelected(item);
}



