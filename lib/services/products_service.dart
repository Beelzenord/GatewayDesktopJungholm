import 'package:supabase_flutter/supabase_flutter.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final String status;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
    );
  }
}

class ProductsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all active products
  Future<List<Product>> getActiveProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id, name, description, status')
          .eq('status', 'active')
          .order('name');

      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }
}



