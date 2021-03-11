// Kinect Point Cloud Class
// ---------------------------------------------------------------------------------------------------------
class KinectPointCloud {

  // OpenGL
  // ---------------------------------------------------------------------------------------------------------
  PShader points_sh;
  int points_vertex_vbo_id;
  int points_color_vbo_id;
  int points_vert_loc;
  int points_color_loc;

  // Points and color buffers
  // ---------------------------------------------------------------------------------------------------------
  float[] float_points;
  FloatBuffer float_buffer_points;

  float[] float_colors;
  FloatBuffer float_buffer_colors;

  // App
  // ---------------------------------------------------------------------------------------------------------
  PApplet application;
  
  // 
  // ---------------------------------------------------------------------------------------------------------
  int setting_point_cloud_size = 5;
  int setting_min_fade_distance = 200;
  int setting_max_fade_distance = 2000;

  // Constructor
  // ---------------------------------------------------------------------------------------------------------
  KinectPointCloud(PApplet app) {
    
    application = app;
    setup();
  }
  
  // Setup
  // ---------------------------------------------------------------------------------------------------------
  void setup() {

    points_sh = loadShader("points_frag.glsl", "points_vert.glsl");

    // Create VBO
    PGL pgl = g.beginPGL(); 

    // Allocate buffer big enough to get all VBO ids back
    IntBuffer int_buffer = IntBuffer.allocate(2);
    pgl.genBuffers(2, int_buffer);
    
    // Memory location of the VBO
    points_vertex_vbo_id = int_buffer.get(0);
    points_color_vbo_id = int_buffer.get(1);
    g.endPGL();
  }
  
  // Update
  // ---------------------------------------------------------------------------------------------------------
  void update(ArrayList<PVector> points, ArrayList colors) {

    if (points.size() > 0) {

      float_points = new float[points.size() * 3];
      Iterator<PVector> iterator = points.iterator(); 

      int point_index = 0;

      while (iterator.hasNext()) {

        PVector p = iterator.next().copy();
        float x = map(p.x, -width/2, width/2, 0, width);
        float y = map(p.y, height/2, -height/2, 0, height);

        float_points[point_index] = x; 
        point_index++;
        float_points[point_index] = y; 
        point_index++;
        float_points[point_index] = -p.z; 
        point_index++;
      }
    } else {
      float_points = null;
    }

    if (colors.size() > 0) {

      float_colors = new float[colors.size() * 3];
      int color_index = 0;

      for (int i=0; i<colors.size(); i++) {

        color c = int((float)colors.get(i));

        float_colors[color_index] = (c >> 16 & 0xFF) / 255.0f;
        color_index++;
        float_colors[color_index] = (c >> 8 & 0xFF) / 255.0f;
        color_index++;
        float_colors[color_index] = (c & 0xFF) / 255.0f;
        color_index++;
      }
    } else {
      float_colors = null;
    }
  }
  
  // Draw
  // ---------------------------------------------------------------------------------------------------------
  void draw() {

    if (points.size() == 0) {
      return;
    }

    points_sh.set("pointSize", float(setting_point_cloud_size));
    points_sh.set("maxDistance", float(setting_max_fade_distance));
    points_sh.set("minDistance", float(setting_min_fade_distance));

    float_buffer_points = Buffers.newDirectFloatBuffer(float_points.length);
    float_buffer_colors = Buffers.newDirectFloatBuffer(float_colors.length);

    PGL points_pgl = g.beginPGL();
    GL3 gl = ((PJOGL)beginPGL()).gl.getGL3();
    points_sh.bind();
 
    // Send the the vertex positions (point cloud) and color down the render pipeline
    // positions are rendered in the vertex shader, and color in the fragment shader
    points_vert_loc = points_pgl.getAttribLocation(points_sh.glProgram, "vertex");
    points_pgl.enableVertexAttribArray(points_vert_loc);
    gl.glPointSize(setting_point_cloud_size);
    // Enable drawing to the vertex and color buffer
    points_color_loc = points_pgl.getAttribLocation(points_sh.glProgram, "color");
    points_pgl.enableVertexAttribArray(points_color_loc);

    int vert_data_points = float_points.length / 3;
    int vert_data_colors = float_points.length / 3;

    float_buffer_points.put(float_points, 0, float_points.length);
    float_buffer_points.rewind();

    float_buffer_colors.put(float_colors, 0, float_colors.length);
    float_buffer_colors.rewind();

    {
      points_pgl.bindBuffer(PGL.ARRAY_BUFFER, points_vertex_vbo_id);
      // Fill VBO with data
      points_pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vert_data_points * 3, float_buffer_points, PGL.DYNAMIC_DRAW);
      // Associate currently bound VBO with shader attribute
      points_pgl.vertexAttribPointer(points_vert_loc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);
    }

    {
      points_pgl.bindBuffer(PGL.ARRAY_BUFFER, points_color_vbo_id);
      // Fill VBO with data
      points_pgl.bufferData(PGL.ARRAY_BUFFER, Integer.BYTES * vert_data_colors * 3, float_buffer_colors, PGL.DYNAMIC_DRAW);
      // Associate currently bound VBO with shader attribute
      points_pgl.vertexAttribPointer(points_color_loc, 4, PGL.FLOAT, false, Float.BYTES * 3, 0);
    }

    // Unbind VBOs
    points_pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

    // Draw the point cloud as a set of points
    points_pgl.drawArrays(PGL.POINTS, 0, vert_data_points);

    // Disable drawing
    points_pgl.disableVertexAttribArray(points_vertex_vbo_id);
    points_pgl.disableVertexAttribArray(points_color_vbo_id);

    points_sh.unbind();
    g.endPGL();
  }
  
  // Set point size
  // ---------------------------------------------------------------------------------------------------------
  void setPointSize(int pointSize) {
    
    setting_point_cloud_size = pointSize;
  }
  
  // Set min/max fade distance
  // ---------------------------------------------------------------------------------------------------------
  void setFadeMinMax(int minFadeZ, int maxFadeZ) {
   
    setting_min_fade_distance = minFadeZ;
    setting_max_fade_distance = maxFadeZ;
  }
}