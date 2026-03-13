import * as THREE from 'three';
import ThreeBasic from './ThreeBasic';

import mainVS from './shaders/mainVS.glsl';
import mainFS from './shaders/mainFS.glsl';

const threeBasic = new ThreeBasic();
threeBasic.createControls();
threeBasic.createLights();
threeBasic.background = new THREE.Color(0x393939); // SRGBColorSpace
// threeBasic.background = new THREE.Color('skyblue'); // SRGBColorSpace

const geometry = new THREE.BoxGeometry(2, 2, 2);
geometry.computeBoundingBox();

const material = new THREE.ShaderMaterial({
  uniforms: {
    time: {value: 0.0},
    background: {value: threeBasic.background},
    lightPosition: {value: threeBasic.lights[0].position},
    lightColor: {value: threeBasic.lights[0].color},

    boxMin: {value: geometry.boundingBox.min},
    boxMax: {value: geometry.boundingBox.max},

    densityInput: {value: 5.0}
  },
  vertexShader: mainVS,
  fragmentShader: mainFS
});

// UI
const densitySlider = document.getElementById("densityRange");
densitySlider.addEventListener('input', (e) => {
  material.uniforms.densityInput.value = parseFloat(e.target.value);
});

const mesh = new THREE.Mesh(geometry, material);
mesh.update = (time) => {
  mesh.material.uniforms.time.value = time / 1000;
};
threeBasic.scene.add(mesh);