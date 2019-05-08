/*

URL de consulta los productos disponibles para picking:
http://rea.opensai.org/alistamientoQ?format=json&productos___picking_raw=1
Campos a consultar:
"productos___location_raw" -> ID almacenamiento en bodega
"productos___id"           -> ID de producto


En la anterior consulta, el ID de la posición de almacenamiento guarda en el campo "productos___location_raw", si dicho ID es 1, se consultaría 
a través del campo "storage_locations___id_raw" a que almacenamiento corresponde dicho ID:
http://rea.opensai.org/almacenamientoQ?format=json&storage_locations___id_raw=1
Campos a consultar:
"storage_locations___location_raw" -> ID del tag de ubicación en bodega (incluye coordenadas físicas y virtuales)


Revisando ese almacenamiento, el ID de la posición a la cual corresponde se guarda en la variable storage_locations___location_raw con ID 2, luego se consulta a que 
posicionamiento corresponde:
http://rea.opensai.org/posicionamientoQ?format=json&positioning_tags___id=2
Campos a consultar:
positioning_tags___physical_location_X:10.00
positioning_tags___physical_location_Y:1.00
positioning_tags___virtual_coordinate_X:1
positioning_tags___virtual_coordinate_Y:10

*/


import com.google.zxing.*;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import com.google.zxing.common.*;
import com.google.zxing.client.j2se.*;
import android.graphics.Bitmap;
import ketai.camera.*;

import ketai.ui.*;
import ketai.sensors.*;

import java.net.*;
import java.io.*;


/*

#######################################################

*/

//camera
KetaiCamera cam;
boolean globalHistogram = false;
com.google.zxing.Reader reader = new com.google.zxing.MultiFormatReader();
String queryCodeResult="0000000000";

//position sensors
KetaiSensor sensor;
PShape flecha,flechaObjetivo;
PImage texture, objetivo;
int textureX, textureY, textureSize;
PVector magneticField;
float azimuth;
float pitch;
float roll;

//INTERFAZ
//icons
PImage cartEmpty, cartFull, networkProblem;
float scale=0.3, rota, wareouseAngle=PI/3;
int step = 10;
float rotationX, rotationY, rotationZ, rX, rY, rZ, posX, posY, posZ;
PFont f;
String[] fontList;
PFont androidFont;
String direction = "";
boolean firstdraw = true;
float giro=1;
float desplazamientoX=0;
float proporcionAngular=0;
float azimuthRadianes=0;
//counter refresh JSON query
int loops=0, JSONqueryDelay=100, secondsBuffer=0;
//grilla ubicación TAGs en bodega anchoX, largoY
int stepWareHouseX=7, stepWareHouseY=5;
//coordenada Operario
float operarioX=0, operarioY=0;
int productosEspera=0;


/*  --------------------------------------------
APP states
FREE = No pedidos en espera
CALLING = Pedidos en espera
VIEW = Visualización de vista previa de producto
PICKING = Navegando para recoger producto
DONE = Producto encontrado
ERROR = Error de la aplicación
------------------------------------------------*/
String state;
boolean free=true, network=true, onPicking=false, drawNav=false;

//WEB SERVICE -----------------------------------
// url lectura productos alistamiento 
String PROTOCOL = "http" + "://";
String SITE = "rea.opensai.org"; 
String FOLD = "/alistamientoQ/" + '?'; 
String FORMAT = "format" + '=' + "json" + '&';
String QUERY = "productos___picking_raw" + '=' + '1';
String PATH = PROTOCOL + SITE + FOLD + FORMAT + QUERY;

//url escritura picking realizado, el ID del form es 1, se debe agregar al final el valor leido desde "productos___id_raw"
String FOLDW = "/productosq/details/1/"; 
String PATHW = PROTOCOL + SITE + FOLDW;
String pickingProductID;

//url consulta identificador de almacenamiento
String FOLD_STORAGE_ID = "/almacenamientoQ"+'?';
String QUERY_STORAGE_ID = "storage_locations___id_raw" + '=';
String PATH_STORAGE_ID = PROTOCOL + SITE + FOLD_STORAGE_ID + FORMAT + QUERY_STORAGE_ID;
String productStorageID;

//url consulta TAG de posicionamiento del almacenamiento del producto
String FOLD_TAG = "/posicionamientoQ"+'?';
String QUERY_TAG = "positioning_tags___id" + '='; //se agrega el valor "productStorageID" de la consulta previa
String PATH_TAG = PROTOCOL + SITE + FOLD_TAG + FORMAT + QUERY_TAG;
float physicalX, physicalY, virtualX, virtualY;

