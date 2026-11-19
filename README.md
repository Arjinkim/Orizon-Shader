# Orizon Shader

<img src="assets/banner.jpg" width="100%" alt="Orizon Shader Preview">

## Overview

Orizon Shader is a high-fidelity, physically-inspired shading pipeline for Minecraft, engineered upon the architectural foundation of Bliss Shader (authored by X0nk) and Chocapic13 Shaders. 

The primary objective of Orizon Shader is to deliver a balanced, cinematic visual presentation with particular emphasis on extreme view distances, realistic atmospheric optics, volumetric media simulation, and cross-platform compatibility. It integrates low-level vertex geometry corrections for distant level-of-detail (LOD) systems and provides full dual-language localization (English and Thai) across all configuration menus.

---

## Technical Architecture and Features

### 1. Distant Horizons and Level-of-Detail (LOD) Integration
* **Compact Far LOD Decoding**: Implements a dedicated vertex-stage decoding routine for 64-bit compact LOD tiles (`FAR_BASE`), preventing buffer out-of-bounds reads and eliminating planar geometry collapse at extreme distances.
* **Cull Guard Safety**: Restricts vertex transformations on unassigned or invalid LOD indices across solid, translucent, and shadow passes.
* **Atmospheric Distance Fog Blending**: Features an extended logarithmic depth blending algorithm that seamlessly merges standard chunk boundaries with Distant Horizons LOD geometry without visible seams or clipping planes.

### 2. Atmospheric Simulation, Nocturnal Celestial Optics, and Volumetrics
* **Rayleigh and Mie Scattering**: Employs an analytical atmospheric scattering model that accurately simulates daylight transitions from dawn, midday, golden hour, to astronomical twilight.
* **Multi-Layered Volumetric Clouds**: Implements ray-marched 3D cloud coverage with dynamic density variation, altitude-dependent shading, and directional sunlight absorption.
* **Animated Dancing Aurora Borealis**: Multi-harmonic flowing Northern Lights ribbons rippling across the northern celestial dome with real-time curtain flutter and physical altitude spectral emissions (557.7nm emerald base, cyan, violet, and 630.0nm crimson crown).
* **Photorealistic Lunar Corona and Surface Maria**: Renders the lunar disc with procedurally calculated basalt seas (lunar maria) and impact crater topography, framed by multi-stage celestial halos and soft moonlight scattering.
* **Milky Way Galactic Core and Scintillating Stars**: Detailed galactic disk structure with bright Sagittarius A* core bulge, dark cosmic dust rifts, stellar cluster formations (Pleiades), and atmospheric twinkling across blackbody stellar classifications.
* **Procedural Nocturnal Fireflies**: Ambient bioluminescent particle simulation generating soft, flickering golden-emerald fireflies hovering over grass and forest undergrowth on clear nights.

### 3. Lighting, Shadows, and Surface Optics
* **Distortion-Protected Shadow Projection**: Integrates logarithmic shadow map distortion with near-zero singularity guards to eliminate projection artifacts and geometric tearing along shadow frustum boundaries.
* **Translucent Colored Shadows**: Full light transmission and tint attenuation through colored glass and translucent barriers.
* **Subsurface Scattering (SSS)**: Approximates light diffusion through thin materials including foliage, grass, leaves, and organic structures.
* **Colored Voxel Illumination**: Full compatibility with Iris-based voxel floodfill lighting for emissive blocks and handheld light sources.
* **Configurable Night and Cave Brightness**: Adjustable minimum light illuminance slider (`MIN_LIGHT_AMOUNT`), allowing players to calibrate visibility in subterranean environments and moonless nights for comfortable survival gameplay.

### 4. Surface Motion, Water Optics, and Precipitation
* **Procedural Foliage Swaying**: Wind velocity vector equations applied to plants, canopy leaves, and tall grass with biome-dependent wave speed and amplitude.
* **Dynamic Water Simulation and Biome Tinting**: Multi-octave wave generation with physically calculated refraction, specular highlights, Snell's window effect, underwater caustics, and automatic watercolor adaptation based on biome geography (e.g., swamps, rivers, warm oceans).
* **Precipitation Wetness and Puddles**: Dynamic PBR surface puddle generation responding to active rain cycles with reflective surface pooling.

### 5. Configured Profile Presets
Orizon Shader includes calibrated rendering presets accessible directly via the in-game profile selector:
* **Quality (Cinematic Vista)**: Maximum visual fidelity featuring 2048 shadow map resolution, multi-layer volumetric clouds, biome-tinted water, and high-sample ambient occlusion.
* **Performance (FPS Boost)**: Optimized for sustained high frame rates with reduced shadow draw distance and streamlined cloud ray-marching.
* **Survival Balanced**: Engineered specifically for gameplay comfort, providing enhanced subterranean ambient illumination, expanded handheld torch radiance, and balanced rendering overhead.
* **Vibrant Fantasy**: Elevated color saturation and warm chromatic balance, offering a stylized, picturesque visual presentation.

