# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ARCore (Sceneform)
-keep class com.google.ar.core.** { *; }
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.sceneform.rendering.** { *; }
-keep class com.google.ar.sceneform.ux.** { *; }
-keep class com.google.ar.sceneform.animation.** { *; }
-keep class com.google.ar.sceneform.collision.** { *; }
-keep class com.google.ar.sceneform.math.** { *; }
-keep class com.google.ar.sceneform.rendering.** { *; }

# Sceneform animation classes
-keep class com.google.ar.sceneform.animation.ModelAnimator { *; }
-keep class com.google.ar.sceneform.animation.AnimationEngine { *; }
-keep class com.google.ar.sceneform.animation.AnimationEngine$1 { *; }
-keep class com.google.ar.sceneform.animation.AnimationEngine$AnimationEngineImpl { *; }

# Sceneform asset loading
-keep class com.google.ar.sceneform.assets.** { *; }
-keep class com.google.ar.sceneform.rendering.RenderableSource { *; }
-keep class com.google.ar.sceneform.rendering.ModelRenderable { *; }
-keep class com.google.ar.sceneform.rendering.Texture { *; }
-keep class com.google.ar.sceneform.rendering.Material { *; }
-keep class com.google.ar.sceneform.rendering.MaterialFactory { *; }
-keep class com.google.ar.sceneform.rendering.Color { *; }

# Sceneform nodes and components
-keep class com.google.ar.sceneform.Node { *; }
-keep class com.google.ar.sceneform.Node$OnTapListener { *; }
-keep class com.google.ar.sceneform.Node$OnTouchListener { *; }
-keep class com.google.ar.sceneform.NodeParent { *; }

# Sceneform camera and view
-keep class com.google.ar.sceneform.Camera { *; }
-keep class com.google.ar.sceneform.Scene { *; }
-keep class com.google.ar.sceneform.SceneView { *; }
-keep class com.google.ar.sceneform.ArSceneView { *; }
-keep class com.google.ar.sceneform.ux.ArFragment { *; }
-keep class com.google.ar.sceneform.ux.BaseArFragment { *; }

# Sceneform math and utilities
-keep class com.google.ar.sceneform.math.** { *; }
-keep class com.google.ar.sceneform.utilities.** { *; }

# ARCore Flutter Plugin
-keep class com.apptreesoftware.arcore_flutter_plugin.** { *; }
-keep class io.flutter.plugins.arcore_flutter_plugin.** { *; }

# ModelViewer
-keep class com.google.modelviewer.** { *; }
-keep class com.google.android.filament.** { *; }
-keep class com.google.android.filament.android.** { *; }

# Keep all native methods that might be called from JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep callback methods
-keepclassmembers class * {
    void onEvent*(***);
    void on*Event(***);
}

# Keep model data classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep View bindings
-keepclassmembers class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep the custom application class
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgent
-keep public class * extends android.preference.Preference

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable
-keep class kotlin.Metadata { *; }
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep the -ViewBinding classes
-keep class * extends androidx.viewbinding.ViewBinding
-keep class * implements androidx.viewbinding.ViewBinding

# Keep the -DataBinding classes
-keep class * extends androidx.databinding.ViewDataBinding
-keep class * implements androidx.databinding.DataBindingComponent
-keepclassmembers class * {
    @androidx.databinding.Bindable <fields>;
}

# Keep the -BR classes
-keep class **.BR {
    *;
}
