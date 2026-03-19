import 'dart:async';
import 'dart:typed_data';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/employee.dart';
import 'services/employee_repository.dart';
import 'supabase_bootstrap.dart';
import 'update/app_update_widgets.dart';

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key, required this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6FBFA),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF14B8A6),
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF101A14),
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111827),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: _buildLightTheme(),
      dark: _buildDarkTheme(),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Portal Kepegawaian',
          theme: theme,
          darkTheme: darkTheme,
          home: AutoUpdateGate(
            child: isSupabaseConfigured
                ? const EmployeeHomePage()
                : const SupabaseSetupPage(),
          ),
        );
      },
    );
  }
}

class SupabaseSetupPage extends StatelessWidget {
  const SupabaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Kepegawaian'),
        actions: [
          AppBarQuickActionsButton(
            pendingCount: 0,
            onOpenNotifications: null,
            onRefresh: null,
            realtimeStatuses: const {
              'employees': 'belum tersambung',
              'requester': 'belum tersambung',
              'target': 'belum tersambung',
              'hub': 'belum tersambung',
            },
            realtimeEventCounts: const {
              'employees': 0,
              'requester': 0,
              'target': 0,
              'hub': 0,
            },
            realtimeLastPayloads: const {
              'employees': '-',
              'requester': '-',
              'target': '-',
              'hub': '-',
            },
            lastRealtimeEventAt: null,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.cloud_sync_outlined, size: 52),
                    SizedBox(height: 16),
                    Text(
                      'Supabase belum dikonfigurasi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Isi file .env supaya portal kepegawaian tersambung ke database cloud.',
                    ),
                    SizedBox(height: 20),
                    _CommandBlock(
                      command: 'SUPABASE_URL=https://YOUR-PROJECT.supabase.co',
                    ),
                    SizedBox(height: 12),
                    _CommandBlock(command: 'SUPABASE_ANON_KEY=YOUR_ANON_KEY'),
                    SizedBox(height: 20),
                    Text(
                      'Setelah file .env terisi, aplikasi akan login anonim ke Supabase lalu semua operasi CRUD memakai tabel employees.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SelectableText(
        command,
        style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
      ),
    );
  }
}

