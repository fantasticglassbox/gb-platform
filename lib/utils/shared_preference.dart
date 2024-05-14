import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AndroidOptions getAndroidOptions() => const AndroidOptions(
      encryptedSharedPreferences: true,
      // sharedPreferencesName: 'Test2',
      // preferencesKeyPrefix: 'Test'
    );
