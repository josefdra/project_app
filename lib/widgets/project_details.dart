import 'package:flutter/cupertino.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:provider/provider.dart';

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRow(context),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
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
}

class _ProjectDetailsState extends State<ProjectDetails> {
  Set<int> expandedItems = {};
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.project.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

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
    // Create a temporary item but don't add it to the project yet
    final tempItem = ProjectItem();
    _showEditDialog(tempItem, null, true);
  }

  // Updated _showEditDialog function in lib/widgets/project_details.dart
  void _showEditDialog(ProjectItem item, [int? index, bool isNewItem = false]) {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(
        text: item.quantity == 0 ? "" : item.quantity.toString().replaceAll('.', ',')
    );
    final unitController = TextEditingController(text: item.unit);
    final priceController = TextEditingController(
        text: item.pricePerUnit == 0 ? "" : item.pricePerUnit.toString().replaceAll('.', ',')
    );
    String errorText = '';

    // Use a full-screen dialog with a CupertinoPageScaffold
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text(isNewItem ? 'Neue Position' : 'Position bearbeiten'),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Abbrechen'),
                  onPressed: () => Navigator.pop(context),
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Speichern'),
                  onPressed: () {
                    if (item.description.isEmpty) {
                      setState(() {
                        errorText = 'Bitte geben Sie einen Titel ein';
                      });
                      return;
                    }

                    // Add the item to the project only if it's new
                    if (isNewItem) {
                      widget.project.items.add(item);
                    }

                    Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
                    Navigator.pop(context);
                    this.setState(() {}); // Refresh the UI
                  },
                ),
              ),
              child: SafeArea(
                bottom: true,
                child: Column(
                  children: [
                    if (errorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemRed,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorText,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Title field
                          _buildFormLabel('Titel'),
                          _buildFormField(
                            controller: descriptionController,
                            placeholder: 'Titel eingeben',
                            isMultiline: false,
                            onChanged: (value) => item.description = value,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Quantity and Unit Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Anzahl'),
                                    _buildFormField(
                                      controller: quantityController,
                                      placeholder: '0',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      onChanged: (value) {
                                        try {
                                          final parsableValue = value.replaceAll(',', '.');
                                          item.quantity = double.parse(parsableValue);
                                        } catch (_) {
                                          item.quantity = 0;
                                        }
                                      },
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Unit Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Einheit'),
                                    _buildFormField(
                                      controller: unitController,
                                      placeholder: 'z.B. Stück, m², h',
                                      textAlign: TextAlign.center,
                                      onChanged: (value) => item.unit = value,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price Per Unit Field
                          _buildFormLabel('Preis pro Einheit (€)'),
                          _buildFormField(
                            controller: priceController,
                            placeholder: '0,00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            suffix: const Padding(
                              padding: EdgeInsets.only(right: 12.0),
                              child: Text('€'),
                            ),
                            onChanged: (value) {
                              try {
                                final parsableValue = value.replaceAll(',', '.');
                                item.pricePerUnit = double.parse(parsableValue);
                              } catch (_) {
                                item.pricePerUnit = 0;
                              }
                            },
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// Helper to build form labels
  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

// Helper to build form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String placeholder,
    bool isMultiline = false,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    Widget? suffix,
    required void Function(String) onChanged,
    TextInputAction? textInputAction,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      textAlign: textAlign,
      suffix: suffix,
      textInputAction: textInputAction,
      maxLines: isMultiline ? 3 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
      ),
    );
  }

  

  // Updated _buildDescriptionSection() in lib/widgets/project_details.dart
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beschreibung',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Fügen Sie eine Projektbeschreibung hinzu...',
            padding: const EdgeInsets.all(16),
            maxLines: 5,
            minLines: 3,
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            textInputAction: TextInputAction.done, // Add this to enable Done button
            onEditingComplete: () {
              // This closes the keyboard when Done is pressed
              FocusScope.of(context).unfocus();
              widget.project.description = _descriptionController.text;
              Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
            },
            onTapOutside: (_) {
              // This closes the keyboard when tapping outside the field
              FocusScope.of(context).unfocus();
              widget.project.description = _descriptionController.text;
              Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
            },
            style: const TextStyle(
              height: 1.3, // Adjust line height for better text alignment
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_down, size: 16),
          ],
        ),
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
                                '${item.quantity.toString().replaceAll('.', ',')} ${item.unit}',
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
                          '${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
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
                        Text('${item.pricePerUnit.toStringAsFixed(2).replaceAll('.', ',')} €'),
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
            '${widget.project.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
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