import processing.opengl.*;

import toxi.physics2d.constraints.*;
import toxi.physics.*;
import toxi.physics.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;

static final int LAYERS = 7;
VerletPhysics2D[] physicsLayers;
int[] layerColors;

ArrayList<InterlayerConnector> connectors;

VerletParticle2D selected = null;

float stackSpacing = 102;

float zoom = 1;
float zoomTarget = 1;

float angle = 0.5;
float spin = 1;
boolean animateSpacing = false;
boolean animateAngle = true;
float zCenter = 0;

boolean saveFrames = false;

boolean sideways = false;
void setup() {
  //size(16*60,9*60);
  if(sideways) size(screen.width, 600);
  else {
    //size(400, screen.height-1);
    size(800,1080, OPENGL);
  }
  smooth();
  
  physicsLayers = new VerletPhysics2D[LAYERS];
  layerColors = new int[LAYERS];
  connectors = new ArrayList<InterlayerConnector>();
  colorMode(HSB);
  generateLayers();
}


void draw() {
  background(0);
  
  // Update
  // =================================================================
  zoom += (zoomTarget-zoom)*0.5;
  
  if(animateSpacing) stackSpacing = 75*(sin(frameCount/30.)+1);
  if(animateAngle) angle = 0.5 + cos(frameCount/60.)*0.49;
  stackSpacing = 50 * angle + 100;
  
  for(int i=0; i<physicsLayers.length; i++)
    physicsLayers[i].update();
  
  // Draw
  // =================================================================
  translate(width/2, height/2);
  if(sideways) rotate(radians(90));
  scale(zoom);
  translate(0,zCenter);
  
  //rotate(radians(frameCount*spin));
  
  // Draw node connections
  stroke(0,0,100);
  strokeWeight(0.5);
  for(Iterator i = connectors.iterator(); i.hasNext();) {
    InterlayerConnector con = (InterlayerConnector)i.next();
    Vec2D a = getIsoCoord(con.topLayer, physicsLayers[con.topLayer].particles.get(con.topNodeIndex));
    Vec2D b = getIsoCoord(con.topLayer-1, physicsLayers[con.topLayer-1].particles.get(con.bottomNodeIndex));
    
    line(a.x, a.y, b.x, b.y);
  }

  /*
  // Trace a path or something
  stroke(0,255,255);
  strokeWeight(1);
  InterlayerConnector con = connectors.get(0);
  Vec2D a = getIsoCoord(con.topLayer, physicsLayers[con.topLayer].particles.get(con.topNodeIndex));
  Vec2D b = getIsoCoord(con.topLayer-1, physicsLayers[con.topLayer-1].particles.get(con.bottomNodeIndex));  
  float k = frameCount%10/10.;
  line(a.x, a.y, b.x+(a.x-b.x)*k, b.y+(a.y-b.y)*k);
  */
  
  for(int l=0; l<physicsLayers.length; l++) {
    pushMatrix();
    translate((l-(int)(physicsLayers.length/2))*0,-(l-(int)(physicsLayers.length/2))*stackSpacing);
    // Pseudo-Isometric Transform
    scale(1,angle);
    rotate(radians(45));
    rotate(radians(frameCount*spin));
    
    // Draw grid
    stroke(0,0,200,128);
    strokeWeight(0.5);
    int gridInterval = 10;
    int gridSpaces = 10;
    for(int i=-gridSpaces; i<=gridSpaces; i++) {
      line(-gridInterval*gridSpaces,i*gridInterval, gridInterval*gridSpaces,i*gridInterval);
      line(i*gridInterval,-gridInterval*gridSpaces, i*gridInterval,gridInterval*gridSpaces);
    }
    
    // Draw springs
    strokeWeight(2);
    float alpha;
    //color c = layerColors.get(l);
    int hue = (int)map(l, 0, physicsLayers.length, 0, 255);
    colorMode(HSB);
    for(Iterator i = physicsLayers[l].springs.iterator(); i.hasNext();) {
      VerletSpring2D s = (VerletSpring2D)i.next();
      
      //stroke(hue(c), 255, brightness(c), constrain((1-s.a.distanceTo(s.b)/50.),0,1)*200+55);
      //stroke(layerColors.get(l), 200, 255, constrain((1-s.a.distanceTo(s.b)/50.),0,1)*200+55);
      stroke(hue, 255, 255, constrain((1-s.a.distanceTo(s.b)/50.),0,1)*200+55);
      line(s.a.x,s.a.y, s.b.x,s.b.y);
    }
    
    
    // Draw nodes
    noStroke();
    //fill(0,128,255);
    for(Iterator i = physicsLayers[l].particles.iterator(); i.hasNext();) {
      VerletParticle2D p = (VerletParticle2D)i.next();
      fill(0);
      ellipse(p.x, p.y, 5,5);
      //fill(layerColors.get(l), 50, 255);
      fill(hue, 50, 255);
      ellipse(p.x, p.y, 4,4);
    }
    popMatrix();
  }    
  
  if(saveFrames) saveFrame("frame-####.png");
}

