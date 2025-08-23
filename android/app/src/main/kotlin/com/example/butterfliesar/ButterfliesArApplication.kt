package com.example.butterfliesar

import android.app.Application
import android.util.Log
import com.google.ar.core.ArCoreApk

class ButterfliesArApplication : Application() {
    companion object {
        private const val TAG = "ButterfliesArApp"
    }

    override fun onCreate() {
        super.onCreate()
        
        // Check ARCore availability
        checkArCoreAvailability()
    }
    
    private fun checkArCoreAvailability() {
        try {
            val availability = ArCoreApk.getInstance().checkAvailability(this)
            when (availability) {
                ArCoreApk.Availability.SUPPORTED_INSTALLED -> {
                    Log.d(TAG, "ARCore is supported and installed")
                }
                ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD,
                ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED -> {
                    Log.d(TAG, "ARCore needs to be installed or updated")
                    // The actual installation will be handled in the MainActivity
                }
                else -> {
                    Log.e(TAG, "ARCore is not supported on this device: $availability")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking ARCore availability", e)
        }
    }
}
