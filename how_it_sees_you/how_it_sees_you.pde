/* HOW IT SEES US
 *
 * @author: Post Neon <info@post-neon.com> 
 *          Luca Claessens <luca@lookaluca.com>
 *
 * @version: 1.0
 **********************************************************************************************************/

// Libs
// ---------------------------------------------------------------------------------------------------------
import controlP5.*;
import SimpleOpenNI.*;
import wblut.geom.*;
import wblut.hemesh.*;
import wblut.core.*;
import wblut.processing.*;
import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;
import com.jogamp.common.nio.*;
import com.jogamp.opengl.*;
//import com.thomasdiewald.pixelflow.java.*;
//import com.thomasdiewald.pixelflow.java.dwgl.*;
//import com.thomasdiewald.pixelflow.java.flowfieldparticles.*;
//import com.thomasdiewald.pixelflow.java.imageprocessing.*;
//import com.thomasdiewald.pixelflow.java.imageprocessing.filter.*;
//import com.thomasdiewald.pixelflow.java.utils.*;
import java.io.*;
import java.nio.*;
import java.util.*;
import java.awt.Rectangle;
import oscP5.*;
import netP5.*;
import spout.*;

OscP5 oscP5;
NetAddress max_patch;
Spout spout;

// Kinect
// ---------------------------------------------------------------------------------------------------------
Kinect kinect;
KinectMesh kinect_mesh;
KinectPointCloud kinect_point_cloud;
Renderer renderer;

// Blur shader
// ---------------------------------------------------------------------------------------------------------
PShader blur;
PShader grad;

// Points and colors
// ---------------------------------------------------------------------------------------------------------
ArrayList<PVector> points = new ArrayList();
ArrayList colors = new ArrayList();

// Mesh
// ---------------------------------------------------------------------------------------------------------
int mesh_save_timer = 0;
int mesh_saved = 0;
String mesh_export_path = "";
UserMeshes mesh_user;

// Scene switch
int last_user_present = 0;

// Settings
// ---------------------------------------------------------------------------------------------------------
ControlP5 cp5;

// Mesh settings
int setting_mesh_simplification = 3;
int setting_mesh_smoothness = 15;
int setting_mesh_save_interval = 1;
int await_user_timer_interval = 3;
int setting_mesh_num_meshes = 2;
boolean setting_create_meshes = true;

// Particle setings
int setting_particles_simplification = 2;
int setting_particles_scale = 3;
int setting_particles_num_particles = 80000;
int setting_particles_particle_size = 3;
int setting_particles_particle_color_r = 0;
int setting_particles_particle_color_g = 0;
int setting_particles_particle_color_b = 0;
int setting_particles_particle_color_a = 0;
int setting_particles_offset_x = 0;
int setting_particles_offset_y = 0;
int setting_particles_offset_z = 3000;
boolean setting_particles_particle_bloom_fx = true;

// Point cloud settings
int setting_point_cloud_blur = 5;
int setting_point_cloud_size = 5;
int setting_point_cloud_offset_x = 0;
int setting_point_cloud_offset_y = 0;
int setting_point_cloud_offset_z = 1200;

int setting_min_fade_distance = 200;
int setting_max_fade_distance = 2000;

// Kinect settings
int setting_max_z = 2000;
int setting_min_z = 2000;
int setting_sides_width_left = 0;
int setting_sides_width_right = 0;

// Show / hide settings
boolean draw_controls = false;
boolean kinectUpdated = false;
// User present
Textlabel user_present_label;
boolean user_present = false;
boolean user_present_close = false;
int user_id = -1;

// States
// ---------------------------------------------------------------------------------------------------------
int STATE_DRAW_POINTCLOUD = 0;
int STATE_DRAW_MESH = 1;
int STATE_MESH_DRAWN = 2;

float USER_PRESENT_OPACITY_SIGNAL = 0.0;
float AWAITING_USER_OPACITY_SIGNAL = 1.0;

int state = 0;
void setState(int s) { 
  state = s;
  last_user_present = millis();
}
int getState() { 
  return state;
 }
