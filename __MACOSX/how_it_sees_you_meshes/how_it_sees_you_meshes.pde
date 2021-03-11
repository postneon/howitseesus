/* HOW IT SEES YOU
 *
 * @author: Martin Bartels <martin@apollomedia.nl> 
 *          Jim Brady <jim.brady@live.nl>
 *
 * @version: 1.0
 **********************************************************************************************************/
 
import wblut.geom.*;
import wblut.hemesh.*;
import wblut.core.*;
import wblut.processing.*;
import java.io.*;
import java.nio.*;
import java.util.*;
import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;
import controlP5.*;
//import spout.*;

UserMeshes meshes;
Ani ani_x, ani_y, ani_z, ani_translate_y;
float ani_x_val = 5;
float ani_y_val = 0;
float ani_z_val = 0;
float ani_translate_y_val = 0;
int timer = 0;
int state = 0;
Ani fade_ani;
float ani_fade = 0;
int new_state = 0;
int next_bodies = 0;
int next_hands = 0;
int next_heads = 0;
boolean is_switching_state = false;
Random random_generator;
ControlP5 cp5;
//Spout spout;

int setting_sides_width_left = 0;
int setting_sides_width_right = 0;
boolean draw_controls = false;

// 
// ---------------------------------------------------------------------------------------------------------
void setup() {

  //size(800, 1200, P3D);
  fullScreen(P3D, 1);

  Ani.init(this);
  Ani.overwrite();
  fade_ani = new Ani(this, 3, "ani_fade", 255, Ani.SINE_OUT);
  
  random_generator = new Random();

  settingsControl();
  timer = millis();

  meshes = new UserMeshes(this);
  getBodyMeshes();
  //frameRate(30);
  //spout = new Spout(this);
  
  //spout.createSender("HISY Meshes");
}

// 
// ---------------------------------------------------------------------------------------------------------
void fadeIn(int s) {
  
  is_switching_state = true;
  
  new_state = s;
  fade_ani.setBegin(0);
  fade_ani.setEnd(255);
  fade_ani.setCallback("onEnd:afterFadeIn");

  fade_ani.start();
}

// 
// ---------------------------------------------------------------------------------------------------------
void afterFadeIn() {

  state = new_state;
  if (state == 1) {
    getHeadMeshes();
  } else if (state == 2) {
    getHandMeshes();
  } else if (state == 0) {
    getBodyMeshes();
  }
  draw();
  fadeOut();
}

// 
// ---------------------------------------------------------------------------------------------------------
void fadeOut() {

  fade_ani.setBegin(255);
  fade_ani.setEnd(0);
  fade_ani.setCallback("onEnd:afterFadeOut");
  fade_ani.start();
}

//
// ---------------------------------------------------------------------------------------------------------
void afterFadeOut() {

  is_switching_state = false;
}

// 
// ---------------------------------------------------------------------------------------------------------
void draw() {

  background(255);
  pushMatrix();
  translate(width/2 - 400, (height / 2) + ani_translate_y_val, ani_z_val);

  rotateX(radians(180 + ani_x_val));
  rotateY(radians(ani_y_val));
  
  // Bodies
  if (state == 0) {
    
    noStroke();
    fill(0);

    int idx = 0;
    HE_MeshIterator mitr = meshes.scene.mItr();

    while (mitr.hasNext()) {
      pushMatrix();
      translate(-(idx * 100) + width/3, idx * 100, idx * 100);
      HE_Mesh m = mitr.next();
      HE_Face[] f = m.getFacesAsArray();
      
      m.rotateAboutCenterSelf(ani_y_val/500, 0, 1, 0);

      for (int i=0; i<f.length; i++) {
        color c = f[i].getColor();
        fill(c);
        meshes.render.drawFace(f[i]);
      }
      popMatrix();
      idx++;
    }
  }
  
  // Heads
  if (state == 1) {
    
    noStroke();
    fill(0);

    int idx = 0;
    HE_MeshIterator mitr = meshes.scene.mItr();

    while (mitr.hasNext()) {
      pushMatrix();
      HE_Mesh m = mitr.next();
      HE_Face[] f = m.getFacesAsArray();
      WB_Point p3d = m.getCenter();
      int mult = -1;
      if (idx % 2 == 0) {
        mult = 1;
      }
      translate(-(idx * 100) * mult + width/3, -(float)p3d.coords()[1], (idx * 100));
      //translate((idx * 100) * mult, -(float)p3d.coords()[1], (idx * 100));
      m.rotateAboutCenterSelf(ani_y_val/50, 0, 1, 0);
      for (int i=0; i<f.length; i++) {
        color c = f[i].getColor();
        fill(c);
        meshes.render.drawFace(f[i]);
      }
      popMatrix();
      idx++;
    }
  }
  
  // Hands
  if (state == 2) {
    
    noStroke();
    fill(0);

    int idx = 0;
    HE_MeshIterator mitr = meshes.scene.mItr();

    while (mitr.hasNext()) {
      pushMatrix();
      HE_Mesh m = mitr.next();
      HE_Face[] f = m.getFacesAsArray();
      WB_Point p3d = m.getCenter();
      int mult = -1;
      if (idx % 2 == 0) {
        mult = 1;
      }
      translate(-(idx * 100) + width/3, 0, 0);
      //translate(-(float)p3d.coords()[0] + (75 * mult), -(float)p3d.coords()[1], (idx * 100));
      for (int i=0; i<f.length; i++) {
        color c = f[i].getColor();
        fill(c);
        meshes.render.drawFace(f[i]);
      }
      popMatrix();
      idx++;
    }
  }
  popMatrix();

  if (is_switching_state) {
    hint(DISABLE_DEPTH_TEST);
    blendMode(BLEND);
    fill(0, 0, 0, ani_fade);
    rect(0, 0, width, height);
    hint(ENABLE_DEPTH_TEST);
  }


  hint(DISABLE_DEPTH_TEST);
  blendMode(BLEND);
  fill(0, 0, 0);
  rect(0, 0, setting_sides_width_left, height);
  rect(width - setting_sides_width_right, 0, setting_sides_width_right, height);
  hint(ENABLE_DEPTH_TEST);

  hint(DISABLE_DEPTH_TEST);
  blendMode(BLEND);
  drawGui();
  hint(ENABLE_DEPTH_TEST);

  if (millis() - timer > 30000) {
    timer = millis();
    if (state == 0) {
      fadeIn(1);
    } else if (state == 1) {
      fadeIn(2);
    } else if (state == 2) {
      fadeIn(0);
    }
  }
  info();
  //spout.sendTexture();
}

