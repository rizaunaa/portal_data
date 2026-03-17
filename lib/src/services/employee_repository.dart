import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
import '../supabase_bootstrap.dart';

class EmployeeRepository {
  const EmployeeRepository();

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
}