void generateNetwork(VerletPhysics2D physics, int type, int n, Vec2D center) {
  VerletParticle2D p;
  
  switch(type) {
    case 0:
    case 3:
      p = new VerletParticle2D(center);
      //if(physics.particles.size() == 0) p.lock();
      physics.addParticle(p);
      addBranch(physics, p, n, type == 0 ? 0.1 : 0.6);
      break;
    case 1:
    case 2:
      // Start with an evenly spaced ring of particles
      int multiplier = type == 1 ? 3 : 6;
      for(int i=0; i<n; i++) {
        p = new VerletParticle2D(new Vec2D(center.x + n*multiplier*cos(i/float(n)*TWO_PI), center.y + n*multiplier*sin(i/float(n)*TWO_PI)));
        physics.addParticle(p);
        physics.addBehavior(new AttractionBehavior(p, 60, -10.2f));
      }
      
      for(int i=0; i<n; i++) {
        // Link the ring with springs
        VerletParticle2D p1 = physics.particles.get(i);
        VerletParticle2D other;
        if(i < n-1) other = physics.particles.get(i+1);
        else other = physics.particles.get(0);
        //float relaxedLength = type == 1 ? p1.distanceTo(other) : p1.distanceTo(other) * 0.5;
        float relaxedLength = p1.distanceTo(other);
        VerletSpring2D s = new VerletSpring2D(p1, other, relaxedLength, 0.1);
        physics.addSpring(s);
        
        for(int j=0; j<n; j++) {
          if(random(0,1) < (type == 1 ? 0.05 : 0.2)) {  // Type 2 has a 10x greater chance of cross-linking
            VerletParticle2D p2 = physics.particles.get(j);

            s = new VerletSpring2D(p1, p2, p1.distanceTo(p2)*0.5, 0.1);
            physics.addSpring(s);
          }
        }
      }      
      break;
  }
}

int addBranch(VerletPhysics2D physics, VerletParticle2D parent, int n_left, float crossLinkChance) {
  if(n_left <= 0) return 0;
  int newParticles = 0;
  
  int branches = (int)random(1,n_left);
  branches = 2;
  
  while(n_left > 0) {
    VerletParticle2D p = new VerletParticle2D(parent.x+random(-20,20),
                                              parent.y+random(-20,20));   
    physics.addParticle(p);                              
    n_left--;                                              
    //int _new = addBranch(physics, p, (int)random(0,n_left));
    int _new = addBranch(physics, p, n_left/(int)random(1,8), crossLinkChance);
    newParticles += _new + 1;
    n_left -= _new;
    
    VerletSpring2D spring = new VerletSpring2D(p, parent, p.distanceTo(parent), .1);
    //VerletSpring2D spring = new VerletSpring2D(p, parent, 10, .1);
    physics.addSpring(spring);
    
    // Randomly cross-link with another particle in the tree
    if(random(0,1) < crossLinkChance) { 
      VerletParticle2D p2 = randomParticle(physics);
      VerletSpring2D spring2 = new VerletSpring2D(p, p2, p.distanceTo(p2)/2, .1);
      physics.addSpring(spring2);
    }
    physics.addBehavior(new AttractionBehavior(p, 60, -10.2f));
  }
  
  return newParticles;
}

Vec2D getIsoCoord(int layer, Vec2D _p) {
    //return _p.add(0,-(layer-(int)(physicsLayers.size()/2))*stackSpacing).scale(1,0.5).rotate(radians(45)).rotate(radians(frameCount*spin));    
    Vec2D p = _p.copy();
    return p.rotate(radians(frameCount*spin)).rotate(radians(45)).scale(1,angle).add(0,-(layer-(int)(physicsLayers.length/2))*stackSpacing);    
}

VerletParticle2D randomParticle(VerletPhysics2D physics) {
  return physics.particles.get((int)random(0,physics.particles.size()));  
}

void generateLayers() {
  for(int i=0; i<physicsLayers.length; i++) {
    int type = (int)random(0,4);
    physicsLayers[i] = new VerletPhysics2D();
    physicsLayers[i].setDrag(0.2);
    int n = (int)(type == 0  || type == 3 ? random(20,200) : type == 1 ? random(20,70) : type == 2 ? random(10,30) : 1);
    generateNetwork(physicsLayers[i], type, n, new Vec2D(0,0));  
    if(type == 0 || type == 3) physicsLayers[i].particles.get(0).lock();
  }
  
  connectors.clear();
  
  // Generate some connections between each layer
  for(int i=1; i<physicsLayers.length; i++) {  // Start at the second layer from the bottom, connect down
    for(int j=0; j<physicsLayers[i].particles.size(); j++) {
      if(random(0,1) < 0.3) {
        connectors.add(new InterlayerConnector(i, j, (int)random(0,physicsLayers[i-1].particles.size())));
      }  
    }
  }
}

void keyPressed() {
  if(key == 'a') zoomTarget *= 1.1;
  if(key == 'z') zoomTarget /= 1.1;
  if(key == ' ') {
    generateLayers();
  }
  if(key == 's') saveFrames = !saveFrames;
}

void mouseDragged() {
  if(mouseButton == RIGHT) {
    stackSpacing += (mouseY-pmouseY)/zoom; 
  }
  if(mouseButton == LEFT)
    zCenter += (mouseY-pmouseY)/zoom;
}

void mouseClicked() {
  //generateNetwork(physicsLayers[0], 0, (int)random(10,200), new Vec2D((mouseX-width/2)/zoom, (mouseY-height/2)/zoom));  
}