// 
// ---------------------------------------------------------------------------------------------------------
void setupBodiesAni() {

  ani_x_val = -10;
  ani_x = Ani.to(this, 15, "ani_x_val", ani_x_val, Ani.SINE_IN_OUT);
  ani_x.setPlayMode(Ani.YOYO);
  ani_x.repeat();

  ani_y_val = 2;
  ani_y = Ani.to(this, 30, "ani_y_val", 13, Ani.SINE_IN_OUT);

  ani_z_val = 500;
  ani_z = Ani.to(this, 40, "ani_z_val", 2200, Ani.SINE_IN_OUT);

  ani_translate_y_val = 200;
  ani_translate_y = Ani.to(this, 40, "ani_translate_y_val", 500, Ani.SINE_IN_OUT);
}

// 
// ---------------------------------------------------------------------------------------------------------
void setupHeadAni() {

  ani_x_val = -2;
  ani_x = Ani.to(this, 30, "ani_x_val", 4, Ani.SINE_IN_OUT);

  ani_y_val = -.2;
  ani_y = Ani.to(this, 10, "ani_y_val", .2, Ani.SINE_IN_OUT);
  ani_y.setPlayMode(Ani.YOYO);
  ani_y.repeat();

  ani_z_val = 2250;
  ani_z = Ani.to(this, 40, "ani_z_val", 1800, Ani.SINE_IN_OUT);

  ani_translate_y_val = -50;
  ani_translate_y = Ani.to(this, 40, "ani_translate_y_val", 50, Ani.SINE_IN_OUT);
}

// 
// ---------------------------------------------------------------------------------------------------------
void setupHandAni() {

  ani_x_val = 0;
  ani_x = Ani.to(this, 15, "ani_x_val", 0, Ani.SINE_IN_OUT);
  ani_x.setPlayMode(Ani.YOYO);
  ani_x.repeat();

  ani_y_val = 0;
  ani_y = Ani.to(this, 30, "ani_y_val", 0, Ani.SINE_IN_OUT);

  ani_z_val = 1800;
  ani_z = Ani.to(this, 30, "ani_z_val", 2500, Ani.SINE_IN_OUT);

  ani_translate_y_val = -100;
  ani_translate_y = Ani.to(this, 30, "ani_translate_y_val", 0, Ani.SINE_IN_OUT);
}

// 
// ---------------------------------------------------------------------------------------------------------
void getBodyMeshes() {

  String base_dir = sketchPath("") + "../how_it_sees_you/exports";
  File[] dirs = listDirs(base_dir);
  ArrayList<String> body_meshes = new ArrayList<String>();
  ArrayList<String> user_body_names = new ArrayList<String>();
  
  for (int i= min(400, dirs.length-1); i>0; i--) {
    String user_base_dir = base_dir + "/" + dirs[i].getName();

    File body_dir = new File(user_base_dir + "/body");
    if (body_dir.exists()) {
      
      File[] bodies = listFiles(user_base_dir + "/body");
      for (int b=0; b<bodies.length; b++) {
        File f = bodies[b];
        String ext = getFileExtension(f);
        String file_name = getFileName(f);

        if ("obj".equals(ext)) {
          user_body_names.add(user_base_dir + "/body/" + file_name);
        }
      }
    }
  }
  
  for (int x=0; x<min(10, user_body_names.size()); x++) {
    body_meshes.add(user_body_names.get(random_generator.nextInt(user_body_names.size())));
  }

  meshes.load(body_meshes);
  setupBodiesAni();
}

