import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
import '../models/inventory_item.dart';
import '../supabase_bootstrap.dart';

class EmployeeDashboardStats {
  const EmployeeDashboardStats({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
  });

  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;

  factory EmployeeDashboardStats.fromMap(Map<String, dynamic> map) {
    int parseCount(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse('$value') ?? 0;
    }

    return EmployeeDashboardStats(
      totalEmployees: parseCount(map['total_employees']),
      activeEmployees: parseCount(map['active_employees']),
      inactiveEmployees: parseCount(map['inactive_employees']),
    );
  }
}

class EmployeeUserActivity {
  const EmployeeUserActivity({
    required this.userId,
    required this.totalEmployees,
    this.lastInputAt,
    this.requestStatus,
    this.canViewData = false,
    this.isCurrentUser = false,
  });

  final String userId;
  final int totalEmployees;
  final DateTime? lastInputAt;
  final String? requestStatus;
  final bool canViewData;
  final bool isCurrentUser;

  factory EmployeeUserActivity.fromMap(Map<String, dynamic> map) {
    int parseCount(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse('$value') ?? 0;
    }

    final lastInputAtValue = map['last_input_at'];

    return EmployeeUserActivity(
      userId: map['user_id'] as String? ?? '',
      totalEmployees: parseCount(map['total_employees']),
      lastInputAt: lastInputAtValue == null
          ? null
          : DateTime.tryParse(lastInputAtValue as String),
      requestStatus: map['request_status'] as String?,
      canViewData: map['can_view_data'] as bool? ?? false,
      isCurrentUser: map['is_current_user'] as bool? ?? false,
    );
  }
}

class DataAccessRequestNotification {
  const DataAccessRequestNotification({
    required this.id,
    required this.requesterUserId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String requesterUserId;
  final String targetUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory DataAccessRequestNotification.fromMap(Map<String, dynamic> map) {
    return DataAccessRequestNotification(
      id: map['id'] as String? ?? '',
      requesterUserId: map['requester_user_id'] as String? ?? '',
      targetUserId: map['target_user_id'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      respondedAt: map['responded_at'] == null
          ? null
          : DateTime.tryParse(map['responded_at'] as String),
    );
  }
}

class EmployeeRepository {
  const EmployeeRepository();

  static const String _employeePhotosBucket = 'employee-photos';

  User? get currentUser => supabaseClient.auth.currentUser;

  Future<void> ensureSignedIn() async {
    if (currentUser != null) {
      return;
    }

    await supabaseClient.auth.signInAnonymously();
  }

  Future<List<Employee>> fetchEmployees() async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('employees')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => Employee.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryItem>> fetchInventoryItems() async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('inventory_items')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<EmployeeDashboardStats> fetchDashboardStats() async {
    await ensureSignedIn();

    final response = await supabaseClient.rpc('employee_dashboard_totals');

    return EmployeeDashboardStats.fromMap(response as Map<String, dynamic>);
  }

  Future<List<EmployeeUserActivity>> fetchEmployeeUsers() async {
    await ensureSignedIn();

    final response = await supabaseClient.rpc('employee_users_list');

    return (response as List<dynamic>)
        .map((item) => EmployeeUserActivity.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestEmployeeDataAccess({required String targetUserId}) async {
    await ensureSignedIn();
    await supabaseClient.rpc(
      'request_employee_data_access',
      params: {'target_user_id_input': targetUserId},
    );
  }

  Future<void> cancelEmployeeDataAccessRequest({
    required String targetUserId,
  }) async {
    await ensureSignedIn();
    await supabaseClient.rpc(
      'cancel_employee_data_access_request',
      params: {'target_user_id_input': targetUserId},
    );
  }

  Future<List<DataAccessRequestNotification>> fetchIncomingAccessRequests() async {
    await ensureSignedIn();

    final response = await supabaseClient.rpc('incoming_employee_access_requests');

    return (response as List<dynamic>)
        .map(
          (item) => DataAccessRequestNotification.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> respondToEmployeeDataAccessRequest({
    required String requestId,
    required bool approve,
  }) async {
    await ensureSignedIn();
    await supabaseClient.rpc(
      'respond_employee_data_access_request',
      params: {
        'request_id_input': requestId,
        'approve_input': approve,
      },
    );
  }

  Future<void> revokeEmployeeDataAccessDecision({
    required String requestId,
  }) async {
    await ensureSignedIn();
    await supabaseClient.rpc(
      'revoke_employee_data_access_decision',
      params: {'request_id_input': requestId},
    );
  }

  Future<List<Employee>> fetchSharedEmployees({required String ownerUserId}) async {
    await ensureSignedIn();

    final response = await supabaseClient.rpc(
      'shared_employee_data',
      params: {'owner_user_id_input': ownerUserId},
    );

    return (response as List<dynamic>)
        .map((item) => Employee.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> createEmployee(Employee employee) async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('employees')
        .insert(employee.toInsertMap())
        .select()
        .single();

    return Employee.fromMap(response);
  }

  Future<Employee> updateEmployee(Employee employee) async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('employees')
        .update(employee.toUpdateMap())
        .eq('id', employee.id)
        .select()
        .single();

    return Employee.fromMap(response);
  }

  Future<void> deleteEmployee(String id) async {
    await ensureSignedIn();
    await supabaseClient.from('employees').delete().eq('id', id);
  }

  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('inventory_items')
        .insert(item.toInsertMap())
        .select()
        .single();

    return InventoryItem.fromMap(response);
  }

  Future<InventoryItem> updateInventoryItem(InventoryItem item) async {
    await ensureSignedIn();

    final response = await supabaseClient
        .from('inventory_items')
        .update(item.toUpdateMap())
        .eq('id', item.id)
        .select()
        .single();

    return InventoryItem.fromMap(response);
  }

  Future<void> deleteInventoryItem(String id) async {
    await ensureSignedIn();
    await supabaseClient.from('inventory_items').delete().eq('id', id);
  }

  Future<String> uploadEmployeePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await ensureSignedIn();

    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('User belum terautentikasi.');
    }

    final safeFileName = fileName.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final objectPath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final contentType = lookupMimeType(fileName, headerBytes: bytes);

    await supabaseClient.storage
        .from(_employeePhotosBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return supabaseClient.storage
        .from(_employeePhotosBucket)
        .getPublicUrl(objectPath);
  }

  Future<String> uploadInventoryPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return uploadEmployeePhoto(bytes: bytes, fileName: fileName);
  }
}
