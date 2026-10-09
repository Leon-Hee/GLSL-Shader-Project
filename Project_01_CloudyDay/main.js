import * as THREE from 'https://cdn.skypack.dev/three@0.136';

class SimonDevGLSLCourse {
    constructor(){

    }

    async initialize() {
        this.threejs_ = new THREE.WebGLRenderer();
        document.body.appendChild(this.threejs_.domElement);

        window.addEventListener('resize', () => {
            this.onWindowResize_();
        }, false);

        this.scene_ = new THREE.Scene();

        this.camera_ = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 1000);
        this.camera_.position.set(0, 0, 1);

        this.totalTime_ = 0.0;

        await this.setupProject_();

        this.previousRAF_ = null;
        this.onWindowResize_();
        this.raf_();
    }

    async setupProject_() {
        const vsh = await fetch('./shaders/vertex-shader.glsl');
        const fsh = await fetch('./shaders/fragment-shader.glsl');

        

        this.material_ = new THREE.ShaderMaterial({
            uniforms: {
                time: {value: 0.0},
                resolution: {
                    value: new THREE.Vector2(
                        window.innerWidth,
                        window.innerHeight
                    )
                }
            },
            vertexShader: await vsh.text(),
            fragmentShader: await fsh.text()
        });

        const colors = [
            new THREE.Color(0xFF0000),
            new THREE.Color(0xFF0F00),
            new THREE.Color(0xFFF000),
            new THREE.Color(0x000FFF),
        ]
        const colorFloats = colors.map(c => c.toArray()).flat();

        const geometry = new THREE.PlaneGeometry(1, 1);
        geometry.setAttribute(
            'LeonColor',
            new THREE.Float32BufferAttribute(colorFloats, 3)
        );

        const plane = new THREE.Mesh(geometry, this.material_);
        plane.position.set(0.5, 0.5, 0);
        this.scene_.add(plane);
    }


    onWindowResize_() {
        const width = window.innerWidth;
        const height = window.innerHeight;

        this.threejs_.setSize(width, height);
        this.camera_.updateProjectionMatrix();
    }


    raf_() {
        requestAnimationFrame((t) => {
            if (this.previousRAF_ === null) {
                this.previousRAF_ = t;
            }

            const timeElapsed = t - this.previousRAF_;

            this.step_(timeElapsed);

            this.threejs_.render(this.scene_, this.camera_);

            this.previousRAF_ = t;
            this.raf_();
        });
    }

    step_(timeElapsed) {
        const timeElapsedS = timeElapsed * 0.001;
        this.totalTime_ += timeElapsedS;

        this.material_.uniforms.time.value = this.totalTime_;
    }
}

let APP_ = null;

window.addEventListener('DOMContentLoaded', async () => {
    APP_ = new SimonDevGLSLCourse();
    await APP_.initialize();
});