enum _HomeSection { dashboard, employees, users }

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final EmployeeRepository _repository = const EmployeeRepository();
  final TextEditingController _searchController = TextEditingController();
  final List<Employee> _employees = [];
  static const int _pageSize = 10;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRefreshingData = false;
  String _searchQuery = '';
  String? _errorMessage;
  int _currentPage = 0;
  _HomeSection _selectedSection = _HomeSection.dashboard;
  EmployeeDashboardStats? _dashboardStats;
  List<EmployeeUserActivity> _employeeUsers = const [];
  List<DataAccessRequestNotification> _incomingRequests = const [];
  RealtimeChannel? _employeesRealtimeChannel;
  RealtimeChannel? _accessRequesterRealtimeChannel;
  RealtimeChannel? _accessTargetRealtimeChannel;
  RealtimeChannel? _portalEventsRealtimeChannel;
  Timer? _realtimeRefreshDebounce;
  bool _pendingRealtimeRefresh = false;
  String? _subscribedUserId;
  final Map<String, String> _realtimeStatuses = {
    'employees': 'belum tersambung',
    'requester': 'belum tersambung',
    'target': 'belum tersambung',
    'hub': 'belum tersambung',
  };
  final Map<String, int> _realtimeEventCounts = {
    'employees': 0,
    'requester': 0,
    'target': 0,
    'hub': 0,
  };
  final Map<String, String> _realtimeLastPayloads = {
    'employees': '-',
    'requester': '-',
    'target': '-',
    'hub': '-',
  };
  DateTime? _lastRealtimeEventAt;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 0;
      });
    });
    _loadEmployees();
  }

  @override
  void dispose() {
    _realtimeRefreshDebounce?.cancel();
    _disposeRealtimeSubscriptions();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees({bool showPageLoader = true}) async {
    final shouldShowPageLoader = showPageLoader && _employees.isEmpty;

    setState(() {
      if (shouldShowPageLoader) {
        _isLoading = true;
      } else {
        _isRefreshingData = true;
      }
      _errorMessage = null;
    });

    try {
      final employeesFuture = _repository.fetchEmployees();
      final dashboardStatsFuture = _repository.fetchDashboardStats();
      final employeeUsersFuture = _repository.fetchEmployeeUsers();
      final incomingRequestsFuture = _repository.fetchIncomingAccessRequests();
      final employees = await employeesFuture;
      EmployeeDashboardStats? dashboardStats;
      List<EmployeeUserActivity>? employeeUsers;
      List<DataAccessRequestNotification>? incomingRequests;

      try {
        dashboardStats = await dashboardStatsFuture;
      } catch (_) {
        dashboardStats = _dashboardStats;
      }

      try {
        employeeUsers = await employeeUsersFuture;
      } catch (_) {
        employeeUsers = _employeeUsers;
      }

      try {
        incomingRequests = await incomingRequestsFuture;
      } catch (_) {
        incomingRequests = _incomingRequests;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _employees
          ..clear()
          ..addAll(employees);
        _dashboardStats = dashboardStats;
        _employeeUsers = employeeUsers ?? const [];
        _incomingRequests = incomingRequests ?? const [];
        _syncCurrentPage(filteredCount: _filteredEmployees.length);
      });
      _setupRealtimeSubscriptionsIfNeeded();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _isRefreshingData = false;
    });

    if (_pendingRealtimeRefresh) {
      _pendingRealtimeRefresh = false;
      _scheduleRealtimeRefresh();
    }
  }

  Future<void> _openEmployeeForm({Employee? employee}) async {
    final result = await showDialog<Employee>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeFormDialog(
        employee: employee,
        userId: _repository.currentUser?.id ?? '',
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedEmployee = employee == null
          ? await _repository.createEmployee(result)
          : await _repository.updateEmployee(result);

      if (!mounted) {
        return;
      }

      setState(() {
        final index = _employees.indexWhere(
          (item) => item.id == savedEmployee.id,
        );
        if (index >= 0) {
          _employees[index] = savedEmployee;
        } else {
          _employees.insert(0, savedEmployee);
        }
        _syncCurrentPage(filteredCount: _filteredEmployees.length);
      });

      _showMessage(
        employee == null
            ? 'Pegawai berhasil ditambahkan.'
            : 'Data pegawai berhasil diperbarui.',
      );
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    await _refreshDashboardStats();
    await _refreshEmployeeUsers();
    await _refreshIncomingRequests();
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.deleteEmployee(employee.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _employees.removeWhere((item) => item.id == employee.id);
        _syncCurrentPage(filteredCount: _filteredEmployees.length);
      });
      _showMessage('${employee.name} berhasil dihapus.');
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    await _refreshDashboardStats();
    await _refreshEmployeeUsers();
    await _refreshIncomingRequests();
  }

  Future<void> _showEmployeeDetails(Employee employee) async {
    await showDialog<void>(
      context: context,
      builder: (context) => EmployeeDetailDialog(employee: employee),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
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

  int get _totalPages {
    final totalItems = _filteredEmployees.length;
    if (totalItems == 0) {
      return 1;
    }

    return (totalItems / _pageSize).ceil();
  }

  List<Employee> get _paginatedEmployees {
    final employees = _filteredEmployees;
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= employees.length) {
      return const [];
    }

    final endIndex = (startIndex + _pageSize).clamp(0, employees.length);
    return employees.sublist(startIndex, endIndex);
  }

  void _syncCurrentPage({required int filteredCount}) {
    final totalPages = filteredCount == 0
        ? 1
        : (filteredCount / _pageSize).ceil();
    final lastPage = totalPages - 1;
    if (_currentPage > lastPage) {
      _currentPage = lastPage;
    }
    if (_currentPage < 0) {
      _currentPage = 0;
    }
  }

  void _selectSection(_HomeSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  void _scheduleRealtimeRefresh() {
    if (mounted) {
      setState(() {
        _lastRealtimeEventAt = DateTime.now();
      });
    }
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      if (_isLoading) {
        _pendingRealtimeRefresh = true;
        return;
      }
      _pendingRealtimeRefresh = false;
      _loadEmployees(showPageLoader: false);
    });
  }

  void _setupRealtimeSubscriptionsIfNeeded() {
    final userId = _repository.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }
    if (_subscribedUserId == userId &&
        _employeesRealtimeChannel != null &&
        _accessRequesterRealtimeChannel != null &&
        _accessTargetRealtimeChannel != null &&
        _portalEventsRealtimeChannel != null) {
      return;
    }

    _disposeRealtimeSubscriptions();
    _subscribedUserId = userId;

    _employeesRealtimeChannel = supabaseClient
        .channel('public:employees:all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'employees',
          callback: (payload) {
            _recordRealtimeEvent(
              key: 'employees',
              summary:
                  '${payload.eventType.name} ${payload.table} ${payload.schema}',
            );
            _scheduleRealtimeRefresh();
          },
        )
        .onSystemEvents((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastRealtimeEventAt = DateTime.now();
          });
        })
        .subscribe((status, error) {
          _updateRealtimeStatus(
            key: 'employees',
            status: _formatRealtimeStatus(status, error),
          );
        });

    _accessRequesterRealtimeChannel = supabaseClient
        .channel('public:employee_data_access_requests:requester:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'employee_data_access_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requester_user_id',
            value: userId,
          ),
          callback: (payload) {
            _recordRealtimeEvent(
              key: 'requester',
              summary:
                  '${payload.eventType.name} ${payload.table} ${payload.schema}',
            );
            _scheduleRealtimeRefresh();
          },
        )
        .onSystemEvents((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastRealtimeEventAt = DateTime.now();
          });
        })
        .subscribe((status, error) {
          _updateRealtimeStatus(
            key: 'requester',
            status: _formatRealtimeStatus(status, error),
          );
        });

    _accessTargetRealtimeChannel = supabaseClient
        .channel('public:employee_data_access_requests:target:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'employee_data_access_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_user_id',
            value: userId,
          ),
          callback: (payload) {
            _recordRealtimeEvent(
              key: 'target',
              summary:
                  '${payload.eventType.name} ${payload.table} ${payload.schema}',
            );
            _scheduleRealtimeRefresh();
          },
        )
        .onSystemEvents((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastRealtimeEventAt = DateTime.now();
          });
        })
        .subscribe((status, error) {
          _updateRealtimeStatus(
            key: 'target',
            status: _formatRealtimeStatus(status, error),
          );
        });

    _portalEventsRealtimeChannel = supabaseClient
        .channel('public:portal_realtime_events:hub')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'portal_realtime_events',
          callback: (payload) {
            _recordRealtimeEvent(
              key: 'hub',
              summary:
                  '${payload.eventType.name} ${payload.table} ${payload.schema}',
            );
            _scheduleRealtimeRefresh();
          },
        )
        .onSystemEvents((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastRealtimeEventAt = DateTime.now();
          });
        })
        .subscribe((status, error) {
          _updateRealtimeStatus(
            key: 'hub',
            status: _formatRealtimeStatus(status, error),
          );
        });
  }

  void _updateRealtimeStatus({
    required String key,
    required String status,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _realtimeStatuses[key] = status;
    });
  }

  void _recordRealtimeEvent({
    required String key,
    required String summary,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _lastRealtimeEventAt = DateTime.now();
      _realtimeEventCounts[key] = (_realtimeEventCounts[key] ?? 0) + 1;
      _realtimeLastPayloads[key] = summary;
    });
  }

  String _formatRealtimeStatus(
    RealtimeSubscribeStatus status,
    Object? error,
  ) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        return 'subscribed';
      case RealtimeSubscribeStatus.channelError:
        return error == null ? 'channel error' : 'error: $error';
      case RealtimeSubscribeStatus.closed:
        return 'closed';
      case RealtimeSubscribeStatus.timedOut:
        return 'timed out';
    }
  }

  void _disposeRealtimeSubscriptions() {
    final employeesChannel = _employeesRealtimeChannel;
    final requesterChannel = _accessRequesterRealtimeChannel;
    final targetChannel = _accessTargetRealtimeChannel;
    final hubChannel = _portalEventsRealtimeChannel;

    _employeesRealtimeChannel = null;
    _accessRequesterRealtimeChannel = null;
    _accessTargetRealtimeChannel = null;
    _portalEventsRealtimeChannel = null;
    _subscribedUserId = null;
    _realtimeStatuses['employees'] = 'belum tersambung';
    _realtimeStatuses['requester'] = 'belum tersambung';
    _realtimeStatuses['target'] = 'belum tersambung';
    _realtimeStatuses['hub'] = 'belum tersambung';
    _realtimeEventCounts['employees'] = 0;
    _realtimeEventCounts['requester'] = 0;
    _realtimeEventCounts['target'] = 0;
    _realtimeEventCounts['hub'] = 0;
    _realtimeLastPayloads['employees'] = '-';
    _realtimeLastPayloads['requester'] = '-';
    _realtimeLastPayloads['target'] = '-';
    _realtimeLastPayloads['hub'] = '-';
    _lastRealtimeEventAt = null;

    if (employeesChannel != null) {
      supabaseClient.removeChannel(employeesChannel);
    }
    if (requesterChannel != null) {
      supabaseClient.removeChannel(requesterChannel);
    }
    if (targetChannel != null) {
      supabaseClient.removeChannel(targetChannel);
    }
    if (hubChannel != null) {
      supabaseClient.removeChannel(hubChannel);
    }
  }

  Future<void> _refreshDashboardStats() async {
    try {
      final dashboardStats = await _repository.fetchDashboardStats();
      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardStats = dashboardStats;
      });
    } catch (_) {
      // Keep the latest dashboard numbers if the aggregate endpoint is unavailable.
    }
  }

  Future<void> _refreshEmployeeUsers() async {
    try {
      final employeeUsers = await _repository.fetchEmployeeUsers();
      if (!mounted) {
        return;
      }

      setState(() {
        _employeeUsers = employeeUsers;
      });
    } catch (_) {
      // Keep the latest user list if the aggregate endpoint is unavailable.
    }
  }

  Future<void> _refreshIncomingRequests() async {
    try {
      final incomingRequests = await _repository.fetchIncomingAccessRequests();
      if (!mounted) {
        return;
      }

      setState(() {
        _incomingRequests = incomingRequests;
      });
    } catch (_) {
      // Keep the latest notifications if the endpoint is unavailable.
    }
  }

  Future<void> _requestUserData(EmployeeUserActivity user) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.requestEmployeeDataAccess(targetUserId: user.userId);
      await _refreshEmployeeUsers();
      _showMessage('Permintaan akses data berhasil dikirim ke ${user.userId}.');
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _cancelUserDataRequest(EmployeeUserActivity user) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.cancelEmployeeDataAccessRequest(
        targetUserId: user.userId,
      );
      await _refreshEmployeeUsers();
      _showMessage('Permintaan akses ke ${user.userId} berhasil dibatalkan.');
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _respondToIncomingRequest({
    required DataAccessRequestNotification request,
    required bool approve,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.respondToEmployeeDataAccessRequest(
        requestId: request.id,
        approve: approve,
      );
      await _refreshIncomingRequests();
      await _refreshEmployeeUsers();
      _showMessage(
        approve
            ? 'Permintaan akses data disetujui.'
            : 'Permintaan akses data ditolak.',
      );
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _revokeIncomingRequestDecision(
    DataAccessRequestNotification request,
  ) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.revokeEmployeeDataAccessDecision(requestId: request.id);
      await _refreshIncomingRequests();
      await _refreshEmployeeUsers();
      _showMessage(
        request.status == 'approved'
            ? 'Akses lihat data berhasil dibatalkan.'
            : 'Status penolakan berhasil dibatalkan.',
      );
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _openSharedEmployees(EmployeeUserActivity user) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final sharedEmployees = await _repository.fetchSharedEmployees(
        ownerUserId: user.userId,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => SharedEmployeesDialog(
          ownerUserId: user.userId,
          employees: sharedEmployees,
        ),
      );
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _openIncomingRequestsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => IncomingRequestsDialog(
        requests: _incomingRequests,
        isBusy: _isSaving,
        onApprove: (request) async {
          Navigator.of(context).pop();
          await _respondToIncomingRequest(request: request, approve: true);
        },
        onReject: (request) async {
          Navigator.of(context).pop();
          await _respondToIncomingRequest(request: request, approve: false);
        },
        onRevokeDecision: (request) async {
          Navigator.of(context).pop();
          await _revokeIncomingRequestDecision(request);
        },
      ),
    );
  }

  String get _pageTitle {
    switch (_selectedSection) {
      case _HomeSection.dashboard:
        return 'Portal Kepegawaian';
      case _HomeSection.employees:
        return 'Data Pegawai';
      case _HomeSection.users:
        return 'List User';
    }
  }

  Widget _buildDashboardSection({
    required ColorScheme colorScheme,
    required int totalEmployees,
    required int activeEmployees,
    required int inactiveEmployees,
  }) {
    return SingleChildScrollView(
      key: const ValueKey('dashboard-section'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ringkasan portal kepegawaian. Buka Data Pegawai dari menu kiri untuk melihat, mencari, dan mengubah data.',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data pegawai sudah dipindahkan',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Semua tabel, pencarian, detail, tambah, edit, dan hapus data sekarang ada di menu kiri bagian Data Pegawai supaya halaman utama lebih rapi dan nanti mudah ditambah menu lain.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _selectSection(_HomeSection.employees),
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Buka Data Pegawai'),
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
  }

  Widget _buildEmployeesSection({
    required ColorScheme colorScheme,
    required bool isDark,
    required bool isWide,
    required List<Employee> filteredEmployees,
    required List<Employee> employees,
    required int totalEmployees,
    required int activeEmployees,
    required int inactiveEmployees,
    required int startItem,
    required int endItem,
  }) {
    return SingleChildScrollView(
      key: const ValueKey('employees-section'),
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
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outline
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x33000000)
                          : const Color(0x12000000),
                      blurRadius: isDark ? 18 : 24,
                      offset: const Offset(0, 10),
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
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 12,
                        spacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Pegawai',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Semua perubahan sekarang tersimpan di Supabase.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: isWide ? 320 : double.infinity,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari nama, NIP, jabatan, unit...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                suffixIcon: Visibility(
                                  visible: _searchQuery.isNotEmpty,
                                  maintainAnimation: true,
                                  maintainSize: true,
                                  maintainState: true,
                                  child: IconButton(
                                    onPressed: _searchController.clear,
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: isWide ? 280 : 220,
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: filteredEmployees.isEmpty
                              ? const EmptyEmployeeState()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isWide)
                                      EmployeeDataTable(
                                        employees: employees,
                                        onViewDetails: _showEmployeeDetails,
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
                                                  onViewDetails: () =>
                                                      _showEmployeeDetails(
                                                        employee,
                                                      ),
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
                                    const SizedBox(height: 16),
                                    PaginationFooter(
                                      currentPage: _currentPage,
                                      totalPages: _totalPages,
                                      startItem: startItem,
                                      endItem: endItem,
                                      totalItems: filteredEmployees.length,
                                      onPrevious: _currentPage == 0
                                          ? null
                                          : () {
                                              setState(() {
                                                _currentPage--;
                                              });
                                            },
                                      onNext: _currentPage >= _totalPages - 1
                                          ? null
                                          : () {
                                              setState(() {
                                                _currentPage++;
                                              });
                                            },
                                    ),
                                  ],
                                ),
                        ),
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
  }

  Widget _buildUsersSection({
    required ColorScheme colorScheme,
    required List<EmployeeUserActivity> employeeUsers,
  }) {
    return SingleChildScrollView(
      key: const ValueKey('users-section'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'List User',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftar user ID yang pernah menggunakan aplikasi ini dan menyimpan data pegawai.',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: employeeUsers.isEmpty
                      ? const _EmptyUserListState()
                      : Column(
                          children: employeeUsers
                              .map(
                                (user) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _UserListCard(
                                    user: user,
                                    isBusy: _isSaving,
                                    onRequestAccess: user.isCurrentUser
                                        ? null
                                        : () => _requestUserData(user),
                                    onCancelRequest:
                                        user.requestStatus == 'pending' &&
                                            !user.isCurrentUser
                                        ? () => _cancelUserDataRequest(user)
                                        : null,
                                    onViewData:
                                        user.canViewData && !user.isCurrentUser
                                        ? () => _openSharedEmployees(user)
                                        : null,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 900;
    final filteredEmployees = _filteredEmployees;
    final employees = _paginatedEmployees;
    final totalEmployees = _employees.length;
    final activeEmployees = _employees.where((item) => item.isActive).length;
    final inactiveEmployees = totalEmployees - activeEmployees;
    final dashboardTotalEmployees =
        _dashboardStats?.totalEmployees ?? totalEmployees;
    final dashboardActiveEmployees =
        _dashboardStats?.activeEmployees ?? activeEmployees;
    final dashboardInactiveEmployees =
        _dashboardStats?.inactiveEmployees ?? inactiveEmployees;
    final employeeUsers = _employeeUsers;
    final startItem = filteredEmployees.isEmpty
        ? 0
        : (_currentPage * _pageSize) + 1;
    final endItem = filteredEmployees.isEmpty
        ? 0
        : ((_currentPage * _pageSize) + employees.length).clamp(
            0,
            filteredEmployees.length,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          AppBarQuickActionsButton(
            pendingCount: _incomingRequests
                .where((item) => item.status == 'pending')
                .length,
            onOpenNotifications: _openIncomingRequestsDialog,
            onRefresh: _isLoading ? null : _loadEmployees,
            realtimeStatuses: _realtimeStatuses,
            realtimeEventCounts: _realtimeEventCounts,
            realtimeLastPayloads: _realtimeLastPayloads,
            lastRealtimeEventAt: _lastRealtimeEventAt,
          ),
        ],
      ),
      drawer: isDesktopLayout
          ? null
          : Drawer(
              child: _HomeSidebar(
                selectedSection: _selectedSection,
                onSelectSection: (section) {
                  Navigator.of(context).pop();
                  _selectSection(section);
                },
              ),
            ),
      floatingActionButton: _selectedSection == _HomeSection.employees
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : () => _openEmployeeForm(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tambah Pegawai'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _employees.isEmpty
          ? ErrorState(message: _errorMessage!, onRetry: _loadEmployees)
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide)
                          _HomeSidebar(
                            selectedSection: _selectedSection,
                            onSelectSection: _selectSection,
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _selectedSection == _HomeSection.dashboard
                                ? _buildDashboardSection(
                                    colorScheme: colorScheme,
                                    totalEmployees: dashboardTotalEmployees,
                                    activeEmployees: dashboardActiveEmployees,
                                    inactiveEmployees: dashboardInactiveEmployees,
                                  )
                                : _selectedSection == _HomeSection.employees
                                ? _buildEmployeesSection(
                                    colorScheme: colorScheme,
                                    isDark: isDark,
                                    isWide: isWide,
                                    filteredEmployees: filteredEmployees,
                                    employees: employees,
                                    totalEmployees: totalEmployees,
                                    activeEmployees: activeEmployees,
                                    inactiveEmployees: inactiveEmployees,
                                    startItem: startItem,
                                    endItem: endItem,
                                  )
                                : _buildUsersSection(
                                    colorScheme: colorScheme,
                                    employeeUsers: employeeUsers,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (_isSaving || _isRefreshingData)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar({
    required this.selectedSection,
    required this.onSelectSection,
  });

  final _HomeSection selectedSection;
  final ValueChanged<_HomeSection> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.apartment_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portal Data',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Menu utama',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SidebarItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                selected: selectedSection == _HomeSection.dashboard,
                onTap: () => onSelectSection(_HomeSection.dashboard),
              ),
              const SizedBox(height: 8),
              _SidebarItem(
                icon: Icons.badge_outlined,
                label: 'Data Pegawai',
                selected: selectedSection == _HomeSection.employees,
                onTap: () => onSelectSection(_HomeSection.employees),
              ),
              const SizedBox(height: 8),
              _SidebarItem(
                icon: Icons.groups_outlined,
                label: 'List User',
                selected: selectedSection == _HomeSection.users,
                onTap: () => onSelectSection(_HomeSection.users),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserListCard extends StatelessWidget {
  const _UserListCard({
    required this.user,
    required this.isBusy,
    this.onRequestAccess,
    this.onCancelRequest,
    this.onViewData,
  });

  final EmployeeUserActivity user;
  final bool isBusy;
  final VoidCallback? onRequestAccess;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onViewData;

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.person_pin_circle_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      user.userId,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _UserListMetaChip(
                icon: Icons.badge_outlined,
                label: 'Total Input',
                value: '${user.totalEmployees} data',
              ),
              _UserListMetaChip(
                icon: Icons.schedule_outlined,
                label: 'Input Terakhir',
                value: _formatDate(user.lastInputAt),
              ),
              _buildActionButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (user.isCurrentUser) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.person),
        label: const Text('Akun Ini'),
      );
    }

    if (user.canViewData) {
      return FilledButton.icon(
        onPressed: isBusy ? null : onViewData,
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Lihat Data'),
      );
    }

    if (user.requestStatus == 'pending') {
      return FilledButton.tonalIcon(
        onPressed: isBusy ? null : onCancelRequest,
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Batalkan Request'),
      );
    }

    final label = user.requestStatus == 'rejected'
        ? 'Request Ulang'
        : 'Request Data';

    return FilledButton.tonalIcon(
      onPressed: isBusy ? null : onRequestAccess,
      icon: const Icon(Icons.send_outlined),
      label: Text(label),
    );
  }
}

class _UserListMetaChip extends StatelessWidget {
  const _UserListMetaChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyUserListState extends StatelessWidget {
  const _EmptyUserListState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada user yang tercatat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Daftar user akan muncul setelah ada data pegawai yang tersimpan di database.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.pendingCount,
    required this.onPressed,
  });

  final int pendingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: pendingCount > 0
          ? '$pendingCount request akses masuk'
          : 'Tidak ada request masuk',
      onPressed: onPressed,
      icon: Badge.count(
        isLabelVisible: pendingCount > 0,
        count: pendingCount,
        child: const Icon(Icons.notifications_none_outlined),
      ),
    );
  }
}

