import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_sidebar.dart';
import '../../providers/menu_provider.dart';

class MenuManagement extends StatefulWidget {
  const MenuManagement({super.key});

  @override
  State<MenuManagement> createState() => _MenuManagementState();
}

class _MenuManagementState extends State<MenuManagement> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).loadProducts();
    });
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    // For simplicity, category is a string. You can use a dropdown if you have categories loaded.
    final categoryController = TextEditingController(text: product?['category_id']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '\$'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category ID', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final provider = Provider.of<MenuProvider>(context, listen: false);
                try {
                  final data = {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'category_id': int.tryParse(categoryController.text) ?? 1,
                    'image_url': imageUrlController.text,
                    'is_active': true,
                  };
                  if (product == null) {
                    await provider.createProduct(data);
                  } else {
                    await provider.updateProduct(product['id'], data);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(product == null ? 'Product added' : 'Product updated'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(product == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    return Scaffold(
      drawer: const AdminSidebar(selected: 'products'),
      appBar: AppBar(title: const Text('Menu Management')),
      body: menuProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Products', style: Theme.of(context).textTheme.titleLarge),
                      ElevatedButton.icon(
                        onPressed: () => _showProductDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: menuProvider.products.length,
                      itemBuilder: (context, index) {
                        final product = menuProvider.products[index];
                        return Card(
                          child: ListTile(
                            leading: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                                ? Image.network(product['image_url'], width: 48, height: 48, fit: BoxFit.cover)
                                : const Icon(Icons.fastfood, size: 48),
                            title: Text(product['name']),
                            subtitle: Text(product['description'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${product['price'].toStringAsFixed(2)}'),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showProductDialog(product: product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final provider = Provider.of<MenuProvider>(context, listen: false);
                                    try {
                                      await provider.deleteProduct(product['id']);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.green),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 