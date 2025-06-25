import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_hive_backend/api/project_models/project.dart';
import 'package:project_hive_backend/repository/repository.dart';
import 'package:projekt_hive/widgets/project_details/project_details.dart';

class ProjectDetailsWidget extends StatelessWidget {
  final Project project;
  final bool active;

  const ProjectDetailsWidget({
    super.key,
    required this.project,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectDetailsBloc(
        repository: context.read<ProjectRepository>(),
        project: project,
        active: active,
      ),
      child: const ProjectDetailsView(),
    );
  }
}

class ProjectDetailsView extends StatelessWidget {
  const ProjectDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailsBloc, ProjectDetailsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateSection(state: state),
              const SizedBox(height: 24),
              _DescriptionSection(state: state),
              const SizedBox(height: 24),
              _ItemsSection(state: state),
              const SizedBox(height: 24),
              _TotalPriceSection(state: state),
            ],
          ),
        );
      },
    );
  }
}

class _DateSection extends StatelessWidget {
  final ProjectDetailsState state;

  const _DateSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProjectDetailsBloc>();

    return GestureDetector(
      onTap: () => _selectDate(context, bloc, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: _cardDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar),
            const SizedBox(width: 8),
            Text(
              'Datum: ${_formatDate(state.project.date)}',
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

  Future<void> _selectDate(BuildContext context, ProjectDetailsBloc bloc, ProjectDetailsState state) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
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
              _buildDatePickerHeader(context),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: state.project.date,
                  mode: CupertinoDatePickerMode.date,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    bloc.add(ProjectDetailsDateUpdated(newDate));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          child: const Text('Abbrechen'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoButton(
          child: const Text('Fertig'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final ProjectDetailsState state;

  const _DescriptionSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProjectDetailsBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Beschreibung'),
        const SizedBox(height: 12),
        Container(
          decoration: _cardDecoration(),
          child: CupertinoTextField(
            controller: bloc.controller,
            placeholder: 'Fügen Sie eine Projektbeschreibung hinzu...',
            padding: const EdgeInsets.all(16),
            maxLines: 5,
            minLines: 3,
            decoration: _textFieldDecoration(),
            textInputAction: TextInputAction.done,
            onEditingComplete: () => _updateDescription(context, bloc),
            onTapOutside: (_) => _updateDescription(context, bloc),
            style: const TextStyle(height: 1.3),
          ),
        ),
      ],
    );
  }

  void _updateDescription(BuildContext context, ProjectDetailsBloc bloc) {
    FocusScope.of(context).unfocus();
    bloc.add(const ProjectDetailsUpdateDescription());
  }
}

class _ItemsSection extends StatelessWidget {
  final ProjectDetailsState state;

  const _ItemsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildItemsList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionTitle('Positionen'),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _addItem(context),
          child: const Icon(CupertinoIcons.add_circled),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    if (state.project.items.isEmpty) {
      return _EmptyItemsList(onAddItem: () => _addItem(context));
    }

    return Column(
      children: List.generate(
        state.project.items.length,
        (index) => _ItemCard(
          item: state.project.items[index],
          index: index,
          isExpanded: state.expandedItems.contains(index),
        ),
      ),
    );
  }

  void _addItem(BuildContext context) {
    final bloc = context.read<ProjectDetailsBloc>();
    final tempItem = ProjectItem();
    _ItemEditDialog.show(context, bloc, tempItem, isNewItem: true);
  }
}

class _EmptyItemsList extends StatelessWidget {
  final VoidCallback onAddItem;