### 6. Multi-Language Localization and Packaging
* **Complete Interface Translation**: Fully localized in native English (`en_us`) and Thai (`th_th`), covering all setting screens, parameter sliders, technical explanations, and debug menus.
* **Standardized Technical Nomenclature**: Clear, professional terminology without encoding corruption or visual clutter in the game UI.
* **Embedded Shaderpack Icon**: Includes high-resolution `icon.png` metadata asset recognized automatically by Iris Shaders and modern shader management interfaces.

---

## System Requirements and Compatibility

### Graphics Hardware and APIs
| Specification | Minimum | Recommended |
|---|---|---|
| **Graphics API** | OpenGL 4.5+ / Vulkan | OpenGL 4.6 / Vulkan 1.3 |
| **GPU Vendor** | NVIDIA GeForce / AMD Radeon / Intel Arc | NVIDIA RTX 2060+ / AMD Radeon RX 6600+ |
| **Video Memory (VRAM)** | 4 GB | 6 GB or higher |
| **Display Resolution** | 1080p | 1440p / 4K |

### Minecraft Platform Compatibility
* **Iris Shaders + Sodium** (Minecraft Java Edition): Fully supported and strongly recommended.
* **Distant Horizons Mod**: Fully supported with native LOD pipeline fixes.
* **Horizon Engine** (Rust/wgpu rewrite): Compatible via native WGSL profile and manifest specifications.
* **OptiFine**: Legacy support available for standard rendering features.

---

## Installation Guide

### Standard Installation (Iris Shaders)
1. Ensure Minecraft is installed with **Fabric** or **NeoForge**, along with **Sodium** and **Iris Shaders**.
2. If extended view distance is desired, install the **Distant Horizons** mod compatible with your game version.
3. Download the latest release from the repository:
   * Navigate to the **Releases** tab on the right side of the repository page and download `Orizon-Shader.zip`.
   * Alternatively, click the green **Code** button and select **Download ZIP**.
4. Place the downloaded `.zip` file directly into your game's shaderpacks directory:
   * Windows: `%APPDATA%\.minecraft\shaderpacks\`
   * Linux: `~/.minecraft/shaderpacks/`
   * macOS: `~/Library/Application Support/minecraft/shaderpacks/`
5. Launch Minecraft, navigate to **Options -> Video Settings -> Shader Packs**, and select **Orizon-Shader**.

---

## Recommended In-Game Settings

To achieve optimal visual balance and performance when using Distant Horizons:
* **Max Render Distance (Minecraft)**: 12 - 16 Chunks.
* **Distant Horizons CPU Load**: Balanced or Minimal Impact.
* **Distant Horizons Max Target Distance**: 64 - 128 Chunks.
* **Profile Selection (Shader Settings)**:
  * Select **Quality** for maximum volumetric fidelity and soft shadows.
  * Select **Performance** for higher frame rates and optimized shadow map resolution.

---

## Repository Structure

```
Orizon-Shader/
├── .github/              # Issue and contribution templates
├── assets/               # Documentation media and banner assets
├── shaders/              # Core GLSL shading passes and properties
│   ├── dimensions/       # Deferred, composite, and geometry passes
│   ├── lang/             # Localization files (en_us, th_th, etc.)
│   ├── lib/              # Atmospheric, lighting, and mathematical libraries
│   ├── world-1/          # Nether-specific pipeline passes
│   ├── world0/           # Overworld-specific pipeline passes
│   └── world1/           # End-specific pipeline passes
├── CREDITS.txt           # Detailed upstream attribution
├── LICENSE.md            # License terms and conditions
└── README.md             # Project documentation
```

---

## Credits and Acknowledgements

Orizon Shader builds upon the foundational research and development of the Minecraft shading community:

* **X0nk**: Original author of [Bliss Shader](https://github.com/X0nk/Bliss-Shader), pioneering custom tonemapping, daily weather logic, and atmospheric style.
* **Chocapic13**: Author of the baseline [Chocapic13' Shaders](https://www.curseforge.com/minecraft/customization/chocapic13-shaders) pipeline.
* **Sasha (WoMspace)**: Depth of field architecture and camera optics.
* **Null**: Voxel-based floodfill colored illumination framework.
* **EminGT & Gri573**: Light-leak mitigation and diffuse lighting enhancements.
* **SixthSurge & RRe36**: Mathematical models, inspiration, and graphics engineering techniques.
* **Arjinkim**: Orizon Shader development, Distant Horizons pipeline reconstruction, vertex decoding stabilization, and complete Thai translation.

---

## License

This software is distributed in compliance with the original licensing terms established by Chocapic13 and Bliss Shader. Consult [LICENSE.md](LICENSE.md) and [CREDITS.txt](CREDITS.txt) for explicit terms, limitations, and attribution requirements.
