part of 'project_details_bloc.dart';

abstract class ProjectDetailsEvent extends Equatable {
  const ProjectDetailsEvent();

  @override
  List<Object?> get props => [];
}

class ProjectDetailsDateUpdated extends ProjectDetailsEvent {
  final DateTime date;

  const ProjectDetailsDateUpdated(this.date);

  @override
  List<Object> get props => [date];
}

class ProjectDetailsUpdateDescription extends ProjectDetailsEvent {
  const ProjectDetailsUpdateDescription();
}

class ProjectDetailsItemToggled extends ProjectDetailsEvent {
  final int index;

  const ProjectDetailsItemToggled(this.index);

  @override
  List<Object> get props => [index];
}

class ProjectDetailsRemoveItem extends ProjectDetailsEvent {
  final int index;

  const ProjectDetailsRemoveItem(this.index);

  @override
  List<Object> get props => [index];
}

class ProjectDetailsExpandedItemsUpdated extends ProjectDetailsEvent {
  final Set<int> expandedItems;

  const ProjectDetailsExpandedItemsUpdated(this.expandedItems);

  @override
  List<Object> get props => [expandedItems];
}

class ProjectDetailsAddItem extends ProjectDetailsEvent {
  final ProjectItem item;

  const ProjectDetailsAddItem(this.item);

  @override
  List<Object> get props => [item];
}

class ProjectDetailsUpdateItem extends ProjectDetailsEvent {
  final int index;
  final ProjectItem item;

  const ProjectDetailsUpdateItem(this.index, this.item);

  @override
  List<Object> get props => [index, item];
}
