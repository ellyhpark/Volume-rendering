import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/Addons.js';

class ThreeBasic {
    constructor() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        this.scene = new THREE.Scene();
        
        this.camera = new THREE.PerspectiveCamera(55, width / height, 0.1, 1000);
        this.camera.position.x = 0;
        this.camera.position.y = 5;
        this.camera.position.z = 10;
        
        this.renderer = new THREE.WebGLRenderer();
        this.renderer.setSize(width, height);
        this.renderer.setAnimationLoop((time) => this.animate(time));
        document.body.appendChild(this.renderer.domElement);

        window.addEventListener('resize', () => this.resize());
    }

    animate(time) {
        this.renderer.render(this.scene, this.camera);
        this.controls?.update(); // calls update() or returns undefined

        // calls update() if it is defined in obj
        this.scene.traverse((obj) => obj.update?.(time));
    }

    resize() {
        const width = window.innerWidth;
        const height = window.innerHeight;

        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(width, height);
    }

    createControls() {
        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
    }
    
    createLights() {
        const dirLight = new THREE.DirectionalLight(0xffffff, 1);
        dirLight.position.set(0, 10, 0);
        this.scene.add(dirLight);

        this.lights = [dirLight];
    }

    set background(color) {
        this.scene.background = color;
    }

    get background() {
        return this.scene.background;
    }
}

export default ThreeBasic;