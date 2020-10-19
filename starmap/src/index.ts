import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"
import * as data from "../umap.json"

function docReady(fn) {
  // see if DOM is already available
  if (document.readyState === "complete" || document.readyState === "interactive") {
    // call on next available tick
    setTimeout(fn, 1);
  } else {
    document.addEventListener("DOMContentLoaded", fn);
  }
}



const init = () => {
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);
  
  const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 2000);
  camera.position.set(0, 0, 0.01);

  const controls = new OrbitControls(camera, renderer.domElement);
  // controls.enableZoom = false;
  // controls.enablePan = false;
  // controls.enableDamping = true;
  // controls.rotateSpeed = - 0.25;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x182332);

  scene.add(camera)

  data.data.forEach((data)=>{
    var geometry = new THREE.SphereGeometry(1, 6, 6);
    var material = new THREE.MeshBasicMaterial({ color: 0xffffff });
    var sphere = new THREE.Mesh(geometry, material);
    sphere.position.set(data.position[0], data.position[1], data.position[2])
    scene.add(sphere);
  })

  var geometry = new THREE.SphereGeometry(1, 6, 6);
  var material = new THREE.MeshBasicMaterial({ color: 0xffffff });
  var sphere = new THREE.Mesh(geometry, material);
  sphere.position.set(0, 0, -1000);
  scene.add(sphere);
  console.log(scene);
  

  const animate = () => {

    requestAnimationFrame(animate);

    controls.update(); // required when damping is enabled

    renderer.render(scene, camera);

  }

  animate();

}

docReady(()=>{
  init()

});
