set -e
M=android/app/src/main
J=$M/java/com/mimusica/app

cat > $J/MainActivity.java <<'EOF'
package com.mimusica.app;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    Intent i = new Intent(this, KeepAliveService.class);
    if (Build.VERSION.SDK_INT >= 26) startForegroundService(i); else startService(i);
  }

  @Override
  public void onPause() {
    super.onPause();
    // Mantiene el WebView activo para que la musica siga con la pantalla apagada
    if (getBridge() != null && getBridge().getWebView() != null) {
      getBridge().getWebView().onResume();
      getBridge().getWebView().resumeTimers();
    }
  }
}
EOF

cat > $J/KeepAliveService.java <<'EOF'
package com.mimusica.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;

public class KeepAliveService extends Service {
  @Override
  public IBinder onBind(Intent intent) { return null; }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    String ch = "lyn_playback";
    if (Build.VERSION.SDK_INT >= 26) {
      NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
      nm.createNotificationChannel(new NotificationChannel(ch, "Reproduccion", NotificationManager.IMPORTANCE_LOW));
    }
    PendingIntent pi = PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE);
    Notification.Builder b = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(this, ch) : new Notification.Builder(this);
    Notification n = b.setContentTitle("Lyn<3").setContentText("Tu musica sigue sonando")
        .setSmallIcon(android.R.drawable.ic_media_play).setContentIntent(pi).setOngoing(true).build();
    if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
    else startForeground(1, n);
    return START_STICKY;
  }
}
EOF

sed -i 's#<application#<uses-permission android:name="android.permission.FOREGROUND_SERVICE" /><uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" /><uses-permission android:name="android.permission.WAKE_LOCK" /><uses-permission android:name="android.permission.POST_NOTIFICATIONS" /><application#' $M/AndroidManifest.xml
sed -i 's#</application>#<service android:name=".KeepAliveService" android:foregroundServiceType="mediaPlayback" android:exported="false" /></application>#' $M/AndroidManifest.xml
sed -i 's#>Lyn</string>#>Lyn\&lt;3</string>#g' $M/res/values/strings.xml
grep -n "Lyn" $M/res/values/strings.xml
