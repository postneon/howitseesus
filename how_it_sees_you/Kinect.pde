// Kinect Class
// ---------------------------------------------------------------------------------------------------------
class Kinect {

  List<PVector> points = Collections.synchronizedList(new ArrayList<PVector>());
  List<Float> colors = Collections.synchronizedList(new ArrayList<Float>());
  
  int setting_max_distance_z = 1000;
  int setting_points_simplification = 1;

  PApplet application;
  SimpleOpenNI context;

  // Constructor
  // ---------------------------------------------------------------------------------------------------------
  Kinect(PApplet app) {

    application = app;
    setupKinect();
  }

  // Update
  // ---------------------------------------------------------------------------------------------------------
  void update() {
    context.update();
    readPoints();
  }

  // Setup Kinect
  // ---------------------------------------------------------------------------------------------------------
  void setupKinect() {

    int kinect_count = SimpleOpenNI.deviceCount();

    if (0 == kinect_count) {
      println("No Kinects found.");
      exit();
      return;
    }

    context = new SimpleOpenNI(application, SimpleOpenNI.RUN_MODE_SINGLE_THREADED);

    if (false == context.isInit()) {
      println("Can't init SimpleOpenNI, maybe the camera is not connected!");
      exit();
      return;
    }

    context.setMirror(false);
    context.enableDepth();
    context.enableRGB();
    context.enableUser();
    context.enableHand();

    context.alternativeViewPointDepthToImage();
    context.setDepthColorSyncEnabled(true);
  }

  // Resize 3D map
  // -------------------------------------------------------------------------------------------------------
  PVector[] resizeMap3D(PVector[] map3D, int n) {

    int x_size_org = context.depthWidth();
    int y_size_org = context.depthHeight();

    int x_size = x_size_org / n;
    int y_size = y_size_org / n;

    PVector[] resized_map_3d = new PVector[x_size * y_size];

    for (int y=0; y<y_size; y++) {
      for (int x=0; x<x_size; x++) {
        resized_map_3d[x + y * x_size] = map3D[x * n + y * n * x_size_org];
      }
    }
    return resized_map_3d;
  }

  // Resize RGB
  // -------------------------------------------------------------------------------------------------------
  PImage resizeRGB(PImage rgbImg, int n) {

    int x_size_org = context.depthWidth();
    int y_size_org = context.depthHeight();

    int x_size = x_size_org / n;
    int y_size = y_size_org / n;

    PImage resized_rgb = createImage(x_size, y_size, RGB);

    for (int y=0; y<y_size; y++) {
      for (int x=0; x<x_size; x++) {
        resized_rgb.pixels[x + y * x_size] = rgbImg.pixels[x * n + y * n * x_size_org];
      }
    }
    return resized_rgb;
  }

  // Read points
  // ---------------------------------------------------------------------------------------------------------
  void readPoints() {

    PVector[] map_3d = resizeMap3D(context.depthMapRealWorld(), setting_points_simplification);
    PImage rgb = resizeRGB(context.rgbImage(), setting_points_simplification);

    int w = context.depthWidth() / setting_points_simplification;
    int h = context.depthHeight() / setting_points_simplification;
    
    points.clear();
    colors.clear();

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        int index = x + y * w;
        if (map_3d[index].z < setting_max_distance_z && map_3d[index].z > 100) {
          points.add(map_3d[index].copy());
          color p_color = (color) rgb.pixels[index];
          colors.add((float)p_color);
        }
      }
    }
    
    kinectUpdated = true;
  }

  // Get 3D map
  // ---------------------------------------------------------------------------------------------------------
  PVector[] getMap3D(int scale) {

    PVector[] map_3d = resizeMap3D(context.depthMapRealWorld(), scale);

    int w = context.depthWidth() / scale;
    int h = context.depthHeight() / scale;

    PVector[] map_3d_dist = new PVector[map_3d.length];

    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        int index = x + y * w;
        if (map_3d[index].z < setting_max_distance_z && map_3d[index].z > 100) {
          map_3d_dist[index] = map_3d[index].copy();
        } else {
          map_3d_dist[index] = new PVector(0, 0, 0);
        }
      }
    }

    return map_3d_dist;
  }

  // Get RGB image
  // ---------------------------------------------------------------------------------------------------------
  PImage getRGBImage(int scale) {

    return resizeRGB(context.rgbImage(), scale);
  }

  // Get Depth image
  // ---------------------------------------------------------------------------------------------------------
  PImage getDepthImage() {

    return context.depthImage();
  }

  // Get 3D map dims
  // ---------------------------------------------------------------------------------------------------------
  PVector getMap3DSize() {

    int w = context.depthWidth();
    int h = context.depthHeight();

    return new PVector(w, h);
  }

  // Set max distance
  // ---------------------------------------------------------------------------------------------------------
  void setMaxDistance(int maxDistance) {

    setting_max_distance_z = maxDistance;
  }

  // Set point cloud simplification
  // ---------------------------------------------------------------------------------------------------------
  void setPointSimplification(int scale) {

    setting_points_simplification = scale;
  }

  PVector getTrackerPos(int userId, int pos) {
    
    PVector lh_pos = new PVector();
    float confidence = context.getJointPositionSkeleton(userId, pos, lh_pos); 
    if (confidence == 0) {
      lh_pos = null;
    }
    
    return lh_pos;
  }

  PVector[] getTrackerPoints(int userId, int pos, int scale, int dist) {
    
    PVector lhp = getTrackerPos(userId, pos);
    PVector[] map_3d = resizeMap3D(context.depthMapRealWorld(), scale);

    int w = context.depthWidth() / scale;
    int h = context.depthHeight() / scale;
    
    PVector[] p = new PVector[w*h];
    
    if (null == lhp) {
      p = null;
      return p; 
    }
    
    boolean has_points = false;
    for (int y=0; y<h; y++) {
      for (int x=0; x<w; x++) {
        int index = x + y * w;
        if (map_3d[index].z < setting_max_distance_z && map_3d[index].z > 100) {
          if (map_3d[index].dist(lhp) < dist) {
            has_points = true;
            p[index] = map_3d[index].copy();

          } else {
            p[index] = new PVector(0, 0, 0);
          }
        } else {
          p[index] = new PVector(0, 0, 0);
        }
      }
    }
    
    if (false == has_points) {
      p = null;
    }
    return p;
  }
}