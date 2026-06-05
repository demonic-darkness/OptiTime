// lib/screens/create_task_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:optitime/models/task_model.dart';
import 'package:optitime/providers/settings_provider.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/providers/task_type_provider.dart';
import 'package:optitime/widgets/app_top_bar.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task;

  const CreateTaskScreen({super.key, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  bool _noDate = false;
  String _selectedType = 'Academica';
  int _selectedImportance = -1;
  bool _reminder = false;
  List<String> _imagePaths = [];

  bool get _isEditing => widget.task != null;
  bool get _isDark => context.watch<SettingsProvider>().darkMode;

  Color get _pageBg =>
      _isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F6FF);
  Color get _surface => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _surfaceAlt =>
      _isDark ? const Color(0xFF111827) : const Color(0xFFEFF6FF);
  Color get _heading =>
      _isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1C1C1E);
  Color get _muted =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8E8E93);
  Color get _accent =>
      _isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
  Color get _border =>
      _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
  Color get _danger => const Color(0xFFFF3B30);

  static const String _font = '.SF Pro Text';

  final List<Map<String, dynamic>> _importanceLevels = [
    {'label': 'Auto', 'color': const Color(0xFF94A3B8), 'value': -1},
    {'label': '0', 'color': const Color(0xFF90CAF9), 'value': 0},
    {'label': '1', 'color': const Color(0xFF66BB6A), 'value': 1},
    {'label': '2', 'color': const Color(0xFFE0A800), 'value': 2},
    {'label': '3', 'color': const Color(0xFFFFA726), 'value': 3},
    {'label': '4', 'color': const Color(0xFFEF5350), 'value': 4},
    {'label': '5', 'color': const Color(0xFF6D1F1F), 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.task!;
      _titleController.text = task.title;
      _detailsController.text = task.details;
      _selectedDate = task.dueDate;
      _noDate = task.dueDate == null;
      _selectedType = task.type;
      _selectedImportance = task.importance;
      _reminder = task.reminder;
      _imagePaths = List.from(task.imagePaths);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePaths.add(picked.path));
    }
  }

  Future<void> _pickDate() async {
    if (_noDate) return;

    final isDark = context.read<SettingsProvider>().darkMode;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(primary: _accent, onPrimary: Colors.white)
              : ColorScheme.light(primary: _accent, onPrimary: Colors.white),
          dialogTheme: DialogThemeData(backgroundColor: _surface),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDate != null
          ? TimeOfDay.fromDateTime(_selectedDate!)
          : TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(primary: _accent, onPrimary: Colors.white)
              : ColorScheme.light(primary: _accent, onPrimary: Colors.white),
          dialogTheme: DialogThemeData(backgroundColor: _surface),
        ),
        child: child!,
      ),
    );

    setState(() {
      _selectedDate = pickedTime != null
          ? DateTime(
              picked.year,
              picked.month,
              picked.day,
              pickedTime.hour,
              pickedTime.minute,
            )
          : picked;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    final taskTypes = context.read<TaskTypeProvider>().allTypes;
    final taskType = taskTypes.contains(_selectedType)
        ? _selectedType
        : TaskTypeProvider.defaultTypes.first;

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleController.text.trim(),
        dueDate: _noDate ? null : _selectedDate,
        clearDueDate: _noDate,
        type: taskType,
        details: _detailsController.text.trim(),
        imagePaths: _imagePaths,
        importance: _selectedImportance,
        reminder: _reminder,
      );
      await provider.updateTask(updated);
    } else {
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        dueDate: _noDate ? null : _selectedDate,
        type: taskType,
        details: _detailsController.text.trim(),
        imagePaths: _imagePaths,
        importance: _selectedImportance,
        reminder: _reminder,
        createdAt: DateTime.now(),
      );
      await provider.addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          'Eliminar tarea',
          style: TextStyle(color: _heading, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta tarea?',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Editar tarea' : 'Crear tarea';

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              backgroundColor: _pageBg,
              primaryColor: _accent,
              mutedColor: _muted,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScreenTitle(title),
                      const SizedBox(height: 18),
                      _buildSection(
                        title: 'Información',
                        icon: Icons.assignment_outlined,
                        children: [
                          _buildTextField(
                            controller: _titleController,
                            label: 'Nombre',
                            hint: 'Escribe el título...',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTypePicker(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _detailsController,
                            label: 'Detalles',
                            hint: 'Agrega notas, instrucciones o contexto...',
                            minLines: 4,
                            maxLines: 6,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Programación',
                        icon: Icons.event_outlined,
                        children: [
                          _buildDateRow(),
                          const SizedBox(height: 14),
                          _buildSwitchRow(
                            title: 'Enviar recordatorios',
                            subtitle: 'Usa las reglas configuradas en ajustes',
                            value: _reminder,
                            onChanged: (value) =>
                                setState(() => _reminder = value),
                            icon: Icons.notifications_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Importancia',
                        icon: Icons.flag_outlined,
                        children: [_buildImportancePicker()],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Elementos',
                        icon: Icons.image_outlined,
                        children: [_buildImagePicker()],
                      ),
                      const SizedBox(height: 22),
                      _buildButtons(),
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTitle(String title) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _accent,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            side: BorderSide(color: _border),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: _font,
                  color: _heading,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isEditing
                    ? 'Actualiza la información registrada'
                    : 'Organiza una nueva actividad',
                style: TextStyle(
                  fontFamily: _font,
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: _font,
                  color: _heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontFamily: _font, color: _heading, fontSize: 15),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildTypePicker() {
    final taskTypes = context.watch<TaskTypeProvider>().allTypes;
    final selectedType = taskTypes.contains(_selectedType)
        ? _selectedType
        : taskTypes.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tipo de tarea'),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _fieldDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              dropdownColor: _surface,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
              style: TextStyle(
                fontFamily: _font,
                color: _heading,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: taskTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    final dateLabel = _selectedDate == null
        ? 'Sin fecha definida'
        : _dateText(_selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Día límite'),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: _fieldDecoration(opacity: _noDate ? 0.55 : 1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: _accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontFamily: _font,
                            color: _selectedDate == null ? _muted : _heading,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'No definir',
                  style: TextStyle(
                    fontFamily: _font,
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _noDate,
                  activeThumbColor: _accent,
                  onChanged: (value) => setState(() {
                    _noDate = value;
                    if (value) _selectedDate = null;
                  }),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: _font,
                    color: _heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: _font,
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: _accent, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildImportancePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Al elegir una importancia personalizada no cambiará con el tiempo.',
          style: TextStyle(fontFamily: _font, color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _importanceLevels.map((level) {
              final value = level['value'] as int;
              final color = level['color'] as Color;
              final selected = _selectedImportance == value;

              // Non-auto items: show colored circles without numbers.
              final bgColor = value == -1
                  ? (selected ? color : _surfaceAlt)
                  : (selected ? color : color.withOpacity(0.22));

              final borderColor = value == -1
                  ? (selected ? color : _border)
                  : (selected ? color : color.withOpacity(0.45));

              return GestureDetector(
                onTap: () => setState(() => _selectedImportance = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: value == -1 ? 76 : 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: borderColor,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: value == -1
                        ? Text(
                            level['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _font,
                              color: selected ? Colors.white : _heading,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            }).toList(),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._imagePaths.map(
            (path) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(path),
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePaths.remove(path)),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: _accent,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: BorderSide(color: _border),
              foregroundColor: _muted,
              backgroundColor: _surface,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isEditing ? 'Actualizar' : 'Guardar',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _deleteTask,
        icon: const Icon(Icons.delete_outline),
        label: const Text(
          'Eliminar tarea',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _danger,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: _danger.withValues(alpha: 0.55)),
          backgroundColor: _danger.withValues(alpha: _isDark ? 0.10 : 0.06),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          color: _heading,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: _font, color: _muted, fontSize: 14),
      filled: true,
      fillColor: _surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: _inputBorder(_border),
      enabledBorder: _inputBorder(_border),
      focusedBorder: _inputBorder(_accent, width: 1.6),
      errorBorder: _inputBorder(_danger.withValues(alpha: 0.65)),
      focusedErrorBorder: _inputBorder(_danger, width: 1.6),
    );
  }

  BoxDecoration _fieldDecoration({double opacity = 1}) {
    return BoxDecoration(
      color: _surfaceAlt.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }
}
