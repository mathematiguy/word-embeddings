import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"
import { NAVY, WHITE } from "./colours";
import PointTexture from "../assets/textures/point.png"

interface Kupu {
  word: string;
  position: [number, number, number];
  rank: number;
  count: number;
}

function docReady(fn: () => void ) {
  // see if DOM is already available
  if (document.readyState === "complete" || document.readyState === "interactive") {
    // call on next available tick
    setTimeout(fn, 1);
  } else {
    document.addEventListener("DOMContentLoaded", fn);
  }
}

const toTitleCase = (phrase: string) => {
  return phrase
    .toLowerCase()
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
};

const buildFontMesh = (text: string, font: THREE.Font, material: THREE.LineBasicMaterial): Promise<THREE.Mesh<THREE.ShapeBufferGeometry, THREE.LineBasicMaterial>> => {
  return new Promise( (resolve) => {
    const fontShapes = font.generateShapes(text, 1.5);
    const geometry = new THREE.ShapeBufferGeometry(fontShapes, 1);
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
      kupuLabelMap[kupu.word].visible = true;
      return
    }
    const text = await buildFontMesh(toTitleCase(kupu.word.replace(/_/g, " ")), font, matDark);
    text.position.set(kupu.position[0], kupu.position[1], kupu.position[2]);
    text.lookAt(camera.position);
    text.translateY(-.8)
    text.translateX(2)
    scene.add(text);
    kupuLabelMap[kupu.word] = text
  })
}

const hideAllKupuLabels = () => {
  Object.keys(kupuLabelMap)
  .forEach((key)=>{
    kupuLabelMap[key].visible = false;
  })
}

const buildPointCloud = (material, kupuData: Kupu[]) => {
  const vertices = kupuData.reduce((accum, kupu) => ([...accum, ...kupu.position]) ,[])

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));

  const points = new THREE.Points(geometry, material);

  return points
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
  controls.rotateSpeed = - 0.25;

  return controls
}

const initRenderer = () => {
  const renderer = new THREE.WebGLRenderer({
    antialias: true,
    powerPreference: "high-performance",
  });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  return renderer
}

const initCamera = () => {
  const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 500, 1100);
  camera.position.set(0, 0, 0.01);
  camera.name = "camera"

  return camera
}


const initZoomListener = (camera: THREE.PerspectiveCamera, renderer: THREE.Renderer, controls: OrbitControls, render:()=>void) => {
  renderer.domElement.addEventListener("wheel", (e: WheelEvent) => {
    e.preventDefault();
    const newZoomLevel = camera.fov + e.deltaY;
    if (newZoomLevel <= 45 && newZoomLevel >= 5) {
      camera.fov = newZoomLevel;
      camera.updateProjectionMatrix();
      render()
    }
    if (newZoomLevel > 10){
      hideAllKupuLabels();
      render()
    }
  })
}

const initScene = (camera: THREE.PerspectiveCamera) => {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(NAVY);
  scene.add(camera)

  return scene
}

const init = async () => {
  const renderFuncs = []
  const render = () => {
    renderFuncs.forEach(func => func())
  };
  const addRenderFunc = (func) => renderFuncs.push(func);
  
  const renderer = initRenderer();
  const camera = initCamera();
  const controls = initControls(camera, renderer.domElement);
  const scene = initScene(camera);
  initZoomListener(camera, renderer, controls, render);
  const font = await initFont();
  addRenderFunc(() => renderer.render(scene, camera))
  

  controls.addEventListener("change", render)

  return { scene, controls, renderer, camera, font, addRenderFunc, render}
}

const kupuInView = (camera: THREE.PerspectiveCamera, kupuData: Kupu[]) => {
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
  const { scene, camera, renderer, font, addRenderFunc, render} = await init()
  const umap = await import("../te_ara.json");
  const kupuData: Kupu[] = umap.data as Kupu[]
  const sprite = new THREE.TextureLoader().load(PointTexture);
  const pointMaterial = new THREE.PointsMaterial({ color: WHITE, map:sprite});
  const pointCloud = buildPointCloud(pointMaterial, kupuData)
  scene.add(pointCloud)

  addRenderFunc(()=>{
    const defaultSize = 1.5;
    pointMaterial.size = defaultSize / Math.tan((Math.PI / 180) * camera.fov / 2);

    if (camera.fov < 10) {
      const visibleKupu = kupuInView(camera, kupuData);
      buildKupuLabels(scene, visibleKupu, font);
    }
  })
  render();


});