//url consulta DB TAG posicionamiento
String FOLD_DB_TAG = "/posicionamientoQ"+'?';
String QUERY_DB_TAG = "resetfilters"+'='+'0'+'&'+"clearordering"+'='+'0'+'&'+"clearfilters"+'='+'0';
String PATH_DB_TAG = PROTOCOL + SITE + FOLD_DB_TAG + FORMAT + QUERY_DB_TAG;

//DATOS DEL PRODUCTO -----------------------------
//array de lectura datos producto desde el servidor
JSONArray picking, product, productStorages, storage, productLocations, location, productTAGLocations, dbTAGLocation;
//imagen vista previa de producto para recoger
PImage pickingProductThumb;
//icono de producto encontrado
PImage ok;
//check url active...
String productThumbUrl;
//identificador de la unidad de almacenamiento en bodega asociada al producto
String producIdLocation, productNAMELocation;
//Serial del producto
String productSERIAL;
//Nombre del producto
String productName;

/*

#######################################################

*/
void settings() {
    fullScreen();
    //size(width,height, P3D);
    //size(width,height);
    
}

void setup() {  
    
  textAlign(CENTER, CENTER);
  textSize(28);
  
  cam = new KetaiCamera(this, 1024, 768, 30);
  
  state = "FREE";
    
  rX = 0;
  rY = 0;
  rZ = 0;
  textureX = 500;
  textureY = 500;
  textureSize = 500;
  posX =width/2;
  posY =height/2;
  posZ = (-1)*(height/2) / tan(PI/6);


  //configuraciones principales
  orientation(LANDSCAPE);
  imageMode(CENTER);
  //frameRate(25);
  //lights();

  //inicializa fuentes
  f = createFont("Arial",16,true);

  //inicializa sensores
  sensor = new KetaiSensor(this);
  sensor.start();
  sensor.list();
  magneticField = new PVector();

  //crea flecha indicación
  texture = loadImage("flecha.png");
  rectMode(CENTER);
  flecha = createShape(RECT,0, 0 , 100,100);
  flecha.setTexture(texture);

  //crea flecha objetivo
  objetivo = loadImage("objetivo.png");
  //rectMode(CENTER);
  flechaObjetivo = createShape(RECT,0, 0 , 100,100);
  flechaObjetivo.setTexture(objetivo);

  //iconos
  cartEmpty = loadImage("cart-empty.png");
  cartFull = loadImage("cart-full.png");
  networkProblem = loadImage("networkProblem.png");
  ok = loadImage("ok.png");


  //funciones de servicio
  thread("JSONloop");
  thread("checkNetwork");
  //thread("writePicking");
  thread("queryPickingProduct");
  thread("queryPicking");
  thread("queryProductStorage");
  thread("queryProductLocation");
  //thread("onCameraPreviewEvent");
  
  loadDBTAGLocation ();

}


void draw() {

  //limpia pantalla
  background(0);
  
  
  
  /*  --------------------------------------------
  APP states
  FREE = No pedidos en espera
  CALLING = Pedidos en espera
  VIEW = Visualización de vista previa de producto
  PICKING = Navegando para recoger producto
  DONE = Producto encontrado
  ERROR = Error de la aplicación
  ------------------------------------------------*/
  
  switch (state){
    case "FREE":
      JSONloop();    
      textFont(f,36);
      fill(0,255,0);
      image(cartEmpty, width/2, height/2);        
      text("No hay productos en espera...", (width/step)*5,(height/step)*7);        
    break;
    case "CALLING":
      JSONloop();    
      image(cartFull, width/2, height/2);
      textFont(f,36);
      fill(255,0,0);
      text("Productos en espera: "+ productosEspera, (width/step)*5,(height/step)*7);    
    break;
    case "VIEW":
      image(pickingProductThumb,width/2,height/2,200,200);
      textFont(f,36);
      fill(255,0,255);
      text(productName+"\n SERIAL: "+productSERIAL+"\n LOCALIZACIÓN: "+productNAMELocation+"\n", (width/step)*5,(height/step)*8);          
      print("STATE: "+ state);
    break;
    case "PICKING":    
      picking();      
    break;
    case "DONE":
      image(ok,width/2,height/2,200,200);
      textFont(f,36);
      fill(0,255,0);
      text("Producto encontrado! \n oprima botón principal \n para cargar el siguiente producto...", (width/step)*5,(height/step)*8);
      print("Producto encontrado, \n oprima ENTER para cargar el siguiente producto...");
    break;
    case "ERROR":
      JSONloop();
      image(networkProblem, width/2, height/2);      
    break;  
    default:
      print("ESTADO: "+ state);
    break;
  }

}


