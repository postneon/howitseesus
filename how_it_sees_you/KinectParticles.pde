//// Kinect Particles Class
//// ---------------------------------------------------------------------------------------------------------
class KinectParticles {

  PApplet application;

  PGraphics2D pg_canvas;
  PGraphics2D pg_obstacles;
  PGraphics2D pg_luminance;
  
  float r = 0;
  float g = 0;
  float b = 0;
  float a = 0;

  boolean setting_update_physics = true;
  boolean setting_apply_bloom = true;
  int[] setting_background = {0, 0, 0, 0};
  int[] setting_foreground = {0, 0, 0, 0};
  int[] setting_foreground_attractors = {10, 10, 10, 50};
  int setting_max_particles = 80000;
  int setting_particle_size = 3;
  int setting_scale = 25;

  float mul_attractors = 5f;
  
  int screen_w = 0;
  int screen_h = 0;

  // Constructor
  // -------------------------------------------------------------------------------------------------------
  KinectParticles(PApplet app) {

    application = app;
    setup(width / 2, height / 2);
  }

  // Setup
  // -------------------------------------------------------------------------------------------------------
  void setup(int w, int h) {
    
    screen_w = w;
    screen_h = h;
  }
}