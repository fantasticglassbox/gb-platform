class MenuModifierModel {
  String modifierGroupId = '';
  String name = '';
  String description = '';
  bool required = true;
  int minimumSelectable = 1;
  int maximumSelectable = 1;
  dynamic modifierOption;

  MenuModifierModel(
      {required this.modifierGroupId,
      required this.name,
      required this.description,
      required this.required,
      required this.minimumSelectable,
      required this.maximumSelectable,
      required this.modifierOption});

  MenuModifierModel.fromJSON(Map<String, dynamic> json) {
    modifierGroupId = json['modifier_group_id'];
    name = json['name'];
    description = json['description'];
    required = json['required'];
    minimumSelectable = json['minimum_selectable'];
    maximumSelectable = json['maximum_selectable'];
    modifierOption = json['modifier_option'];
  }
}