Boolean isState(int s) { 
  return (s == state);
}

Ani fade_ani;
float ani_fade = 0;
int switch_state = 0;
boolean is_switching_state = false;
boolean sent_user_present = false;
boolean sent_awaiting_user = false;


// Setup
// ---------------------------------------------------------------------------------------------------------
void setup() {

  size(800, 1200, P3D);
  //fullScreen(P3D, 2);

  setupBlurShader();
  setupKinectMesh();
  setupUserMeshes();
  //setupKinectParticles();
  setupPointCloud();
  setupKinect();
  setupOSC();
  
  grad = loadShader("frag.glsl");  

  settingsControl();

  setState(STATE_DRAW_POINTCLOUD);

  Ani.init(this);
  Ani.overwrite();
  fade_ani = new Ani(this, 2, "ani_fade", 255, Ani.SINE_OUT);

  spout = new Spout(this);
  
  spout.createSender("Orbbec Sender");
  smooth(4);
  frameRate(30);
}

//
// -------------------------------------------------------------------------------------------------------
void switchState(int s) {

  if (is_switching_state == true) {
    return;
  }

  switch_state = s;
  fadeIn();
}

//
// -------------------------------------------------------------------------------------------------------
void fadeIn() {

  if (is_switching_state == true) {
    return;
  }

  is_switching_state = true;
  fade_ani.setBegin(0);
  fade_ani.setEnd(255);
  fade_ani.setCallback("onEnd:setStateAfterFadeIn");

  fade_ani.start();
}

//
// -------------------------------------------------------------------------------------------------------
void setStateAfterFadeIn() {

  delay(3500);
  setState(switch_state);
  fadeOut();
}

//
// -------------------------------------------------------------------------------------------------------
void fadeOut() {

  fade_ani.setBegin(255);
  fade_ani.setEnd(0);
  fade_ani.setCallback("onEnd:setStateAfterFadeOut");
  fade_ani.start();
}

//
// -------------------------------------------------------------------------------------------------------
void setStateAfterFadeOut() {

  is_switching_state = false;
  sent_user_present = false;
  sent_awaiting_user = false;
}

//
// -------------------------------------------------------------------------------------------------------
void setupOSC() {
  
  oscP5 = new OscP5(this, 4444);
  max_patch = new NetAddress("127.0.0.1", 7000);
}

// Setup Blur Shader
// ---------------------------------------------------------------------------------------------------------
void setupBlurShader() {  

  blur = loadShader("blur.glsl");
  blur.set("resolution", float(width), float(height));
}

// Setup Kinect
// ---------------------------------------------------------------------------------------------------------
void setupKinect() {

  kinect = new Kinect(this);
  thread("updateKinect");
}

//void setupKinectParticles() {
//  kinect_particles = new KinectParticles(this);
//}

// Setup Kinect Mesh
// ---------------------------------------------------------------------------------------------------------
void setupKinectMesh() {

  kinect_mesh = new KinectMesh();
  kinect_mesh.setup(this);

  renderer = new Renderer();
}

// Setup Kinect Particles
// ---------------------------------------------------------------------------------------------------------
//void setupKinectParticles() {

//  kinect_particles = new KinectParticles(this);
//}

// Setup Kinect Point Cloud
// ---------------------------------------------------------------------------------------------------------
void setupPointCloud() {

  kinect_point_cloud = new KinectPointCloud(this);
}

