// Kinect Mesh Class
// ---------------------------------------------------------------------------------------------------------
class KinectMesh {

  PApplet application;

  ArrayList faces = new ArrayList();
  ArrayList colors = new ArrayList();
  
  color[] colors_array;

  // Setup
  // -------------------------------------------------------------------------------------------------------
  void setup(PApplet app) {

    application = app;
  }

  // Create Faces
  // -------------------------------------------------------------------------------------------------------
  ArrayList createFaces(PVector[] points, int[] rgbPixels, PVector size, int scale) {
    
    faces.clear();
    colors.clear();
    
    int depth_width = int(size.x / scale);
    int depth_height = int(size.y / scale);
    
    float max_seperation = 999999;
    for (int y=0; y<depth_height-1; y+=1) {
      for (int x=0; x<depth_width-1; x+=1) {

        int index = x + y * depth_width;

        if ((points[index].z > 0) && ((points[index+1].z > 0) && (points[index+depth_width].z > 0))) {

          PVector p1 = points[index];
          PVector p2 = points[index + 1];
          PVector p3 = points[index + depth_width];

          if ((p1.dist(p2) < max_seperation) && (p1.dist(p3) < max_seperation) && (p2.dist(p3) < max_seperation)) {

            WB_Point hp1 = new WB_Point(p1.x, p1.y, p1.z);
            WB_Point hp2 = new WB_Point(p2.x, p2.y, p2.z);
            WB_Point hp3 = new WB_Point(p3.x, p3.y, p3.z);

            faces.add(new WB_Triangle(hp1, hp2, hp3));
            colors.add((color) rgbPixels[index]);
          }
        }

        if ((points[index+1].z > 0) && ((points[index+1+depth_width].z > 0) && (points[index+depth_width].z > 0))) {

          PVector p1 = points[index + 1];
          PVector p2 = points[index + 1 + depth_width];
          PVector p3 = points[index + depth_width];

          if ((p1.dist(p2) < max_seperation) && (p1.dist(p3) < max_seperation) && (p2.dist(p3) < max_seperation)) {

            WB_Point hp1 = new WB_Point(p1.x, p1.y, p1.z);
            WB_Point hp2 = new WB_Point(p2.x, p2.y, p2.z);
            WB_Point hp3 = new WB_Point(p3.x, p3.y, p3.z);

            faces.add(new WB_Triangle(hp1, hp2, hp3));
            colors.add((color) rgbPixels[index]);
          }
        }
      }
    }
    return faces;
  }

  // Get Faces
  // -------------------------------------------------------------------------------------------------------
  ArrayList getFaces() {

    return faces;
  }
  
  // Get Colors
  // -------------------------------------------------------------------------------------------------------
  ArrayList getColors() {
    
    return colors;
  }
  
  // Get Colors Array
  // -------------------------------------------------------------------------------------------------------
  color[] getColorsArray() {
    
    colors_array = new color[colors.size()];
    Iterator iter = colors.iterator();
    for (int i = 0; iter.hasNext(); i++) {
      colors_array[i] = (color)(Integer) iter.next();
    }
    
    return colors_array;
  }
}