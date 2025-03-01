import 'package:flutter/material.dart';
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
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    provider.updateProject(widget.project);
    _showEditDialog(item);
  }

  void _showEditDialog(ProjectItem item) {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(
        text: item.quantity == 0 ? "" : item.quantity.toString()
    );
    final unitController = TextEditingController(text: item.unit);
    final priceController = TextEditingController(
        text: item.pricePerUnit == 0 ? "" : item.pricePerUnit.toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Position bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              controller: descriptionController,
              onChanged: (value) => item.description = value,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Anzahl',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => item.quantity = double.tryParse(value) ?? 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Einheit',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    controller: unitController,
                    onChanged: (value) => item.unit = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Preis pro Einheit in €',
                suffixText: '€',
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              controller: priceController,
              keyboardType: TextInputType.number,
              onChanged: (value) => item.pricePerUnit = double.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              provider.updateProject(widget.project);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Positionen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                tooltip: 'Position hinzufügen',
              ),
            ],
          ),
          _buildItemsList(context),
          const SizedBox(height: 16),
          _buildTotalPrice(context),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today),
        const SizedBox(width: 8),
        Text(
          'Datum: ${_formatDate(widget.project.date)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return Column(
      children: List.generate(
        widget.project.items.length,
            (index) {
          final item = widget.project.items[index];
          final isExpanded = expandedItems.contains(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                InkWell(
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${item.quantity} ${item.unit}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(item),
                          tooltip: 'Bearbeiten',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.project.items.removeAt(index);
                            final provider = Provider.of<ProjectProvider>(
                              context,
                              listen: false,
                            );
                            provider.updateProject(widget.project);
                            setState(() {});
                          },
                          tooltip: 'Löschen',
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
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

  Widget _buildTotalPrice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Gesamtpreis:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${widget.project.totalPrice.toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
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