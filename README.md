# Body Layers: 3D Anatomy (iOS)

A native SwiftUI + SceneKit port of the [Human Atlas Organs](https://human-altas-organs-louis.vercel.app/) web app ([source](https://github.com/louisyoong/human-altas-organ)). Explore the full body or focus on a single organ system, isolate structures, explode the layers apart, and inspect anatomical detail — all rendered natively on-device from the same [BodyParts3D](https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html) mesh data the web app uses.

## Features

- Full body plus organ-focused categories: heart, brain, kidneys, lungs, liver, stomach, pancreas, spleen
- Body-system layer toggles (skeletal, muscular, cardiac, nervous, etc.) with per-system color coding
- Tap-to-select any structure for name, system, and description
- Isolate a structure, or explode all systems apart to see how they layer
- Front / back / side camera framing, plus pinch-to-zoom and drag-to-orbit
- Search across all 2,234 anatomical structures
- Heart-specific chamber/valve/vessel layers with a "reveal interior" mode

## How it works

The original web app ships raw geometry as gzip-compressed binary blobs (`atlas.json` describes byte offsets into 15 `body-N.bin.gz` chunks; each chunk decompresses to a flat buffer of `Float32` positions, normalized `Int16` normals, and `UInt32` indices). This app reuses that exact data:

- **[Gzip.swift](HumanAtlas/Services/Gzip.swift)** — strips the gzip header/trailer and inflates the raw DEFLATE stream via Apple's `Compression` framework.
- **[AtlasLoader.swift](HumanAtlas/Services/AtlasLoader.swift)** — decompresses chunks concurrently (3 workers, mirroring the web app) and streams parsed per-part geometry back to the main actor.
- **[GeometryBuilder.swift](HumanAtlas/Scene/GeometryBuilder.swift)** — builds an `SCNGeometry` + material per anatomical part.
- **[AnatomyViewModel.swift](HumanAtlas/Scene/AnatomyViewModel.swift)** — ports the web app's category/layer/selection/explode logic.
- **[AnatomySceneView.swift](HumanAtlas/Scene/AnatomySceneView.swift)** — `UIViewRepresentable` wrapping `SCNView`, with a custom orbit camera and bounding-box-based framing for the front/back/side view presets.

## Requirements

- Xcode 16+, iOS 17+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` is generated from [project.yml](project.yml) and is not checked into git

## Getting started

```sh
brew install xcodegen   # if you don't already have it
xcodegen generate
open HumanAtlas.xcodeproj
```

Build and run on an iOS 17+ simulator or device. The ~33MB of anatomy data is bundled directly into the app, so no network access is required.

## Attribution

BodyParts3D, © The Database Center for Life Science, licensed under [Creative Commons Attribution 4.0 International](https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html). Adult male reference anatomy. Educational use only — not for diagnosis or surgical planning.