// Setup Kinect Point Cloud
// ---------------------------------------------------------------------------------------------------------
void setupUserMeshes() {
  mesh_user = new UserMeshes(this);
}
// Settings control
// ---------------------------------------------------------------------------------------------------------
void settingsControl() {

  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  Group kinect_settings = cp5.addGroup("KINECT")
    .setPosition(0, 0)
    .setBackgroundColor(color(255, 50))
    .setSize(250, 150);

  Group particles_settings = cp5.addGroup("PARTICLES")
    .setPosition(0, 0)
    .setBackgroundColor(color(255, 50))
    .setSize(250, 300);

  Group point_cloud_settings = cp5.addGroup("POINT CLOUD")
    .setPosition(0, 0)
    .setBackgroundColor(color(255, 50))
    .setSize(250, 220);

  Group mesh_settings = cp5.addGroup("MESH")
    .setPosition(0, 0)
    .setBackgroundColor(color(255, 50))
    .setSize(250, 150);

  cp5.addSlider("setting_max_z").setLabel("MAX Z")
    .setPosition(10, 10)
    .setRange(100, 5000)
    .setNumberOfTickMarks(20)
    .setGroup(kinect_settings);

  cp5.addSlider("setting_min_z").setLabel("MIN USER Z")
    .setPosition(10, 35)
    .setRange(100, 5000)
    .setNumberOfTickMarks(20)
    .setGroup(kinect_settings);

  cp5.addNumberbox("setting_sides_width_left").setLabel("LEFT")
    .setPosition(10, 60)
    .setRange(0, width)
    .setScrollSensitivity(1.1)
    .setGroup(kinect_settings);

  cp5.addNumberbox("setting_sides_width_right").setLabel("RIGHT")
    .setPosition(100, 60)
    .setRange(0, width)
    .setScrollSensitivity(1.1)
    .setGroup(kinect_settings);

  user_present_label = cp5.addTextlabel("label")
    .setText("USER: AWAY")
    .setPosition(10, 110)
    .setGroup(kinect_settings);

  cp5.addSlider("setting_mesh_simplification").setLabel("SIMPLIFICATION")
    .setPosition(10, 10)
    .setRange(1, 10)
    .setNumberOfTickMarks(10)
    .setGroup(mesh_settings);

  cp5.addSlider("setting_mesh_smoothness").setLabel("SMOOTHING")
    .setPosition(10, 35)
    .setRange(1, 20)
    .setNumberOfTickMarks(10)
    .setGroup(mesh_settings);

  cp5.addSlider("setting_mesh_save_interval").setLabel("SAVE INTERVAL")
    .setPosition(10, 60)
    .setRange(1, 10)
    .setNumberOfTickMarks(10)
    .setGroup(mesh_settings);

  cp5.addSlider("setting_mesh_num_meshes").setLabel("NUM MESHES")
    .setPosition(10, 85)
    .setRange(1, 10)
    .setNumberOfTickMarks(10)
    .setGroup(mesh_settings);

  cp5.addToggle("setting_create_meshes").setLabel("MESHES")
    .setPosition(10, 110)
    .setSize(15, 15)
    .setGroup(mesh_settings);

  cp5.addSlider("setting_particles_scale").setLabel("SCALE")
    .setPosition(10, 10)
    .setRange(1, 15)
    .setNumberOfTickMarks(20)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_num_particles").setLabel("NUM PARTICLES")
    .setPosition(10, 35)
    .setRange(100, 100000)
    .setNumberOfTickMarks(10)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_particle_size").setLabel("PARTICLE SIZE")
    .setPosition(10, 60)
    .setRange(1, 10)
    .setNumberOfTickMarks(10)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_particle_color_r").setLabel("RED")
    .setPosition(10, 85)
    .setRange(1, 255)
    .setNumberOfTickMarks(10)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_particle_color_g").setLabel("GREEN")
    .setPosition(10, 110)
    .setRange(1, 255)
    .setNumberOfTickMarks(10)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_particle_color_b").setLabel("BLUE")
    .setPosition(10, 135)
    .setRange(1, 255)
    .setNumberOfTickMarks(10)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_particle_color_a").setLabel("ALPHA")
    .setPosition(10, 160)
    .setRange(1, 255)
    .setNumberOfTickMarks(20)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_offset_x").setLabel("X OFFSET")
    .setPosition(10, 185)
    .setRange(-width*6, width*6)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_offset_y").setLabel("Y OFFSET")
    .setPosition(10, 210)
    .setRange(-height*4, height*4)
    .setGroup(particles_settings);

  cp5.addSlider("setting_particles_offset_z").setLabel("Z OFFSET")
    .setPosition(10, 235)
    .setRange(1000, 6000)
    .setNumberOfTickMarks(20)
    .setGroup(particles_settings);

  cp5.addToggle("setting_particles_particle_bloom_fx").setLabel("BLOOM FX")
    .setPosition(10, 260)
    .setSize(15, 15)
    .setGroup(particles_settings);

  cp5.addSlider("setting_point_cloud_blur").setLabel("BLUR")
    .setPosition(10, 10)
    .setRange(0, 10)
    .setNumberOfTickMarks(10)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_point_cloud_size").setLabel("POINT SIZE")
    .setPosition(10, 35)
    .setRange(1, 20)
    .setNumberOfTickMarks(20)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_min_fade_distance").setLabel("FADE MIN Z")
    .setPosition(10, 60)
    .setRange(100, 5000)
    .setNumberOfTickMarks(20)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_max_fade_distance").setLabel("FADE MAX Z")
    .setPosition(10, 85)
    .setRange(100, 5000)
    .setNumberOfTickMarks(20)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_particles_simplification").setLabel("SIMPLIFICATION")
    .setPosition(10, 110)
    .setRange(1, 10)
    .setNumberOfTickMarks(10)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_point_cloud_offset_x").setLabel("X OFFSET")
    .setPosition(10, 135)
    .setRange(-width*2, width*2)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_point_cloud_offset_y").setLabel("Y OFFSET")
    .setPosition(10, 160)
    .setRange(-height*2, height*2)
    .setGroup(point_cloud_settings);

  cp5.addSlider("setting_point_cloud_offset_z").setLabel("Z OFFSET")
    .setPosition(10, 185)
    .setRange(0, 2500)
    .setGroup(point_cloud_settings);

  Accordion accordion = cp5.addAccordion("settings_accourdion")
    .setPosition(40, 40)
    .setWidth(200)
    .addItem(mesh_settings)
    .addItem(particles_settings)
    .addItem(point_cloud_settings)
    .addItem(kinect_settings);

  cp5.loadProperties("settings/hisy.properties");
}