class AppBarQuickActionsButton extends StatelessWidget {
  const AppBarQuickActionsButton({
    super.key,
    required this.pendingCount,
    required this.onOpenNotifications,
    required this.onRefresh,
    required this.realtimeStatuses,
    required this.realtimeEventCounts,
    required this.realtimeLastPayloads,
    required this.lastRealtimeEventAt,
  });

  final int pendingCount;
  final Future<void> Function()? onOpenNotifications;
  final Future<void> Function()? onRefresh;
  final Map<String, String> realtimeStatuses;
  final Map<String, int> realtimeEventCounts;
  final Map<String, String> realtimeLastPayloads;
  final DateTime? lastRealtimeEventAt;

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aksi cepat',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) {
            final colorScheme = Theme.of(sheetContext).colorScheme;

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aksi Cepat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notifikasi, update aplikasi, tema, dan refresh sekarang ada di satu tempat.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (kDebugMode) ...[
                        _RealtimeStatusCard(
                          statuses: realtimeStatuses,
                          eventCounts: realtimeEventCounts,
                          lastPayloads: realtimeLastPayloads,
                          lastEventAt: _formatDateTime(lastRealtimeEventAt),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (onOpenNotifications != null)
                            _QuickActionTile(
                              child: NotificationBellButton(
                                pendingCount: pendingCount,
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await onOpenNotifications!();
                                },
                              ),
                              label: 'Notifikasi',
                            ),
                          const _QuickActionTile(
                            child: UpdateActionButton(),
                            label: 'Update',
                          ),
                          const _QuickActionTile(
                            child: ThemeModeButton(),
                            label: 'Tema',
                          ),
                          _QuickActionTile(
                            child: IconButton(
                              tooltip: 'Refresh',
                              onPressed: onRefresh == null
                                  ? null
                                  : () async {
                                      Navigator.of(sheetContext).pop();
                                      await onRefresh!();
                                    },
                              icon: const Icon(Icons.refresh),
                            ),
                            label: 'Refresh',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      icon: Badge.count(
        isLabelVisible: pendingCount > 0,
        count: pendingCount,
        child: const Icon(Icons.tune_outlined),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.child,
    required this.label,
  });

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.primary;

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: IconTheme(
        data: IconThemeData(color: iconColor, size: 24),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: iconColor,
              iconSize: 24,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RealtimeStatusCard extends StatelessWidget {
  const _RealtimeStatusCard({
    required this.statuses,
    required this.eventCounts,
    required this.lastPayloads,
    required this.lastEventAt,
  });

  final Map<String, String> statuses;
  final Map<String, int> eventCounts;
  final Map<String, String> lastPayloads;
  final String lastEventAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget statusRow(String label, String key) {
      final value = statuses[key] ?? '-';
      final isHealthy = value == 'subscribed';
      final count = eventCounts[key] ?? 0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHealthy ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: isHealthy ? Colors.green.shade600 : colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '$value | event $count'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Realtime',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          statusRow('Employees', 'employees'),
          const SizedBox(height: 4),
          Text(
            'Payload: ${lastPayloads['employees'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          statusRow('Portal Hub', 'hub'),
          const SizedBox(height: 4),
          Text(
            'Payload: ${lastPayloads['hub'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          statusRow('Access Requester', 'requester'),
          const SizedBox(height: 4),
          Text(
            'Payload: ${lastPayloads['requester'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          statusRow('Access Target', 'target'),
          const SizedBox(height: 4),
          Text(
            'Payload: ${lastPayloads['target'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(
            'Event terakhir: $lastEventAt',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class IncomingRequestsDialog extends StatelessWidget {
  const IncomingRequestsDialog({
    super.key,
    required this.requests,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onRevokeDecision,
  });

  final List<DataAccessRequestNotification> requests;
  final bool isBusy;
  final Future<void> Function(DataAccessRequestNotification request) onApprove;
  final Future<void> Function(DataAccessRequestNotification request) onReject;
  final Future<void> Function(DataAccessRequestNotification request)
      onRevokeDecision;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingRequests = requests.where((item) => item.status == 'pending');
    final approvedRequests = requests
        .where((item) => item.status == 'approved');
    final rejectedRequests = requests
        .where((item) => item.status == 'rejected');

    return AlertDialog(
      title: const Text('Request Masuk'),
      content: SizedBox(
        width: 620,
        child: requests.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada request atau akses data yang tercatat.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pendingRequests.isNotEmpty) ...[
                      const _RequestSectionTitle(
                        title: 'Request Menunggu',
                        subtitle:
                            'User yang sedang menunggu keputusan accept atau tolak.',
                      ),
                      const SizedBox(height: 10),
                      ...pendingRequests.map(
                        (request) => _IncomingRequestCard(
                          request: request,
                          isBusy: isBusy,
                          onApprove: () => onApprove(request),
                          onReject: () => onReject(request),
                        ),
                      ),
                    ],
                    if (approvedRequests.isNotEmpty) ...[
                      if (pendingRequests.isNotEmpty) const SizedBox(height: 10),
                      const _RequestSectionTitle(
                        title: 'Sudah Diberi Akses',
                        subtitle:
                            'Daftar user yang saat ini boleh melihat data Anda.',
                      ),
                      const SizedBox(height: 10),
                      ...approvedRequests.map(
                        (request) => _ManagedAccessCard(
                          request: request,
                          isBusy: isBusy,
                          buttonLabel: 'Batalkan Akses',
                          onPressed: () => onRevokeDecision(request),
                        ),
                      ),
                    ],
                    if (rejectedRequests.isNotEmpty) ...[
                      if (pendingRequests.isNotEmpty || approvedRequests.isNotEmpty)
                        const SizedBox(height: 10),
                      const _RequestSectionTitle(
                        title: 'Request Ditolak',
                        subtitle:
                            'Riwayat penolakan yang masih tersimpan dan bisa dibatalkan.',
                      ),
                      const SizedBox(height: 10),
                      ...rejectedRequests.map(
                        (request) => _ManagedAccessCard(
                          request: request,
                          isBusy: isBusy,
                          buttonLabel: 'Batalkan Penolakan',
                          onPressed: () => onRevokeDecision(request),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _RequestSectionTitle extends StatelessWidget {
  const _RequestSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final DataAccessRequestNotification request;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User ${request.requesterUserId} meminta akses data Anda.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk: ${_formatDate(request.createdAt)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onApprove,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept'),
              ),
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onReject,
                icon: const Icon(Icons.close),
                label: const Text('Tolak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagedAccessCard extends StatelessWidget {
  const _ManagedAccessCard({
    required this.request,
    required this.isBusy,
    required this.buttonLabel,
    required this.onPressed,
  });

  final DataAccessRequestNotification request;
  final bool isBusy;
  final String buttonLabel;
  final VoidCallback onPressed;

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isApproved = request.status == 'approved';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.requesterUserId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip(
                isActive: isApproved,
                activeLabel: 'Diizinkan',
                inactiveLabel: 'Ditolak',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Diproses: ${_formatDate(request.respondedAt)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: isBusy ? null : onPressed,
            icon: Icon(
              isApproved ? Icons.block_outlined : Icons.restore_outlined,
            ),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class SharedEmployeesDialog extends StatelessWidget {
  const SharedEmployeesDialog({
    super.key,
    required this.ownerUserId,
    required this.employees,
  });

  final String ownerUserId;
  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Data Pegawai User'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                ownerUserId,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (employees.isEmpty)
                const Text('Belum ada data yang bisa ditampilkan.')
              else
                Column(
                  children: employees
                      .map(
                        (employee) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EmployeeListCard(
                            employee: employee,
                            onViewDetails: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) =>
                                    EmployeeDetailDialog(employee: employee),
                              );
                            },
                            onEdit: () {},
                            onDelete: () {},
                            showActions: false,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Text(
          'Menampilkan $startItem-$endItem dari $totalItems data',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Halaman ${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Sebelumnya'),
            ),
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Berikutnya'),
            ),
          ],
        ),
      ],
    );
  }
}

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDark ? 'Pindah ke Light Mode' : 'Pindah ke Dark Mode',
      onPressed: () {
        final adaptiveTheme = AdaptiveTheme.of(context);
        if (isDark) {
          adaptiveTheme.setLight();
        } else {
          adaptiveTheme.setDark();
        }
      },
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat data dari Supabase',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmployeeDataTable extends StatelessWidget {
  const EmployeeDataTable({
    super.key,
    required this.employees,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Employee> employees;
  final Future<void> Function(Employee employee) onViewDetails;
  final Future<void> Function({Employee? employee}) onEdit;
  final Future<void> Function(Employee employee) onDelete;

  static const int _photoFlex = 2;
  static const int _nameFlex = 5;
  static const int _nipFlex = 3;
  static const int _positionFlex = 4;
  static const int _departmentFlex = 3;
  static const int _contactFlex = 5;
  static const int _statusFlex = 3;
  static const int _actionFlex = 3;

  Widget _singleLineText(String value, {FontWeight? fontWeight, Color? color}) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: fontWeight,
        color: color,
        height: 1.2,
      ),
    );
  }

  Widget _headerCell(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _dataCell({
    required int flex,
    required Widget child,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Align(alignment: alignment, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? colorScheme.outline : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                _headerCell('Foto', _photoFlex),
                _headerCell('Nama', _nameFlex),
                _headerCell('NIP', _nipFlex),
                _headerCell('Jabatan', _positionFlex),
                _headerCell('Unit', _departmentFlex),
                _headerCell('Kontak', _contactFlex),
                _headerCell('Status', _statusFlex),
                _headerCell('Aksi', _actionFlex),
              ],
            ),
          ),
          ...employees.asMap().entries.map((entry) {
            final index = entry.key;
            final employee = entry.value;
            final isLast = index == employees.length - 1;

            return InkWell(
              onTap: () => onViewDetails(employee),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark
                                ? colorScheme.outline.withValues(alpha: 0.35)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    _dataCell(
                      flex: _photoFlex,
                      child: EmployeeAvatarButton(
                        name: employee.name,
                        photoUrl: employee.photoUrl,
                        radius: 20,
                      ),
                    ),
                    _dataCell(
                      flex: _nameFlex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _singleLineText(
                            employee.name,
                            fontWeight: FontWeight.w700,
                          ),
                          _singleLineText(
                            employee.address,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    _dataCell(
                      flex: _nipFlex,
                      child: _singleLineText(employee.nip),
                    ),
                    _dataCell(
                      flex: _positionFlex,
                      child: _singleLineText(employee.position),
                    ),
                    _dataCell(
                      flex: _departmentFlex,
                      child: _singleLineText(employee.department),
                    ),
                    _dataCell(
                      flex: _contactFlex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _singleLineText(employee.email),
                          _singleLineText(
                            employee.phone,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    _dataCell(
                      flex: _statusFlex,
                      child: StatusChip(isActive: employee.isActive),
                    ),
                    _dataCell(
                      flex: _actionFlex,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit',
                              onPressed: () => onEdit(employee: employee),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Hapus',
                              onPressed: () => onDelete(employee),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class EmployeeListCard extends StatelessWidget {
  const EmployeeListCard({
    super.key,
    required this.employee,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
  });

  final Employee employee;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onViewDetails,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162033) : const Color(0xFFF9FCFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? colorScheme.outline : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmployeeAvatarButton(
                    name: employee.name,
                    photoUrl: employee.photoUrl,
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
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              if (showActions) ...[
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
            ],
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class EmployeeDetailDialog extends StatelessWidget {
  const EmployeeDetailDialog({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Detail Pegawai'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmployeeAvatarButton(
                    name: employee.name,
                    photoUrl: employee.photoUrl,
                    radius: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${employee.position} • ${employee.department}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(isActive: employee.isActive),
                ],
              ),
              const SizedBox(height: 18),
              _InfoRow(label: 'NIP', value: employee.nip),
              _InfoRow(label: 'Email', value: employee.email),
              _InfoRow(label: 'Telepon', value: employee.phone),
              _InfoRow(label: 'Alamat', value: employee.address),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class EmployeePhotoViewerDialog extends StatelessWidget {
  const EmployeePhotoViewerDialog({
    super.key,
    required this.name,
    required this.photoUrl,
  });

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Foto profil gagal dimuat.',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeAvatarButton extends StatelessWidget {
  const EmployeeAvatarButton({
    super.key,
    required this.name,
    required this.photoUrl,
    this.photoBytes,
    this.radius = 22,
  });

  final String name;
  final String photoUrl;
  final Uint8List? photoBytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoBytes != null || photoUrl.trim().isNotEmpty;

    if (!hasPhoto) {
      return EmployeeAvatar(
        name: name,
        photoUrl: photoUrl,
        photoBytes: photoBytes,
        radius: radius,
      );
    }

    return Tooltip(
      message: 'Lihat foto penuh',
      child: InkWell(
        borderRadius: BorderRadius.circular(radius + 6),
        onTap: () {
          final trimmedPhotoUrl = photoUrl.trim();
          if (trimmedPhotoUrl.isEmpty) {
            return;
          }

          showDialog<void>(
            context: context,
            builder: (context) => EmployeePhotoViewerDialog(
              name: name,
              photoUrl: trimmedPhotoUrl,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: EmployeeAvatar(
            name: name,
            photoUrl: photoUrl,
            photoBytes: photoBytes,
            radius: radius,
          ),
        ),
      ),
    );
  }
}

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.photoBytes,
    this.radius = 22,
  });

  final String name;
  final String photoUrl;
  final Uint8List? photoBytes;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = photoUrl.trim();
    final hasPhoto = trimmedPhotoUrl.isNotEmpty;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFCCFBF1),
      foregroundColor: const Color(0xFF115E59),
      foregroundImage: photoBytes != null
          ? MemoryImage(photoBytes!)
          : hasPhoto
          ? NetworkImage(trimmedPhotoUrl)
          : null,
      onForegroundImageError: photoBytes == null && hasPhoto ? (_, _) {} : null,
      child: Text(initial.toUpperCase()),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.isActive,
    this.activeLabel = 'Aktif',
    this.inactiveLabel = 'Nonaktif',
  });

  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text(isActive ? activeLabel : inactiveLabel),
      labelStyle: TextStyle(
        color: isActive
            ? (isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534))
            : (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E)),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: isActive
          ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
          : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162033) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? colorScheme.outline : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada data pegawai di database',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan pegawai pertama untuk mulai membangun portal kepegawaian.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class EmployeeFormDialog extends StatefulWidget {
  const EmployeeFormDialog({super.key, this.employee, required this.userId});

  final Employee? employee;
  final String userId;

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeRepository _repository = const EmployeeRepository();
  late final TextEditingController _nameController;
  late final TextEditingController _nipController;
  late final TextEditingController _positionController;
  late final TextEditingController _departmentController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  late String _photoUrl;
  late bool _isActive;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;

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
    _photoUrl = employee?.photoUrl ?? '';
    _isActive = employee?.isActive ?? true;
    _nameController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshPreview);
    _nameController.dispose();
    _nipController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto || _isSubmitting) {
      return;
    }

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      if (file.bytes == null) {
        throw Exception('File foto tidak terbaca.');
      }

      setState(() {
        _selectedPhotoBytes = file.bytes!;
        _selectedPhotoName = file.name;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
      _photoUrl = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final existing = widget.employee;
    final now = DateTime.now().toUtc();
    var photoUrl = _photoUrl;

    try {
      if (_selectedPhotoBytes != null && _selectedPhotoName != null) {
        photoUrl = await _repository.uploadEmployeePhoto(
          bytes: _selectedPhotoBytes!,
          fileName: _selectedPhotoName!,
        );
      }
    } on StorageException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload foto gagal: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final employee = Employee(
      id: existing?.id ?? '',
      userId: existing?.userId ?? widget.userId,
      name: _nameController.text.trim(),
      photoUrl: photoUrl,
      nip: _nipController.text.trim(),
      position: _positionController.text.trim(),
      department: _departmentController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      isActive: _isActive,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (!mounted) {
      return;
    }

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
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: EmployeeAvatar(
                    name: _nameController.text.trim().isEmpty
                        ? 'Pegawai'
                        : _nameController.text.trim(),
                    photoUrl: _photoUrl,
                    photoBytes: _selectedPhotoBytes,
                    radius: 30,
                  ),
                ),
                _buildField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.badge_outlined,
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto Pegawai',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedPhotoName ??
                            (_photoUrl.isEmpty
                                ? 'Belum ada foto dipilih'
                                : 'Foto tersimpan dan akan dipakai lagi'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickPhoto,
                              icon: _isPickingPhoto
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: Text(
                                _selectedPhotoBytes != null ||
                                        _photoUrl.isNotEmpty
                                    ? 'Ganti Foto'
                                    : 'Pilih Foto',
                              ),
                            ),
                          ),
                          if (_selectedPhotoBytes != null ||
                              _photoUrl.isNotEmpty)
                            const SizedBox(width: 12),
                          if (_selectedPhotoBytes != null ||
                              _photoUrl.isNotEmpty)
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _isSubmitting ? null : _removePhoto,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Hapus Foto'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
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
                  validator: (value) => null,
                ),
                _buildField(
                  controller: _addressController,
                  label: 'Alamat',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  validator: (value) => null,
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah'),
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
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label wajib diisi';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
