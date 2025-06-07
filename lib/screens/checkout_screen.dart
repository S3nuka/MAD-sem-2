import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'credit_card';
  bool _isPlacingOrder = false;
  String? _orderError;
  bool _orderSuccess = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _placeOrder(CartProvider cart, OrderProvider orderProvider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isPlacingOrder = true;
      _orderError = null;
      _orderSuccess = false;
    });
    try {
      final cartItems = cart.items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList();
      await orderProvider.createOrder(
        cartItems: cartItems,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
      );
      setState(() {
        _orderSuccess = true;
      });
      cart.clearCart();
      if (mounted) {
        // Show SnackBar and redirect to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Use GoRouter to go to home
            context.go('/');
          }
        });
      }
    } catch (e) {
      setState(() {
        _orderError = e.toString();
      });
    } finally {
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final items = cart.items;
    final subtotal = cart.totalPrice;
    final tax = subtotal * 0.1;
    final total = subtotal + tax;

    return AppScaffold(
      title: 'Checkout',
      child: items.isEmpty
          ? Center(child: Text('Your cart is empty.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_orderSuccess)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Order placed successfully!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (_orderError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _orderError!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact & Delivery Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Phone number is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 24),
                        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            RadioListTile<String>(
                              value: 'credit_card',
                              groupValue: _paymentMethod,
                              onChanged: (value) => setState(() => _paymentMethod = value!),
                              title: const Text('Credit Card'),
                            ),
                            RadioListTile<String>(
                              value: 'paypal',
                              groupValue: _paymentMethod,
                              onChanged: (value) => setState(() => _paymentMethod = value!),
                              title: const Text('PayPal'),
                            ),
                            RadioListTile<String>(
                              value: 'cash',
                              groupValue: _paymentMethod,
                              onChanged: (value) => setState(() => _paymentMethod = value!),
                              title: const Text('Cash on Delivery'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        ...items.map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: Text('Qty: ${item.quantity}'),
                              trailing: Text('\$' + (item.price * item.quantity).toStringAsFixed(2)),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('\$' + subtotal.toStringAsFixed(2)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax (10%)'),
                            Text('\$' + tax.toStringAsFixed(2)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$' + total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPlacingOrder || _orderSuccess
                                ? null
                                : () => _placeOrder(cart, orderProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isPlacingOrder
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Place Order'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 