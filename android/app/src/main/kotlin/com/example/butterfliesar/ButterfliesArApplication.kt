package com.example.butterfliesar

import android.app.Application
import android.util.Log

class ButterfliesArApplication : Application() {
    companion object {
        private const val TAG = "ButterfliesArApp"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application started - Using ModelViewer for 3D content")
    }
}
