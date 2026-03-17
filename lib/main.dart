import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EmployeeApp());
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portal Kepegawaian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6FBFA),
        useMaterial3: true,
      ),
      home: const EmployeeHomePage(),
    );
  }
}

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  static const _storageKey = 'employees_storage_v1';

  final TextEditingController _searchController = TextEditingController();
  final List<Employee> _employees = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _employees
        ..clear()
        ..addAll(
          decoded.map(
            (item) => Employee.fromMap(item as Map<String, dynamic>),
          ),
        );
    } else {
      _employees.addAll(Employee.sampleData);
      await _saveEmployees();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _employees.map((employee) => employee.toMap()).toList(),
    );
    await prefs.setString(_storageKey, payload);
  }

  Future<void> _openEmployeeForm({Employee? employee}) async {
    final result = await showDialog<Employee>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeFormDialog(employee: employee),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = _employees.indexWhere((item) => item.id == result.id);
      if (index >= 0) {
        _employees[index] = result;
      } else {
        _employees.insert(0, result);
      }
    });

    await _saveEmployees();
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data pegawai'),
        content: Text(
          'Yakin ingin menghapus data ${employee.name}? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _employees.removeWhere((item) => item.id == employee.id);
    });

    await _saveEmployees();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${employee.name} berhasil dihapus.')),
    );
  }

  List<Employee> get _filteredEmployees {
    if (_searchQuery.isEmpty) {
      return _employees;
    }

    return _employees.where((employee) {
      final source = [
        employee.name,
        employee.nip,
        employee.position,
        employee.department,
        employee.email,
      ].join(' ').toLowerCase();

      return source.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final employees = _filteredEmployees;
    final totalEmployees = _employees.length;
    final activeEmployees = _employees.where((item) => item.isActive).length;
    final inactiveEmployees = totalEmployees - activeEmployees;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Kepegawaian'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEmployeeForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pegawai'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SummaryCard(
                                title: 'Total Pegawai',
                                value: '$totalEmployees',
                                icon: Icons.groups_2_outlined,
                                color: const Color(0xFF0F766E),
                              ),
                              SummaryCard(
                                title: 'Pegawai Aktif',
                                value: '$activeEmployees',
                                icon: Icons.verified_user_outlined,
                                color: const Color(0xFF2563EB),
                              ),
                              SummaryCard(
                                title: 'Nonaktif',
                                value: '$inactiveEmployees',
                                icon: Icons.person_off_outlined,
                                color: const Color(0xFFB45309),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    runSpacing: 12,
                                    spacing: 12,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Data Pegawai',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Kelola informasi pegawai untuk seluruh platform.',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: isWide ? 320 : double.infinity,
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Cari nama, NIP, jabatan, unit...',
                                            prefixIcon:
                                                const Icon(Icons.search),
                                            suffixIcon:
                                                _searchQuery.isNotEmpty
                                                ? IconButton(
                                                    onPressed: () {
                                                      _searchController.clear();
                                                    },
                                                    icon: const Icon(Icons.close),
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  if (employees.isEmpty)
                                    const EmptyEmployeeState()
                                  else if (isWide)
                                    EmployeeDataTable(
                                      employees: employees,
                                      onEdit: _openEmployeeForm,
                                      onDelete: _deleteEmployee,
                                    )
                                  else
                                    Column(
                                      children: employees
                                          .map(
                                            (employee) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: EmployeeListCard(
                                                employee: employee,
                                                onEdit: () =>
                                                    _openEmployeeForm(
                                                      employee: employee,
                                                    ),
                                                onDelete: () =>
                                                    _deleteEmployee(employee),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class EmployeeDataTable extends StatelessWidget {
  const EmployeeDataTable({
    super.key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Employee> employees;
  final Future<void> Function({Employee? employee}) onEdit;
  final Future<void> Function(Employee employee) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('NIP')),
          DataColumn(label: Text('Jabatan')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Kontak')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: employees.map((employee) {
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      employee.address,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              DataCell(Text(employee.nip)),
              DataCell(Text(employee.position)),
              DataCell(Text(employee.department)),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(employee.email),
                    Text(
                      employee.phone,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              DataCell(StatusChip(isActive: employee.isActive)),
              DataCell(
                Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => onEdit(employee: employee),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: () => onDelete(employee),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class EmployeeListCard extends StatelessWidget {
  const EmployeeListCard({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFCCFBF1),
                foregroundColor: const Color(0xFF115E59),
                child: Text(employee.name.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${employee.position} • ${employee.department}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              StatusChip(isActive: employee.isActive),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'NIP', value: employee.nip),
          _InfoRow(label: 'Email', value: employee.email),
          _InfoRow(label: 'Telepon', value: employee.phone),
          _InfoRow(label: 'Alamat', value: employee.address),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Aktif' : 'Nonaktif'),
      labelStyle: TextStyle(
        color: isActive ? const Color(0xFF166534) : const Color(0xFF92400E),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor:
          isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.5)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyEmployeeState extends StatelessWidget {
  const EmptyEmployeeState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.manage_search, size: 48, color: Colors.black45),
          SizedBox(height: 12),
          Text(
            'Data pegawai tidak ditemukan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Coba ubah kata kunci pencarian atau tambahkan data pegawai baru.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class EmployeeFormDialog extends StatefulWidget {
  const EmployeeFormDialog({super.key, this.employee});

  final Employee? employee;

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nipController;
  late final TextEditingController _positionController;
  late final TextEditingController _departmentController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  late bool _isActive;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee?.name ?? '');
    _nipController = TextEditingController(text: employee?.nip ?? '');
    _positionController = TextEditingController(text: employee?.position ?? '');
    _departmentController = TextEditingController(
      text: employee?.department ?? '',
    );
    _emailController = TextEditingController(text: employee?.email ?? '');
    _phoneController = TextEditingController(text: employee?.phone ?? '');
    _addressController = TextEditingController(text: employee?.address ?? '');
    _isActive = employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final employee = Employee(
      id: widget.employee?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      nip: _nipController.text.trim(),
      position: _positionController.text.trim(),
      department: _departmentController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      isActive: _isActive,
    );

    Navigator.pop(context, employee);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Pegawai' : 'Tambah Pegawai'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.badge_outlined,
                ),
                _buildField(
                  controller: _nipController,
                  label: 'NIP',
                  icon: Icons.numbers_outlined,
                ),
                _buildField(
                  controller: _positionController,
                  label: 'Jabatan',
                  icon: Icons.work_outline,
                ),
                _buildField(
                  controller: _departmentController,
                  label: 'Unit / Divisi',
                  icon: Icons.account_tree_outlined,
                ),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!text.contains('@')) {
                      return 'Format email belum valid';
                    }
                    return null;
                  },
                ),
                _buildField(
                  controller: _phoneController,
                  label: 'Nomor Telepon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _buildField(
                  controller: _addressController,
                  label: 'Alamat',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Status Pegawai Aktif'),
                  subtitle: const Text(
                    'Matikan jika pegawai sudah tidak aktif bekerja.',
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label wajib diisi';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.nip,
    required this.position,
    required this.department,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
  });

  final String id;
  final String name;
  final String nip;
  final String position;
  final String department;
  final String email;
  final String phone;
  final String address;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nip': nip,
      'position': position,
      'department': department,
      'email': email,
      'phone': phone,
      'address': address,
      'isActive': isActive,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      nip: map['nip'] as String,
      position: map['position'] as String,
      department: map['department'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      isActive: map['isActive'] as bool,
    );
  }

  static const sampleData = [
    Employee(
      id: '1',
      name: 'Siti Rahmawati',
      nip: '198706122015042001',
      position: 'HR Generalist',
      department: 'Sumber Daya Manusia',
      email: 'siti.rahmawati@kantor.id',
      phone: '0812-9876-1234',
      address: 'Bandung, Jawa Barat',
      isActive: true,
    ),
    Employee(
      id: '2',
      name: 'Budi Santoso',
      nip: '199112032018011004',
      position: 'Staff IT Support',
      department: 'Teknologi Informasi',
      email: 'budi.santoso@kantor.id',
      phone: '0813-5555-2201',
      address: 'Semarang, Jawa Tengah',
      isActive: true,
    ),
    Employee(
      id: '3',
      name: 'Maya Putri',
      nip: '198903172016072006',
      position: 'Analis Keuangan',
      department: 'Keuangan',
      email: 'maya.putri@kantor.id',
      phone: '0821-3456-7890',
      address: 'Yogyakarta',
      isActive: false,
    ),
  ];
}
