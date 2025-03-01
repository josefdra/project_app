import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class ProjectDetails extends StatefulWidget {
  final Project project;

  const ProjectDetails({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  Set<int> expandedItems = {};

  void toggleItem(int index) {
    setState(() {
      if (expandedItems.contains(index)) {
        expandedItems.remove(index);
      } else {
        expandedItems.add(index);
      }
    });
  }

  void _addItem() {
    final item = ProjectItem();
    widget.project.items.add(item);
    Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
    _showEditDialog(item);
  }

  void _showEditDialog(ProjectItem item, [int? index]) {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(
        text: item.quantity == 0 ? "" : item.quantity.toString()
    );
    final unitController = TextEditingController(text: item.unit);
    final priceController = TextEditingController(
        text: item.pricePerUnit == 0 ? "" : item.pricePerUnit.toString()
    );
    String errorText = '';

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            color: CupertinoColors.systemBackground,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Abbrechen'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Position bearbeiten',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Speichern'),
                      onPressed: () {
                        // Validate inputs
                        if (item.description.isEmpty) {
                          setState(() {
                            errorText = 'Bitte geben Sie eine Beschreibung ein';
                          });
                          return;
                        }

                        Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
                        Navigator.pop(context);
                        this.setState(() {}); // Refresh the UI
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (errorText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Text('Beschreibung'),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: descriptionController,
                  placeholder: 'Beschreibung',
                  onChanged: (value) => item.description = value,
                  maxLines: 2,
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Anzahl'),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: quantityController,
                            placeholder: 'Anzahl',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              try {
                                item.quantity = double.parse(value);
                              } catch (_) {
                                item.quantity = 0;
                              }
                            },
                            padding: const EdgeInsets.all(12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Einheit'),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: unitController,
                            placeholder: 'Einheit',
                            onChanged: (value) => item.unit = value,
                            padding: const EdgeInsets.all(12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Preis pro Einheit (€)'),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: priceController,
                  placeholder: 'Preis pro Einheit',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    try {
                      item.pricePerUnit = double.parse(value);
                    } catch (_) {
                      item.pricePerUnit = 0;
                    }
                  },
                  suffix: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Text('€'),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRow(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Positionen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addItem,
                child: const Icon(CupertinoIcons.add_circled),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildItemsList(context),
          const SizedBox(height: 24),
          _buildTotalPrice(context),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Row(
        children: [
          const Icon(CupertinoIcons.calendar),
          const SizedBox(width: 8),
          Text(
            'Datum: ${_formatDate(widget.project.date)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Use cupertino date picker with a modal popup
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Abbrechen'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Fertig'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: widget.project.date,
                  mode: CupertinoDatePickerMode.date,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      widget.project.date = newDate;
                      Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    if (widget.project.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              const Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey),
              const SizedBox(height: 12),
              const Text(
                'Keine Positionen vorhanden',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _addItem,
                child: const Text('Position hinzufügen'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        widget.project.items.length,
            (index) {
          final item = widget.project.items[index];
          final isExpanded = expandedItems.contains(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => toggleItem(index),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} ${item.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.pencil, size: 22),
                          onPressed: () => _showEditDialog(item, index),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.delete, size: 22),
                          onPressed: () {
                            _showDeleteConfirmation(context, index);
                          },
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemGreen,
                          ),
                        ),
                        Icon(
                          isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Preis pro ${item.unit}:'),
                        Text('${item.pricePerUnit.toStringAsFixed(2)} €'),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Position löschen'),
        content: const Text('Möchten Sie diese Position wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              setState(() {
                widget.project.items.removeAt(index);
                if (expandedItems.contains(index)) {
                  expandedItems.remove(index);
                }
                // Adjust expanded indices for items after the deleted one
                final newExpandedItems = <int>{};
                for (final expandedIndex in expandedItems) {
                  if (expandedIndex > index) {
                    newExpandedItems.add(expandedIndex - 1);
                  } else {
                    newExpandedItems.add(expandedIndex);
                  }
                }
                expandedItems = newExpandedItems;
                Provider.of<ProjectProvider>(context, listen: false)
                    .updateProject(widget.project);
              });
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPrice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Gesamtpreis:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${widget.project.totalPrice.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}