void onOrientationEvent(float x, float y, float z)
{
  magneticField.set(x, y, z);
  
  azimuth = x;
  pitch = y;
  roll = z;  
}


void keyPressed(){
  
  if(keyCode == 23){
   
    switch (state){
      case "FREE":
        print("No products to picking...");
      break;
      case "CALLING":
        state="VIEW";
        queryPickingProduct();        
      break;
      case "VIEW":
        if (!cam.isStarted()) cam.start();
        queryProductCoord();
        state="PICKING";                
      break;
      case "PICKING":
        if (cam.isStarted()) cam.stop();
        state = "FREE";
      break;
      case "DONE":
        if (cam.isStarted()) cam.stop();
        state = "FREE";      
      break;
      case "ERROR":
        print("Revise conectividad...");
      break;      
      default:
        print("keyCode: "+ keyCode);
        print("ESTADO: "+ state);
      break;
      
    }
  }

}



/*
Activa la consulta al servidor cada cierto intervalo
*/
void JSONloop(){
  if(loops < JSONqueryDelay){
    loops++;
    //print("loops: "+ loops);
  }else{
    loops=0;
    
    queryPicking();    
    print("Query picking...");
    print("Seconds from last query: " + (second()-secondsBuffer));
    print("STATE: "+state);
    secondsBuffer=second();
    
    return;
  }
 
 return;
}



/*
Consulta al servidor para ver si hay productos en alistamiento
*/
void queryPicking (){

  checkNetwork();  
  
  if(state!="ERROR"){
  
    picking = loadJSONArray(PATH);
    product = picking.getJSONArray(0);
  
    if (product.size()>0){
       //free=false;
       productosEspera=product.size();
       state="CALLING";       
     }else{
       //free=true;
       state="FREE";
    }
    print ("# picking products: " + product.size());  
  }else{
    print("Error in Products to picking JSON query...");
  }

}



/*
Cuando hay productos en alistamiento, consulta los datos el primero en espera
*/
void queryPickingProduct (){

  checkNetwork();  
  
  if(state!="ERROR"){
  
    picking = loadJSONArray(PATH);
    product = picking.getJSONArray(0);
  
    for (int i = 0; i < product.size(); i++) {
    
      JSONObject item = product.getJSONObject(i); 

      producIdLocation = item.getString("productos___location_raw");
      productNAMELocation = item.getString("productos___location");
      
      productThumbUrl = item.getString("productos___image_raw");
      pickingProductID = item.getString("productos___id_raw");
      productName = item.getString("productos___product");
      productSERIAL = item.getString("productos___serial");

      println("ID Location: " + producIdLocation);
      println("Thumb URL: " + productThumbUrl);
      print("STATE: "+state);
    }
  
    productThumbUrl = PROTOCOL + SITE + productThumbUrl;
    pickingProductThumb = loadImage(productThumbUrl);
    
    //onPicking=true;
  }else{  
    print("Error in Product Details JSON query...");
  }


}

/*
Del producto en espera seleccionado, consulta el ID del storage de almacenamiento
*/
void queryProductStorage (){

  checkNetwork();  
  
  if(state!="ERROR"){
  
    productStorages = loadJSONArray(PATH_STORAGE_ID+producIdLocation);
    storage = productStorages.getJSONArray(0);
  
    for (int i = 0; i < storage.size(); i++) {
    
      JSONObject item = storage.getJSONObject(i); 

      productStorageID = item.getString("storage_locations___location_raw");

      println("Product Storage ID: " + productStorageID);
      print("STATE: "+state);
    }
  
  }else{  
    print("Error in Storage ID JSON query...");
  }


}



/*
Del almacenamiento asociado al producto, consulta las coordenadas
*/
void queryProductLocation (){

  checkNetwork();  
  
  if(state!="ERROR"){
  
    productLocations = loadJSONArray(PATH_TAG+productStorageID);
    location = productLocations.getJSONArray(0);
  
    for (int i = 0; i < location.size(); i++) {
    
      JSONObject item = location.getJSONObject(i); 

      physicalX = item.getFloat("positioning_tags___physical_location_X_raw");
      physicalY = item.getFloat("positioning_tags___physical_location_Y_raw");
      virtualX = item.getFloat("positioning_tags___virtual_coordinate_X_raw");
      virtualY = item.getFloat("positioning_tags___virtual_coordinate_Y_raw");

      print("PhX: "+ physicalX);
      print("PhY: "+physicalY);
      print("VX: "+virtualX);
      print("VY: "+virtualY);
      print("STATE: "+state);
    }
  
  }else{  
    print("Error in Location JSON query...");
  }


}

