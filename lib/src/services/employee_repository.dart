import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
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

  Future<EmployeeDashboardStats> fetchDashboardStats() async {
    await ensureSignedIn();

    final response = await supabaseClient.rpc('employee_dashboard_totals');

    return EmployeeDashboardStats.fromMap(response as Map<String, dynamic>);
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
}