// Update
// ---------------------------------------------------------------------------------------------------------
void update() {

  if (frameCount % 30 == 0) {
     checkUserPresence();
  }
  
  if (frameCount % 5 == 0) {
    thread("updateKinect");
    updatePointsAndColors();
  }
 
  
    kinect_point_cloud.setPointSize(setting_point_cloud_size);
    kinect_point_cloud.setFadeMinMax(setting_min_fade_distance, setting_max_fade_distance);
    kinect_point_cloud.update(points, colors);

  if (true == isState(STATE_DRAW_POINTCLOUD)) {
    float[] boundingBox = { width, height }; 
  }

  if (true == userPresent()) {
    if (false == is_switching_state && (true == setting_create_meshes && true == isState(STATE_DRAW_POINTCLOUD))) {
      sent_awaiting_user = false;
      last_user_present = millis();
      if(false == sent_user_present){
        sendUserPresent();
      }
      exportMeshOnTimer();
    }
  } else {
    if(false == is_switching_state && true == isState(STATE_DRAW_POINTCLOUD)){
      sent_user_present = false;
          sendAwaitUserOnTimer(); 
    }
  }

  if (kinect.context.isTrackingSkeleton(user_id)) {
    user_present_label.setText("USER TRACKING");
  } else {
    user_present_label.setText("NO USER TRACKING");
  }
}

void sendUserPresent(){
    sendOpacityOSCSignal(USER_PRESENT_OPACITY_SIGNAL);
    sent_user_present = true;
    println("sendUserPresent::sendSignal");
}

void sendAwaitingUser(){
  sendOpacityOSCSignal(AWAITING_USER_OPACITY_SIGNAL);
  sent_awaiting_user = true;
}

void sendOpacityOSCSignal(float signal){
      OscMessage msg = new OscMessage("/layer2/video/opacity/values");
    msg.add(signal);
    oscP5.send(msg, max_patch);
}

