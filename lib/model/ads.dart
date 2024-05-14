class AdsModel {
  String? id;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? partnerId;
  String? createdBy;
  String content = '';
  String type = '';
  int duration = 0;

  AdsModel(
      {required this.content,
      required this.type,
      required this.duration,
      this.id,
      this.createdAt,
      this.createdBy,
      this.deletedAt,
      this.partnerId,
      this.updatedAt});

  AdsModel.fromJSON(Map<String, dynamic> json) {
    id = json['id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    partnerId = json['partner_id'];
    createdBy = json['created_by'];
    content = json['content'];
    type = json['type'];
    duration = json['duration'];
  }
}
