import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"
import { NAVY, WHITE } from "./colours";

interface Kupu {
  word: string;
  position: [number, number, number];
  rank: number;
  count: number;
}

function docReady(fn) {
  // see if DOM is already available
  if (document.readyState === "complete" || document.readyState === "interactive") {
    // call on next available tick
    setTimeout(fn, 1);
  } else {
    document.addEventListener("DOMContentLoaded", fn);
  }
}

const buildFontMesh = (text: string, font: THREE.Font, material: THREE.LineBasicMaterial): Promise<THREE.Mesh<THREE.ShapeBufferGeometry, THREE.LineBasicMaterial>> => {

  return new Promise((resolve)=>{
    const fontShapes = font.generateShapes(text, 2);
    const geometry = new THREE.ShapeBufferGeometry(fontShapes, 1.5);
    const mesh = new THREE.Mesh(geometry, material)
    resolve(mesh)
  })
}

type FontMesh = THREE.Mesh<THREE.ShapeBufferGeometry, THREE.LineBasicMaterial>

const kupuLabelMap: Record<string, FontMesh> = {}

const buildKupuLabels = async (scene: THREE.Scene, kupuData: Kupu[], font: THREE.Font) => {
  const matDark = new THREE.LineBasicMaterial({
    color: WHITE,
    side: THREE.FrontSide
  });
  const camera = scene.getObjectByName("camera")
  kupuData.forEach( async (kupu: Kupu) => {
    if (kupuLabelMap[kupu.word]){
      return
    }
    const text = await buildFontMesh(kupu.word.replace(/_/g, " "), font, matDark);
    text.position.set(kupu.position[0], kupu.position[1], kupu.position[2]);
    text.lookAt(camera.position);
    scene.add(text);
    kupuLabelMap[kupu.word] = text
  })
}

const loadDataAndPlaceStars = async (scene: THREE.Scene, kupuData: Kupu[]) => {
  kupuData.forEach((kupu: Kupu) => {
    var geometry = new THREE.SphereGeometry(1, 6, 6);
    var material = new THREE.MeshBasicMaterial({ color: WHITE });
    var sphere = new THREE.Mesh(geometry, material);

    sphere.position.set(kupu.position[0], kupu.position[1], kupu.position[2]);
    scene.add(sphere);
  })
}

const initFont = async () => {
  const fontLoader = new THREE.FontLoader();
  const NotoSerifBoldItalic = await import("../assets/fonts/Noto Serif_Bold Italic.json");
  return fontLoader.parse(NotoSerifBoldItalic)
}

const initControls = (camera: THREE.Camera, domElement: HTMLCanvasElement) =>{
  const controls = new OrbitControls(camera, domElement);
  controls.enableZoom = false;
  controls.enablePan = false;
  controls.enableDamping = true;
  controls.rotateSpeed = - 0.25;

  return controls
}

const init = async () => {
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  
  const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 2000);
  camera.position.set(0, 0, 0.01);
  camera.name = "camera"

  renderer.domElement.addEventListener("wheel", (e: WheelEvent) => {
    e.preventDefault();
    const newZoomLevel = camera.fov + e.deltaY 
    if (newZoomLevel <= 45 && newZoomLevel >= 5 ){
      camera.fov = newZoomLevel;
      camera.updateProjectionMatrix();
    }
  })

  const controls = initControls(camera, renderer.domElement)
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(NAVY);
  scene.add(camera)

  return {scene, controls, renderer, camera}
}

const kupuInView = (camera: THREE.Camera, kupuData: Kupu[], controls: OrbitControls) => {
  const frustum = new THREE.Frustum;
  const baseMatrix = camera.projectionMatrix.clone()
  frustum.setFromProjectionMatrix(baseMatrix.multiply(camera.matrixWorldInverse.clone()));
  return kupuData.filter( 
    (kupu) => (
      frustum.containsPoint( new THREE.Vector3(kupu.position[0], kupu.position[1], kupu.position[2]) )
    )
  )
}

docReady(async () => {
  const { scene, controls, renderer, camera} = await init()
  const umap = await import("../../data/papers/umap.json");
  const font = await initFont();
  const kupuData: Kupu[] = umap.data as Kupu[]

  await loadDataAndPlaceStars(scene, kupuData)
  const animate = () => {
    requestAnimationFrame(animate);
    controls.update(); // required when damping is enabled
    renderer.render(scene, camera);
    if (camera.fov < 7) {
      const visibleKupu = kupuInView(camera, kupuData, controls)
      buildKupuLabels(scene, visibleKupu, font)
    }
  };
  animate();

});