// Export mesh on timer
// ---------------------------------------------------------------------------------------------------------
void exportMeshOnTimer() {
 

  if (userPresent() && false == is_switching_state) {

    if (millis() - mesh_save_timer > setting_mesh_save_interval * 200) {

      if (mesh_saved < setting_mesh_num_meshes) {

        if (mesh_saved == 0) {
          createNewExportDir();
        }

        thread("saveMesh");
        sendScanTrigger();

        mesh_save_timer = millis();
        mesh_saved++;
      } else {

        println("Meshes saved", mesh_export_path);

        mesh_user.load(mesh_export_path + "/body");
        kinect.context.stopTrackingSkeleton(user_id);
        switchState(STATE_DRAW_MESH);
      }
    }
  }
}

void sendAwaitUserOnTimer() {
  if (false == userPresent() && false == is_switching_state && false == sent_awaiting_user) {
    if (millis() - last_user_present > await_user_timer_interval * 1000) {
        sendAwaitingUser();
        println("sendAwaitUserOnTimer::sendSignal");
    }
  }
}

// Update points and colors (thread safe)
// ---------------------------------------------------------------------------------------------------------
void updatePointsAndColors() {  

  synchronized(kinect.points) {
    points = new ArrayList<PVector>(kinect.points);
  }

  synchronized(kinect.colors) {
    colors = new ArrayList(kinect.colors);
  }
}

// Update Kinect Thread
// ---------------------------------------------------------------------------------------------------------
void updateKinect() {
  kinect.setPointSimplification(setting_particles_simplification);
  kinect.setMaxDistance(setting_max_z);
  kinect.update();
}

// Draw
// ---------------------------------------------------------------------------------------------------------
void draw() {

  update();

  info();

  if (frameCount % 10 == 0) {
    sendPointsCount();
  }

  if (true == isState(STATE_DRAW_POINTCLOUD)) {

    background(0);

    hint(ENABLE_DEPTH_TEST);

    pushMatrix();
    blendMode(REPLACE);
    translate(
      setting_particles_offset_x, 
      setting_particles_offset_y, 
      -setting_particles_offset_z
      );
    scale(setting_particles_scale);
    popMatrix();
    if (is_switching_state == false) {
      pushMatrix();
      blendMode(BLEND);
      translate(setting_point_cloud_offset_x, setting_point_cloud_offset_y, setting_point_cloud_offset_z);
      kinect_point_cloud.draw();
      popMatrix();
    }

    blur.set("direction", float(setting_point_cloud_blur), 0.0f);
    filter(blur);
    blur.set("direction", 0.0f, float(setting_point_cloud_blur));
    filter(blur);

    if (is_switching_state == false) {
      pushMatrix();
      blendMode(BLEND);
      translate(setting_point_cloud_offset_x, setting_point_cloud_offset_y, setting_point_cloud_offset_z);
      kinect_point_cloud.draw();
      popMatrix();
    }
  }

  if (true == isState(STATE_DRAW_MESH)) {
    background(0);
    lights();
    mesh_user.draw();
  }

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
  
  spout.sendTexture();
}

// Draw gui
// ---------------------------------------------------------------------------------------------------------
void drawGui() {

  if (true == draw_controls) {
    cp5.draw();
  }
}

