class CategoryModel {
  String id = '';
  String name = '';
  String merchantId = '';
  String icon = '';
  String image = '';
  int pos = 0;

  CategoryModel(
      {required this.id,
      required this.name,
      required this.merchantId,
      required this.icon,
      required this.image,
      required this.pos});

  CategoryModel.fromJSON(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    merchantId = json['merchant_id'];
    icon = json['icon'];
    image = json['image'];
    pos = json['pos'];
  }
}