  const _EmptyItemsList({required this.onAddItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.doc_text,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
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
              onPressed: onAddItem,
              child: const Text('Position hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ProjectItem item;
  final int index;
  final bool isExpanded;

  const _ItemCard({
    required this.item,
    required this.index,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProjectDetailsBloc>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(shadow: true),
      child: Column(
        children: [
          _buildMainContent(context, bloc),
          if (isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ProjectDetailsBloc bloc) {
    return GestureDetector(
      onTap: () => bloc.add(ProjectDetailsItemToggled(index)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildItemInfo()),
            _buildActions(context, bloc),
            _buildPrice(),
            _buildExpandIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Column(
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
          '${_formatNumber(item.quantity)} ${item.unit}',
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ProjectDetailsBloc bloc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pencil, size: 22),
          onPressed: () => _ItemEditDialog.show(context, bloc, item, index: index),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.delete, size: 22),
          onPressed: () => _showDeleteConfirmation(context, bloc, index),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Text(
      '${_formatCurrency(item.totalPrice)} €',
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.systemGreen,
      ),
    );
  }

  Widget _buildExpandIcon() {
    return Icon(
      isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
      color: CupertinoColors.systemGrey,
      size: 20,
    );
  }

  Widget _buildExpandedContent() {
    return Container(
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
          Text('${_formatCurrency(item.pricePerUnit)} €'),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProjectDetailsBloc bloc, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Position löschen'),
        content: const Text('Möchten Sie diese Position wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              bloc.add(ProjectDetailsRemoveItem(index));
              _updateExpandedItems(context, bloc, index);
              Navigator.pop(context);
            },
            isDestructiveAction: true,
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _updateExpandedItems(BuildContext context, ProjectDetailsBloc bloc, int removedIndex) {
    final state = context.read<ProjectDetailsBloc>().state;
    final newExpandedItems = <int>{};
    
    for (final expandedIndex in state.expandedItems) {
      if (expandedIndex > removedIndex) {
        newExpandedItems.add(expandedIndex - 1);
      } else if (expandedIndex != removedIndex) {
        newExpandedItems.add(expandedIndex);
      }
    }
    
    bloc.add(ProjectDetailsExpandedItemsUpdated(newExpandedItems));
  }
}

class _TotalPriceSection extends StatelessWidget {
  final ProjectDetailsState state;

  const _TotalPriceSection({required this.state});

  @override
  Widget build(BuildContext context) {
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
            '${_formatCurrency(state.project.totalPrice)} €',
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
}

class _ItemEditDialog {
  static void show(
    BuildContext context,
    ProjectDetailsBloc bloc,
    ProjectItem item, {
    int? index,
    bool isNewItem = false,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ItemEditDialogContent(
          bloc: bloc,
          item: item,
          index: index,
          isNewItem: isNewItem,
        ),
      ),
    );
  }
}

class _ItemEditDialogContent extends StatefulWidget {
  final ProjectDetailsBloc bloc;
  final ProjectItem item;
  final int? index;
  final bool isNewItem;

  const _ItemEditDialogContent({
    required this.bloc,
    required this.item,
    this.index,
    this.isNewItem = false,
  });

  @override
  State<_ItemEditDialogContent> createState() => _ItemEditDialogContentState();
}

class _ItemEditDialogContentState extends State<_ItemEditDialogContent> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(
      text: widget.item.quantity == 0 ? "" : _formatNumber(widget.item.quantity),
    );
    _unitController = TextEditingController(text: widget.item.unit);
    _priceController = TextEditingController(
      text: widget.item.pricePerUnit == 0 ? "" : _formatNumber(widget.item.pricePerUnit),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            if (_errorText.isNotEmpty) _buildErrorMessage(),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      middle: Text(widget.isNewItem ? 'Neue Position' : 'Position bearbeiten'),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Text('Abbrechen'),
        onPressed: () => Navigator.pop(context),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _saveItem,
        child: const Text('Speichern'),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
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
                _errorText,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildDescriptionField(),
        const SizedBox(height: 16),
        _buildQuantityAndUnitFields(),
        const SizedBox(height: 16),
        _buildPriceField(),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel('Titel'),
        _FormField(
          controller: _descriptionController,
          placeholder: 'Titel eingeben',
          onChanged: (value) => widget.item.description = value,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildQuantityAndUnitFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormLabel('Anzahl'),
              _FormField(
                controller: _quantityController,
                placeholder: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                onChanged: _parseQuantity,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormLabel('Einheit'),
              _FormField(
                controller: _unitController,
                placeholder: 'z.B. Stück, m², h',
                textAlign: TextAlign.center,
                onChanged: (value) => widget.item.unit = value,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel('Preis pro Einheit (€)'),
        _FormField(
          controller: _priceController,
          placeholder: '0,00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Text('€'),
          ),
          onChanged: _parsePrice,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  void _parseQuantity(String value) {
    try {
      widget.item.quantity = double.parse(value.replaceAll(',', '.'));
    } catch (_) {
      widget.item.quantity = 0;
    }
  }

  void _parsePrice(String value) {
    try {
      widget.item.pricePerUnit = double.parse(value.replaceAll(',', '.'));
    } catch (_) {
      widget.item.pricePerUnit = 0;
    }
  }

  void _saveItem() {
    if (widget.item.description.isEmpty) {
      setState(() {
        _errorText = 'Bitte geben Sie einen Titel ein';
      });
      return;
    }

    if (widget.isNewItem) {
      widget.bloc.add(ProjectDetailsAddItem(widget.item));
    } else {
      widget.bloc.add(ProjectDetailsUpdateItem(widget.index!, widget.item));
    }
    Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
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
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final Widget? suffix;
  final void Function(String) onChanged;
  final TextInputAction? textInputAction;

  const _FormField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.suffix,
    required this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      textAlign: textAlign,
      suffix: suffix,
      textInputAction: textInputAction,
      maxLines: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _textFieldDecoration(),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
    );
  }
}

BoxDecoration _cardDecoration({bool shadow = false}) {
  return BoxDecoration(
    color: CupertinoColors.systemBackground,
    borderRadius: BorderRadius.circular(shadow ? 10 : 12),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: shadow ? 3 : 4,
              offset: const Offset(0, 1),
            ),
          ]
        : [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
  );
}

BoxDecoration _textFieldDecoration() {
  return BoxDecoration(
    border: Border.all(
      color: CupertinoColors.systemGrey4,
      width: 0.5,
    ),
    borderRadius: BorderRadius.circular(8),
  );
}

String _formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
}

String _formatNumber(double number) {
  return number.toString().replaceAll('.', ',');
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(2).replaceAll('.', ',');
}