// Save mesh
// ---------------------------------------------------------------------------------------------------------
void saveMesh() {

  if (false == userPresent()) {
    return;
  }

  try {
    int[] body_mesh_pixels = kinect.getRGBImage(setting_mesh_simplification).pixels;

    ArrayList body_mesh_faces = kinect_mesh.createFaces(
      kinect.getMap3D(setting_mesh_simplification), 
      body_mesh_pixels, 
      kinect.getMap3DSize(), 
      setting_mesh_simplification
      );

    color[] body_mesh_colors = kinect_mesh.getColorsArray();
    renderer.setSmoothing(setting_mesh_smoothness);
    renderer.saveMesh(body_mesh_faces, body_mesh_colors, mesh_export_path + "/body");

    if (kinect.context.isTrackingSkeleton(user_id)) {

      int mesh_scale = 2;

      int[] tracker_mesh_pixels = kinect.getRGBImage(mesh_scale).pixels;
      PVector[] right_hand_points = kinect.getTrackerPoints(user_id, SimpleOpenNI.SKEL_RIGHT_HAND, mesh_scale, 200);
      PVector[] head_points = kinect.getTrackerPoints(user_id, SimpleOpenNI.SKEL_HEAD, mesh_scale, 200);

      if (null != right_hand_points) {
        ArrayList rh_mesh_faces = kinect_mesh.createFaces(
          right_hand_points, 
          tracker_mesh_pixels, 
          kinect.getMap3DSize(), 
          mesh_scale
          );
        color[] right_hand_mesh_colors = kinect_mesh.getColorsArray();
        renderer.setSmoothing(2);
        renderer.saveMesh(rh_mesh_faces, right_hand_mesh_colors, mesh_export_path + "/right_hand");
      }

      if (null != head_points) {
        ArrayList lh_mesh_faces = kinect_mesh.createFaces(
          head_points, 
          tracker_mesh_pixels, 
          kinect.getMap3DSize(), 
          mesh_scale
          );
        color[] head_mesh_colors = kinect_mesh.getColorsArray();
        renderer.setSmoothing(2);
        renderer.saveMesh(lh_mesh_faces, head_mesh_colors, mesh_export_path + "/head");
      }
    }
  } 
  catch(Exception e) {
  }
}

// Key events
// ---------------------------------------------------------------------------------------------------------
void keyPressed() {

  if ('s' == key) {
    cp5.saveProperties("settings/hisy.properties");
  }

  if ('m' == key) {
    draw_controls = !draw_controls;
  }
}

// Get for user presence
// ---------------------------------------------------------------------------------------------------------
boolean userPresent() {

  return user_present_close;
}

// Create new mesh export dir for user
// ---------------------------------------------------------------------------------------------------------
void createNewExportDir() {

  Date d = new Date();
  long timestamp = d.getTime() / 1000;
  mesh_export_path = sketchPath("exports") + "/" + Long.toString(timestamp);
  File dir = new File(mesh_export_path);
  dir.mkdir();
}

// Info debug
// -------------------------------------------------------------------------------------------------------
void info() {

  String txt_fps = String.format("%7.2f fps", frameRate);
  surface.setTitle(txt_fps);
}

//
// -------------------------------------------------------------------------------------------------------
void sendOSC() {

  sendParticlesCount();
  sendPointsCount();
}
//
// -------------------------------------------------------------------------------------------------------
void sendParticlesCount() {

  OscMessage msg = new OscMessage("/particles/count");
  //msg.add(kinect_particles.getCount());
  oscP5.send(msg, max_patch);
}

//
// -------------------------------------------------------------------------------------------------------
void sendPointsCount() {
    OscMessage msg = new OscMessage("/kinect/points/");
    msg.add(kinect.points.size());
    oscP5.send(msg, max_patch);
}

//
// -------------------------------------------------------------------------------------------------------
void sendScanTrigger() {

  OscMessage msg = new OscMessage("/mesh/create");
  msg.add(1);
  oscP5.send(msg, max_patch);
}

//
// -------------------------------------------------------------------------------------------------------
void sendPointCloudTrigger() {

  OscMessage msg = new OscMessage("/mesh/create");
  msg.add(0);
  oscP5.send(msg, max_patch);
}

//
// -------------------------------------------------------------------------------------------------------
void onNewUser(SimpleOpenNI curContext, int userId) {

  curContext.stopTrackingSkeleton(user_id);

  user_present = true;
  user_id = userId;

  curContext.startTrackingSkeleton(userId);
}

//
// -------------------------------------------------------------------------------------------------------
void onLostUser(SimpleOpenNI curContext, int userId) {

  user_present = false;
}

//
// -------------------------------------------------------------------------------------------------------
void onVisibleUser(SimpleOpenNI curContext, int userId) {
}

//
// -------------------------------------------------------------------------------------------------------
void checkUserPresence() {
    println(kinect.points.size());
    boolean is_present = (kinect.points.size() > 2000);
  
    if (is_present != user_present_close) {
      mesh_save_timer = millis();
      mesh_saved = 0;
    }
    user_present_close = is_present;
}
