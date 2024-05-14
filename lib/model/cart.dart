class CartModel {
  String id = '';
  int totalItem = 0;
  Map subTotal = {'currency': 'IDR', 'value': 0};
  List items = [];

  CartModel(
      {required this.id,
      required this.totalItem,
      required this.subTotal,
      required this.items});

  CartModel.fromJSON(Map<String, dynamic> json) {
    id = json['id'];
    totalItem = json['total_item'];
    subTotal = json['sub_total'];
    items = json['items'];
  }
}
