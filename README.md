# Neon Trail

**Neon Trail** is a small Godot 4.7 3D obstacle-course runner. The track, runner, barriers, gems, lighting, and UI are made from built-in 3D shapes—no paid assets or add-ons.

## Play

- **A / D** or **← / →**: change lanes
- **Space**, **W**, or **↑**: jump
- You run forward automatically. Dodge the glowing barriers and collect gold gems.
- On a phone, use the on-screen buttons.

## Web preview

1. Open this repository's **Actions** tab.
2. Select **Web Preview** → **Run workflow** on `main`.
3. When it completes, open the Pages link:
   `https://keshab1997.github.io/godot-3d-obstacle-course/`

GitHub Pages is enabled for this repository with **GitHub Actions** as the deployment source. If you fork this project, set **Settings → Pages → Build and deployment → Source: GitHub Actions** before the first deployment.

## Android builds

Run **Actions → Android APK and AAB → Run workflow**. The workflow always creates a debug-signed APK for device testing. To create a Play Store AAB, select **include_aab** and configure these repository Actions secrets first:

- `ANDROID_KEYSTORE_BASE64` — Base64 of your private upload keystore
- `ANDROID_KEYSTORE_PASSWORD` — keystore/key password
- `ANDROID_KEY_ALIAS` — key alias

Never commit a keystore or its password. The workflow stores APK/AAB files as downloadable Actions artifacts; it does not publish them to a store.

## Local development

Open `project.godot` with Godot **4.7.2 stable** and press **F6/F5**. Web export uses the **Web** preset. Android export presets are included; Android SDK, Java, and the debug keystore are needed for local Android builds.
