class UserMeshes {

  PApplet application;
  WB_Render render;
  HE_MeshCollection scene;
  Ani ani_x, ani_y, ani_z, ani_translate_y;
  float ani_x_val = 5;
  float ani_y_val = 0;
  float ani_z_val = 0;
  float ani_translate_y_val = 0;

  int timer = 0;

  UserMeshes(PApplet app) {

    application = app;
    scene = new HE_MeshCollection();
    render = new WB_Render(application);
  }

  void load(String path) {
    println(path);
    scene = new HE_MeshCollection();
    File[] files = listFiles(path);
    for (int i=0; i<files.length; i++) {

      File f = files[i];
      String ext = getFileExtension(f);
      String file_name = getFileName(f);

      if ("obj".equals(ext)) {

        HEC_FromOBJFile creator = new HEC_FromOBJFile(path + "/" + f.getName());

        try {
          HE_Mesh mesh = new HE_Mesh(creator);

          byte[] colors_bytes = loadBytes(path + "/" + file_name + ".colors");

          ByteArrayInputStream colors_buffer = new ByteArrayInputStream(colors_bytes);
          DataInputStream colors_stream = new DataInputStream(colors_buffer);

          float[] colors = new float[colors_bytes.length / 4];
          for (int ci= 0; ci<colors.length; ci++) {
            try {
              colors[ci] = colors_stream.readFloat();
            } 
            catch(IOException e) {
              println(e);
            }
          }

          HE_FaceIterator fitr = mesh.fItr();
          int color_idx = 0;
          while (fitr.hasNext()) {
            fitr.next().setColor(color((int)colors[color_idx]));
            color_idx++;
          }
  
          println("adding "+ mesh+ "to scene");
          scene.add(mesh);
        } 
        catch (Exception e) {
          println(e);
        }
      }
    }

    scene.update();

    ani_x_val = -10;
    ani_x = Ani.to(this, 15, "ani_x_val", ani_x_val, Ani.SINE_IN_OUT);
    ani_x.setPlayMode(Ani.YOYO);
    ani_x.repeat();

    ani_y_val = -2;
    ani_y = Ani.to(this, 40, "ani_y_val", 13, Ani.SINE_IN_OUT);

    ani_z_val = 500;
    ani_z = Ani.to(this, 40, "ani_z_val", 2200, Ani.SINE_IN_OUT);

    ani_translate_y_val = 200;
    ani_translate_y = Ani.to(this, 30, "ani_translate_y_val", 500, Ani.SINE_IN_OUT);

    timer = millis();
  }

  String getFileName(File file) {

    String fileName = file.getName();
    int pos = fileName.lastIndexOf(".");
    if (pos > 0 && pos < (fileName.length() - 1)) { // If '.' is not the first or last character.
      fileName = fileName.substring(0, pos);
    }

    return fileName;
  }

  String getFileExtension(File file) {

    String name = file.getName();
    try {
      return name.substring(name.lastIndexOf(".") + 1);
    } 
    catch (Exception e) {
      return "";
    }
  }

  File[] listFiles(String dir) {

    File file = new File(dir);
    if (file.isDirectory()) {
      File[] files = file.listFiles();
      return files;
    } else {
      // If it's not a directory
      return null;
    }
  }
  
  void draw() {

    noStroke();
    fill(0);

    int idx = 0;
    HE_MeshIterator mitr = scene.mItr();

    while (mitr.hasNext()) {

      pushMatrix();
      translate(200, (height / 2) + ani_translate_y_val, ani_z_val);
      //rotateX(radians(180));
      rotateX(radians(180 + ani_x_val));
      rotateY(radians(ani_y_val));
      pushMatrix();

      translate((idx * (width/3)), (idx * 50), (idx * 30));
      HE_Mesh m = mitr.next();
      HE_Face[] f = m.getFacesAsArray();

      for (int i=0; i<f.length; i++) {
        color c = f[i].getColor();
        fill(c);
        render.drawFace(f[i]);
      }

      popMatrix();
      popMatrix();
      idx++;
    }
    
    if (millis() - timer > 15000 && false == is_switching_state) {

      mesh_save_timer = millis();
      mesh_saved = 0;

      sendPointCloudTrigger();
      switchState(STATE_DRAW_POINTCLOUD);
    }
  }
}
