package com.videocompressor.video_compressor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		// Ensure all Flutter plugins register correctly for method channels like file_picker
		GeneratedPluginRegistrant.registerWith(flutterEngine)
	}
}
