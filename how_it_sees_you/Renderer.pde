class Renderer {
 
  int scene_smoothing = 0;
  
  // Save mesh
  // -------------------------------------------------------------------------------------------------------
  void saveMesh(ArrayList faces, color[] colors, String dir) {
    
    HEC_FromTriangles creator = new HEC_FromTriangles();
    creator.setTriangles(new ArrayList(faces));
    
    HE_Mesh mesh = new HE_Mesh(creator);
   
    HE_FaceIterator fitr = mesh.fItr();
    int color_idx = 0;
    while (fitr.hasNext()) {
      fitr.next().setColor(colors[color_idx]);
      color_idx++;
    }
   
    //mesh.uncapBoundaryHalfedges();
    //mesh.modify(new HEM_CapHoles());
    
    //HEM_Clean clean = new HEM_Clean();
    //mesh.modify(clean);
    
    HEM_TaubinSmooth smooth = new HEM_TaubinSmooth().setIterations(scene_smoothing);
    mesh.modify(smooth);
    
    Date d = new Date();
    long timestamp = d.getTime() / 1000;
    String filename = Long.toString(timestamp);
    HET_Export.saveToOBJ(mesh, dir, filename);
    
    saveColors(mesh.getFaceColors(), dir, filename);
  }
  
  // Save Colors
  // -------------------------------------------------------------------------------------------------------
  void saveColors(int[] colors, String dir, String filename) {
    
    ByteArrayOutputStream bas = new ByteArrayOutputStream();
    DataOutputStream ds = new DataOutputStream(bas);
  
    for (int i=0; i<colors.length; i++) {
      try {
        color c = (color)colors[i];
        ds.writeFloat(c);
      } 
      catch(IOException e) {
        println("could not write float to byte array", e);
      }
    }

  
    byte[] bytes = bas.toByteArray();
    saveBytes(dir + "/" + filename + ".colors", bytes);
  }
  
  // Set smoothing
  // -------------------------------------------------------------------------------------------------------
  void setSmoothing(int smoothing) {
    
    scene_smoothing = smoothing;
  }

  
  // Draw Mesh
  // -------------------------------------------------------------------------------------------------------
  /*
  void draw() {
    
    noStroke();
    fill(255);
    HE_MeshIterator mitr = scene.mItr();
    while (mitr.hasNext()) {
      render.drawFaces(mitr.next());
    } 
  }*/
}