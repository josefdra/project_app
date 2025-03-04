import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project.g.dart';

@HiveType(typeId: 0)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  List<ProjectItem> items;

  @HiveField(4)
  List<String> images;

  @HiveField(5)
  DateTime lastEdited;

  @HiveField(6)
  String description;

  Project({
    String? id,
    required this.name,
    DateTime? date,
    List<ProjectItem>? items,
    List<String>? images,
    DateTime? lastEdited,
    String? description,
  }) :
        id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        items = items ?? [],
        images = images ?? [],
        lastEdited = lastEdited ?? DateTime.now(),
        description = description ?? '';

  double get totalPrice {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Update lastEdited timestamp
  void updateLastEdited() {
    lastEdited = DateTime.now();
  }
}

@HiveType(typeId: 1)
class ProjectItem extends HiveObject {
  @HiveField(0)
  double quantity;

  @HiveField(1)
  String unit;

  @HiveField(2)
  String description;

  @HiveField(3)
  double pricePerUnit;

  ProjectItem({
    this.quantity = 0,
    this.unit = '',
    this.description = '',
    this.pricePerUnit = 0,
  });

  double get totalPrice => quantity * pricePerUnit;
}