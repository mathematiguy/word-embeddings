import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"

function docReady(fn) {
  // see if DOM is already available
  if (document.readyState === "complete" || document.readyState === "interactive") {
    // call on next available tick
    setTimeout(fn, 1);
  } else {
    document.addEventListener("DOMContentLoaded", fn);
  }
}

const loadDataAndPlaceStars = async (scene: THREE.Scene) => {
  const {data} = await import("../umap.json");
  data.forEach((kupu) => {
    var geometry = new THREE.SphereGeometry(1, 6, 6);
    var material = new THREE.MeshBasicMaterial({ color: 0xffffff });
    var sphere = new THREE.Mesh(geometry, material);
    sphere.position.set(kupu.position[0], kupu.position[1], kupu.position[2]);
    scene.add(sphere);
  })
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

  const controls = initControls(camera, renderer.domElement)

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x182332);

  scene.add(camera)

  return {scene, controls, renderer, camera}
}

docReady(async () => {
  const { scene, controls, renderer, camera} = await init()
  const animate = () => {
    requestAnimationFrame(animate);
    controls.update(); // required when damping is enabled
    renderer.render(scene, camera);
  };
  animate();
  await loadDataAndPlaceStars(scene)

});
