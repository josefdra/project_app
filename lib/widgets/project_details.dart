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

    // Determine dialog title based on whether we're creating or editing
    final title = isNewItem ? 'Neue Position hinzufügen' : 'Position bearbeiten';

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            color: CupertinoColors.systemBackground,
            height: MediaQuery.of(context).size.height * 0.8, // Make it larger to accommodate keyboard
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section with title and close/save buttons
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Speichern',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () {
                            // Validate inputs
                            if (item.description.isEmpty) {
                              setState(() {
                                errorText = 'Bitte geben Sie eine Beschreibung ein';
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
                      ],
                    ),
                  ),

                  // Error text if validation fails
                  if (errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.systemRed,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorText,
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Scrollable content area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description Field
                            _buildFormLabel('Beschreibung'),
                            _buildFormField(
                              controller: descriptionController,
                              placeholder: 'Beschreibung eingeben',
                              isMultiline: true,
                              onChanged: (value) => item.description = value,
                            ),
                            SizedBox(height: 24),

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
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        onChanged: (value) {
                                          try {
                                            // Convert comma to dot for decimal parsing
                                            final parsableValue = value.replaceAll(',', '.');
                                            item.quantity = double.parse(parsableValue);
                                          } catch (_) {
                                            item.quantity = 0;
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),

                            // Price Per Unit Field
                            _buildFormLabel('Preis pro Einheit (€)'),
                            _buildFormField(
                              controller: priceController,
                              placeholder: '0,00',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: Text('€'),
                              ),
                              onChanged: (value) {
                                try {
                                  // Convert comma to dot for decimal parsing
                                  final parsableValue = value.replaceAll(',', '.');
                                  item.pricePerUnit = double.parse(parsableValue);
                                } catch (_) {
                                  item.pricePerUnit = 0;
                                }
                              },
                            ),
                            SizedBox(height: 24),

                            // Total Price Preview (read-only)
                            _buildFormLabel('Gesamtpreis (Vorschau)'),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${(item.quantity * item.pricePerUnit).toStringAsFixed(2).replaceAll('.', ',')} €',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.systemGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build consistent form labels
  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  // Helper method to build consistent form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String placeholder,
    bool isMultiline = false,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    Widget? suffix,
    required void Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        textAlign: textAlign,
        suffix: suffix,
        maxLines: isMultiline ? 3 : 1,
        minLines: isMultiline ? 2 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          // Remove default border
          border: null,
        ),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
        ),
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
            onChanged: (value) {
              widget.project.description = value;
              Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
            },
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