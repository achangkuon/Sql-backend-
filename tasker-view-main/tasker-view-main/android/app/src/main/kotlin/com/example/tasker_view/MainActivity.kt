package com.example.tasker_view

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

/**
 * Main Activity for ServiTask.
 *
 * Uses SurfaceView with Impeller — the recommended config for Android API 35+.
 * SurfaceView is composited directly by SurfaceFlinger (bypasses HWUI),
 * which avoids the TextureView+Skia black-screen issue on API 37 emulators.
 *
 * If the emulator still shows a black screen, change the AVD Graphics setting
 * to "Software - GLES 2.0" in Android Studio → Device Manager → Edit AVD.
 */
class MainActivity : FlutterActivity() {

    /** SurfaceView: composited by SurfaceFlinger, required for Impeller. */
    override fun getRenderMode(): RenderMode = RenderMode.surface
}