/*
Del almacenamiento asociado al producto, consulta las coordenadas
*/
void loadDBTAGLocation (){

  checkNetwork();
  
  float Px,Py,Vx,Vy;
  
  if(state!="ERROR"){
  
    productTAGLocations = loadJSONArray(PATH_DB_TAG);
    dbTAGLocation = productTAGLocations.getJSONArray(0);
    print("TAG Location DB size: "+ dbTAGLocation.size());
    print("PATH_DB_TAG: "+ PATH_DB_TAG);
    
    for (int i = 0; i < dbTAGLocation.size(); i++) {
    
      JSONObject item = dbTAGLocation.getJSONObject(i); 

      Px = item.getFloat("positioning_tags___physical_location_X_raw");
      Py = item.getFloat("positioning_tags___physical_location_Y_raw");
      Vx = item.getFloat("positioning_tags___virtual_coordinate_X_raw");
      Vy = item.getFloat("positioning_tags___virtual_coordinate_Y_raw");

      print("#" + (i+1) + " PhX: "+ Px + "PhY: "+ Py + "Vx: "+ Vx + "Vy: "+ Vy);
    }
    print("STATE: "+state);
  
  }else{  
    print("Error in TAG Location JSON query...");
  }


}




/*
Consulta las coordenadas de un producto seleccionado
*/
void queryProductCoord(){

  print("Leer Storage ID...");
  queryProductStorage();
  print("Leer coordenadas de producto...");
  queryProductLocation();
  print("Product SERIAL: "+ productSERIAL);  

}



/*
Dibuja interfaz de navegación durante proceso de picking
*/
void picking(){
  
  //imprime cámara
  image(cam, width/2, height/2); 
  
  readCodes();
  drawVirtualSpace();
  drawWareHouse();
  drawNorth();
  print("Navegando, picking...");
  print("Norte: "+azimuth);
}



/*
Lee código desde la cámara
*/
void readCodes(){ 
  print("queryCodeResult: "+queryCodeResult);
  print("productSERIAL: "+productSERIAL);
  
  if(productSERIAL.equals(queryCodeResult)){
    print("Producto "+productName+" encontrado");
    writePicking();
    state="DONE";
  }else{
    print("Buscando TAG posición");
    if(!queryDBCodeTAG())
      print("Serial "+productSERIAL + " no leido..."+"Coordenada no encontrada en DB...");  
  }
}


/*
Valida si hay conectividad
*/
void checkNetwork(){  
 
  String[] urlCheckConn; 
  urlCheckConn = loadStrings(PROTOCOL+SITE);
  if (urlCheckConn[0]==null){

    state="ERROR";
    print ("Connection Problem!!");
  }else{

    print ("url active (size): "+urlCheckConn.length);
    print ("urlCheckConn: "+urlCheckConn[0]);
  }

}



/*
Al encontrar un producto en bodega, se lee código de barras y se reporta al servidor su alistamiento
*/
void writePicking(){  
 
  String[] urlCheckConn; 
  urlCheckConn = loadStrings(PATHW+pickingProductID);
  if (urlCheckConn[0]==null){
    
    state="ERROR";
    print ("Connection Problem!!");
  }else{

    print ("Picking Write!!!");
    print ("Update product in: "+urlCheckConn[0]);
    print(PATHW+pickingProductID);
  }
  

}



void populateYUVLuminanceFromRGB(int[] rgb, byte[] yuv420sp, int width, int height) {
  for (int i = 0; i < width * height; i++) {
    float red = (rgb[i] >> 16) & 0xff;
    float green = (rgb[i] >> 8) & 0xff;
    float blue = (rgb[i]) & 0xff;
    int luminance = (int) ((0.257f * red) + (0.504f * green) + (0.098f * blue) + 16);
    yuv420sp[i] = (byte) (0xff & luminance);
  }
}