// 
// ---------------------------------------------------------------------------------------------------------
void getHeadMeshes() {

  String base_dir = sketchPath("") + "../how_it_sees_you/exports";
  File[] dirs = listDirs(base_dir);
  ArrayList<String> body_meshes = new ArrayList<String>();
  ArrayList<String> user_body_names = new ArrayList<String>();
  
  for (int i= min(400, dirs.length-1); i>0; i--) {
    String user_base_dir = base_dir + "/" + dirs[i].getName();

    File body_dir = new File(user_base_dir + "/head");
    if (body_dir.exists()) {
      
      File[] bodies = listFiles(user_base_dir + "/head");
      for (int b=0; b<bodies.length; b++) {
        File f = bodies[b];
        String ext = getFileExtension(f);
        String file_name = getFileName(f);

        if ("obj".equals(ext)) {
          user_body_names.add(user_base_dir + "/head/" + file_name);
        }
      }
    }
  }
  
  for (int x=0; x<min(20, user_body_names.size()); x++) {
    body_meshes.add(user_body_names.get(random_generator.nextInt(user_body_names.size())));
  }

  meshes.load(body_meshes);
  setupHeadAni();
}

// 
// ---------------------------------------------------------------------------------------------------------
void getHandMeshes() {
  
  String base_dir = sketchPath("") + "../how_it_sees_you/exports";
  File[] dirs = listDirs(base_dir);
  ArrayList<String> body_meshes = new ArrayList<String>();
  ArrayList<String> user_body_names = new ArrayList<String>();
  
  for (int i= min(400, dirs.length-1); i>0; i--) {
    String user_base_dir = base_dir + "/" + dirs[i].getName();

    File body_dir = new File(user_base_dir + "/right_hand");
    if (body_dir.exists()) {
      
      File[] bodies = listFiles(user_base_dir + "/right_hand");
      for (int b=0; b<bodies.length; b++) {
        File f = bodies[b];
        String ext = getFileExtension(f);
        String file_name = getFileName(f);

        if ("obj".equals(ext)) {
          user_body_names.add(user_base_dir + "/right_hand/" + file_name);
        }
      }
    }
  }
  
  for (int x=0; x<min(20, user_body_names.size()); x++) {
   body_meshes.add(user_body_names.get(random_generator.nextInt(user_body_names.size())));
  }

  meshes.load(body_meshes);
  setupHandAni();
}

// 
// ---------------------------------------------------------------------------------------------------------
File[] listFiles(String dir) {

  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } else {
    return null;
  }
}

// 
// ---------------------------------------------------------------------------------------------------------
File[] listDirs(String dir) {

  File[] directories = new File(dir).listFiles(new FileFilter() {
    @Override
      public boolean accept(File file) {
      return file.isDirectory();
    }
  }
  );

  return directories;
}

// 
// ---------------------------------------------------------------------------------------------------------
String getFileName(File file) {

  String fileName = file.getName();
  int pos = fileName.lastIndexOf(".");
  if (pos > 0 && pos < (fileName.length() - 1)) { // If '.' is not the first or last character.
    fileName = fileName.substring(0, pos);
  }

  return fileName;
}

// 
// ---------------------------------------------------------------------------------------------------------
String getFileExtension(File file) {

  String name = file.getName();
  try {
    return name.substring(name.lastIndexOf(".") + 1);
  } 
  catch (Exception e) {
    return "";
  }
}

//
// -------------------------------------------------------------------------------------------------------
void info() {

  String txt_fps = String.format("%7.2f fps", frameRate);
  surface.setTitle(txt_fps);
}

//
// ---------------------------------------------------------------------------------------------------------
void settingsControl() {

  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  Group app_settings = cp5.addGroup("APP")
    .setPosition(0, 0)
    .setBackgroundColor(color(255, 50))
    .setSize(250, 150);

  cp5.addNumberbox("setting_sides_width_left").setLabel("LEFT")
    .setPosition(10, 10)
    .setRange(0, width)
    .setScrollSensitivity(1.1)
    .setGroup(app_settings);

  cp5.addNumberbox("setting_sides_width_right").setLabel("RIGHT")
    .setPosition(10, 50)
    .setRange(0, width)
    .setScrollSensitivity(1.1)
    .setGroup(app_settings);

  Accordion accordion = cp5.addAccordion("settings_accourdion")
    .setPosition(40, 40)
    .setWidth(200)
    .addItem(app_settings);

  cp5.loadProperties("settings/hisy.properties");
}

// 
// ---------------------------------------------------------------------------------------------------------
void keyPressed() {

  if ('s' == key) {
    cp5.saveProperties("settings/hisy.properties");
  }

  if ('m' == key) {
    draw_controls = !draw_controls;
  }
}

//
// ---------------------------------------------------------------------------------------------------------
void drawGui() {

  if (true == draw_controls) {
    cp5.draw();
  }
}