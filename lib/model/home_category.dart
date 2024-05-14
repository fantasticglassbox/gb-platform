class HomeCategoryModel {
  String id = '';
  String name = '';
  String icon = '';
  String image = '';

  HomeCategoryModel(
      {required this.id,
      required this.name,
      required this.icon,
      required this.image});

  HomeCategoryModel.fromJSON(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    icon = json['icon'];
    image = json['image'];
  }
}
