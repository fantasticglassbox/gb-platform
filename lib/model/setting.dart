class SettingModel {
  bool enableOrdering = true;
  bool defaultImage = true;
  // bool forceUpdateContent = false;
  bool localCacheEnabled = false;

  SettingModel({required this.enableOrdering, required this.defaultImage,required this.localCacheEnabled});
}
