class MenuModel {
  String id = '';
  String name = '';
  String thumbnail = '';
  String image = '';
  int price = 0;
  String description = '';
  String labels = '';
  int discount = 0;
  int priceAfterDiscount = 0;
  List categories = [];

  MenuModel(
      {required this.id,
      required this.name,
      required this.thumbnail,
      required this.image,
      required this.price,
      required this.description,
      required this.labels,
      required this.discount,
      required this.priceAfterDiscount,
      required this.categories});

  MenuModel.fromJSON(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    thumbnail = json['thumbnail'];
    image = json['image'];
    price = json['price'];
    description = json['description'];
    labels = json['labels'];
    discount = json['discount'];
    priceAfterDiscount = json['price_after_discount'];
    categories = json['categories'];
  }
}