void onCameraPreviewEvent()
{
  cam.read();
  queryCodeResult="0000000000";
  Bitmap camBitmap = (Bitmap) cam.getNative();
  int w = camBitmap.getWidth();
  int h = camBitmap.getHeight();
  int[] rgb = new int[w * h];
  byte[] yuv = new byte[w * h];

  camBitmap.getPixels(rgb, 0, w, 0, 0, w, h);
  populateYUVLuminanceFromRGB(rgb, yuv, w, h);
  PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(yuv, w, h, 0, 0, w, h, false);
  BinaryBitmap bitmap;
  if (globalHistogram)
    bitmap = new BinaryBitmap(new GlobalHistogramBinarizer(source)); 
  else
    bitmap = new BinaryBitmap(new HybridBinarizer(source)); 
  
  Result result = null;
  try {
    result = reader.decode(bitmap);
  } 
  catch (Exception e) {
  }
  //Once we get the results, we can do some display
  if (result != null &&
    result.getText() != null) {
      
    println(result.getText());
    queryCodeResult = result.getText();
    println("COMPARE 1: "+ queryCodeResult.equals(result.getText()));
    println("COMPARE 2: "+ productSERIAL.equals(queryCodeResult));
    
  }
}

void drawVirtualSpace(){
  
  int resolution=20;
  stroke(255,0,0,100);
 
  pushMatrix();
  translate(width/2,height/2);
  rotate(-radians(azimuth));
  //ejes
  for(int x = resolution; x < width; x+=resolution){
    line(x-(width/2),0-(height/2),x-(width/2),height-(height/2)); 
  }
  for(int y = resolution; y < height; y+=resolution){
    line(0-(width/2),y-(height/2),width-(width/2),y-(height/2)); 
  }    
  popMatrix();  
}

void drawNorth(){
  //Flecha orientadora norte
  pushMatrix();
  translate(width/2,(height/step));
  rotate(-radians(azimuth));
  shape(flecha);
  popMatrix();  
  
}

void drawWareHouse(){
  
  pushMatrix();  
  translate(width/2,height/2);
  //angulo adicional de variación de la disposición de la bodega con respecto al norte 
  //rotate(-radians(azimuth)+wareouseAngle);
  rotate(-radians(azimuth));
  scale(scale);
  //cuadro principal
  fill(255);
  rect(0,0,width,height);
  fill(#fd0d08);  
  //sección 1
  rect(0, 0-(height/step)*2, (width/step)*8, (height/step)*2); 
  //sección 2
  rect(0,(height/step)*2, (width/step)*8, (height/step)*2);
  drawLocationTAGs();
  drawWorker();
  drawProduct();
  popMatrix();  
}

void drawLocationTAGs(){
  float TAGx, TAGy;      
    for (int i = 0; i < dbTAGLocation.size(); i++) {
    
      JSONObject item = dbTAGLocation.getJSONObject(i); 

      TAGx = item.getFloat("positioning_tags___physical_location_X_raw");
      TAGy = item.getFloat("positioning_tags___physical_location_Y_raw");
      
      fill(0,255,0);       
      ellipse(TAGx*(width/stepWareHouseX)-(width/2),TAGy*(height/stepWareHouseY)-(height/2),50,50);
    }
}

void drawWorker(){  
      fill(0,0,255);       
      ellipse(operarioX*(width/stepWareHouseX)-(width/2),operarioY*(height/stepWareHouseY)-(height/2),100,100);
      //ellipse(operarioX,operarioY,100,100);
}

void drawProduct(){  
      fill(255,0,255);       
      ellipse(physicalX*(width/stepWareHouseX)-(width/2),physicalY*(height/stepWareHouseY)-(height/2),100,100);
      //ellipse(operarioX,operarioY,100,100);
}

Boolean queryDBCodeTAG(){
  String serialTAG="0000000000";
  
  print("DB TAG Size: "+dbTAGLocation.size());
    
    for (int i = 0; i < dbTAGLocation.size(); i++) {
    
      JSONObject item = dbTAGLocation.getJSONObject(i);
      serialTAG = item.getString("positioning_tags___serial_raw");
      print("#"+i+" DBserialTAG: "+ serialTAG);
      print("DB_TAG vs. CAM query code: " + queryCodeResult.equals(serialTAG));
      
      //si el serial leido en pantalla corresponde a un tag, actualiza coordenadas de posición
      if(queryCodeResult.equals(serialTAG)){        
        operarioX = item.getFloat("positioning_tags___physical_location_X_raw");
        operarioY = item.getFloat("positioning_tags___physical_location_Y_raw");
        print("Coordenadas de Operario actualizadas, refresque mapa...");
        return true;
      }else{
        print("No Location TAG with that SERIAL...");
      }

    }    
    return false;
} 
