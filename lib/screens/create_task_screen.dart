// lib/screens/create_task_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:optitime/models/task_model.dart';
import 'package:optitime/providers/task_provider.dart';
import 'package:optitime/providers/task_type_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  // Si se pasa una tarea existente, la pantalla entra en modo edición
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

  // Modo edición si se recibió una tarea
  bool get _isEditing => widget.task != null;

  final List<Map<String, dynamic>> _importanceLevels = [
    {'label': 'Predeterminado\n(por\nconfiguración)', 'color': Colors.grey.shade300, 'value': -1},
    {'label': '0', 'color': const Color(0xFF90CAF9), 'value': 0},
    {'label': '1', 'color': const Color(0xFF66BB6A), 'value': 1},
    {'label': '2', 'color': const Color(0xFFFFEE58), 'value': 2},
    {'label': '3', 'color': const Color(0xFFFFA726), 'value': 3},
    {'label': '4', 'color': const Color(0xFFEF5350), 'value': 4},
    {'label': '5', 'color': const Color(0xFF6D1F1F), 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    // Si hay tarea existente, prellenamos todos los campos
    if (_isEditing) {
      final t = widget.task!;
      _titleController.text = t.title;
      _detailsController.text = t.details;
      _selectedDate = t.dueDate;
      _noDate = t.dueDate == null;
      _selectedType = t.type;
      _selectedImportance = t.importance;
      _reminder = t.reminder;
      _imagePaths = List.from(t.imagePaths);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // ── Seleccionar imagen ────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePaths.add(picked.path));
    }
  }

  // ── Seleccionar fecha ─────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    if (_noDate) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3A3A9F),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      );
      setState(() {
        _selectedDate = pickedTime != null
            ? DateTime(picked.year, picked.month, picked.day,
                pickedTime.hour, pickedTime.minute)
            : picked;
      });
    }
  }

  // ── Guardar o actualizar tarea ────────────────────────────────────────────
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    final taskTypes = context.read<TaskTypeProvider>().allTypes;
    final taskType = taskTypes.contains(_selectedType)
        ? _selectedType
        : TaskTypeProvider.defaultTypes.first;

    if (_isEditing) {
      // Actualiza la tarea existente conservando su id y fecha de creación
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
      // Crea una tarea nueva
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

  // ── Eliminar tarea (solo en modo edición) ─────────────────────────────────
  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNombreField(),
                      const SizedBox(height: 22),
                      _buildDiaLimite(),
                      const SizedBox(height: 22),
                      _buildTipoTarea(),
                      const SizedBox(height: 22),
                      _buildDetalles(),
                      const SizedBox(height: 22),
                      _buildElementos(),
                      const SizedBox(height: 22),
                      _buildImportancia(),
                      const SizedBox(height: 22),
                      _buildRecordatorios(),
                      const SizedBox(height: 32),
                      _buildButtons(),
                      // Botón eliminar solo en modo edición
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        _buildDeleteButton(),
                      ],
                      const SizedBox(height: 20),
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

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B5FDC), Color(0xFF5BC8F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Text(
        _isEditing ? 'Editar tarea' : 'Crear nueva tarea',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildNombreField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nombre:'),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Escribe el título...',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF3A3A9F), width: 2),
            ),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildDiaLimite() {
    final dateLabel = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
          '${_selectedDate!.year.toString().substring(2)} '
          '${_selectedDate!.hour.toString().padLeft(2, '0')}:'
          '${_selectedDate!.minute.toString().padLeft(2, '0')}'
        : 'dd/mm/aa';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Día límite'),
        Row(
          children: [
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: const Icon(Icons.calendar_month_outlined,
                    color: Color(0xFF3A3A9F), size: 28),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: _selectedDate != null
                        ? const Color(0xFF3A3A9F)
                        : const Color(0xFFBDBDBD),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('No definir',
                    style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                Switch(
                  value: _noDate,
                  activeColor: const Color(0xFF3A3A9F),
                  onChanged: (v) => setState(() {
                    _noDate = v;
                    if (v) _selectedDate = null;
                  }),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipoTarea() {
    final taskTypes = context.watch<TaskTypeProvider>().allTypes;
    final selectedType =
        taskTypes.contains(_selectedType) ? _selectedType : taskTypes.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tipo de tarea'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3A3A9F)),
              items: taskTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Detalles'),
        TextFormField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF3A3A9F), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElementos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Elementos'),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imagePaths.map((path) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(path),
                              width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imagePaths.remove(path)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BC8F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportancia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Elegir nivel de importancia'),
        const Text(
          '*Al elegir una importancia personalizada no cambiará con el tiempo',
          style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _importanceLevels.map((level) {
            final isSelected = _selectedImportance == level['value'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedImportance = level['value']),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: level['color'],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: const Color(0xFF3A3A9F), width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      level['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF424242)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecordatorios() {
    return Row(
      children: [
        const Text(
          'Enviar recordatorios',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        Switch(
          value: _reminder,
          activeColor: const Color(0xFF3A3A9F),
          onChanged: (v) => setState(() => _reminder = v),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B5FDC), Color(0xFF5BC8F5)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isEditing ? 'Actualizar' : 'Guardar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              side: const BorderSide(color: Color(0xFFBDBDBD)),
              foregroundColor: const Color(0xFF757575),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text(
          'Eliminar tarea',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
