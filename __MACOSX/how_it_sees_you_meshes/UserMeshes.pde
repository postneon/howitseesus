class UserMeshes {

  PApplet application;
  WB_Render render;
  HE_MeshCollection scene;

  UserMeshes(PApplet app) {

    application = app;
    scene = new HE_MeshCollection();
    render = new WB_Render(application);
  }

  void load(ArrayList<String> files) {

    scene = new HE_MeshCollection();

    for (int i=0; i<files.size(); i++) {
      
      String file_path = files.get(i);

      try {
        HEC_FromOBJFile creator = new HEC_FromOBJFile(file_path+".obj");
        HE_Mesh mesh = new HE_Mesh(creator);

        byte[] colors_bytes = loadBytes(file_path + ".colors");

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
        scene.add(mesh);
      } 
      catch (Exception e) {
        println(e);
      }
    }

    scene.update();

    
  }

}