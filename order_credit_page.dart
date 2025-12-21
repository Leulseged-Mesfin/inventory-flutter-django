import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:inventory_management_app/screens/credit/add_order_page.dart';
import 'package:inventory_management_app/screens/credit/edit_order_item_page.dart';
import 'package:inventory_management_app/screens/credit/order_items_page.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management_app/base/res/styles/app_styles.dart';
import 'package:inventory_management_app/base/utils/auth_helper.dart'; // Import your helper

class CreditListPage extends StatefulWidget {
  const CreditListPage({super.key});

  @override
  State<CreditListPage> createState() => _CreditListPageState();
}

class _CreditListPageState extends State<CreditListPage> {
  bool isLoading = true;
  bool _submitting = false;
  List<dynamic> items = [];

  static const String ordersEndpoint =
      'http://10.0.2.2:8000/api/inventory/orders-credit';
  static const String ordersCreditEndpoint =
      'http://10.0.2.2:8000/api/inventory/orders';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> _showUpdateStatusDialog(BuildContext context, String id) async {
    String? selectedStatus = 'Done'; // Default selected value

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Done', child: Text('Done')),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancel'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                updateStatus(id, selectedStatus!); // Update the status
                // fetchData();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateStatus(String id, String newStatus) async {
    // if (!_formKey.currentState!.validate()) return;
    final accessToken = await AuthHelper.getAccessToken();
    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are not authenticated. Please log in."),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final orderId = id?.toString();
    if (orderId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order id missing')));
      setState(() => _submitting = false);
      return;
    }

    final payload = {'status': newStatus};

    try {
      final uri = Uri.parse('$ordersEndpoint/$orderId');
      // debugPrint('PATCH $uri body: ${jsonEncode(payload)}');

      final resp = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
      // debugPrint('Edit order response: ${resp.statusCode} ${resp.body}');
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order updated',
              style: TextStyle(color: Colors.green),
            ),
          ),
        );
        fetchData();
      } else {
        String msg = 'Failed to update (${resp.statusCode})';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _showUpdatePaymentStatusDialog(
    BuildContext context,
    String id,
    String currentPaymentStatus,
    String currentPaidAmount,
  ) async {
    String? selectedPaymentStatus = currentPaymentStatus;
    TextEditingController paidAmountController = TextEditingController(
      text: currentPaidAmount,
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          // margin: const EdgeInsets.all(2.0),
          padding: const EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width * 0.8,
          // width: 700,
          child: AlertDialog(
            title: const Text('Update Payment Status'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPaymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Unpaid',
                          child: Text('Unpaid'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPaymentStatus = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: paidAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        border: OutlineInputBorder(),
                        // contentPadding: EdgeInsets.all(12.0),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  updatePaymentStatus(
                    id,
                    selectedPaymentStatus!,
                    paidAmountController.text,
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  // void updatePaymentStatus(
  //   String id,
  //   String newPaymentStatus,
  //   String newPaidAmount,
  // ) {
  //   // Here you would typically make an API call to update the payment status and paid amount
  //   print(
  //     'Updating payment status for ID: $id to $newPaymentStatus with paid amount $newPaidAmount',
  //   );
  //   // Example API call (pseudo-code)
  //   // apiClient.updatePaymentStatus(id: id, paymentStatus: newPaymentStatus, paidAmount: newPaidAmount).then((response) {
  //   //   if (response.statusCode == 200) {
  //   //     fetchData(); // Refresh the data
  //   //   } else {
  //   //     print('Failed to update payment status');
  //   //   }
  //   // }).catchError((error) {
  //   //   print('Error updating payment status: $error');
  //   // });
  // }

  Future<void> updatePaymentStatus(
    String id,
    String newPaymentStatus,
    String newPaidAmount,
  ) async {
    // Get the access token
    final accessToken = await AuthHelper.getAccessToken();
    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are not authenticated. Please log in."),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final orderId = id.toString();

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order id missing')));
      setState(() => _submitting = false);
      return;
    }

    // Validate paid amount is a valid number
    double? paidAmount;
    try {
      paidAmount = double.parse(newPaidAmount);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid paid amount')));
      setState(() => _submitting = false);
      return;
    }

    // Prepare the payload
    final payload = {
      'payment_status': newPaymentStatus,
      'paid_amount': paidAmount,
    };

    try {
      final uri = Uri.parse('$ordersCreditEndpoint/$orderId');
      print(uri);

      final resp = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment status updated',
              style: TextStyle(color: Colors.green),
            ),
          ),
        );
        fetchData(); // Refresh the data
      } else {
        String msg =
            'Failed to update payment status (${resp.statusCode}): ${resp.body}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _extractPaymentStatus(Map<String, dynamic> item) {
    return item['payment_status']?.toString() ?? 'Pending';
  }

  String _extractPaidAmount(Map<String, dynamic> item) {
    return item['paid_amount']?.toString() ?? '0.0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(title: const Center(child: Text('Credit List'))),
      body: Visibility(
        visible: isLoading,
        replacement: RefreshIndicator(
          onRefresh: fetchData,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id']?.toString() ?? '';
              String receipt = _extractReceipt(item);
              String credit = _extractCredit(item);
              String customerName = _extractCustomerName(item);
              // String orderDate = _extractOrderDate(item);
              String status = _extractStatus(item);
              String totalAmount = _extractTotalAmount(item);

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 12.0,
                ),
                color: Colors.white,
                elevation: 3,

                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.only(right: 16.0),
                            child: InkWell(
                              onTap: () => navigateToOrderItemPage(id: id),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt: ${receipt}',
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${status}',
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Amount: ${totalAmount}',
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ],
                          ),
                          Text(
                            'Credit: ${credit}',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              return PopupMenuButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: Colors.grey[500],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    navigateToEditPage(item);
                                  } else if (value == 'delete') {
                                    deleteById(id);
                                  } else if (value == 'status') {
                                    // Handle status
                                    _showUpdateStatusDialog(context, id);
                                  } else if (value == 'payment status') {
                                    // Handle payment status
                                    String paymentStatus =
                                        _extractPaymentStatus(item);
                                    String paidAmount = _extractPaidAmount(
                                      item,
                                    );
                                    _showUpdatePaymentStatusDialog(
                                      context,
                                      id,
                                      paymentStatus,
                                      paidAmount,
                                    );
                                  } else if (value == 'log') {
                                    // Handle log
                                  } else if (value == 'receipt') {
                                    // Handle receipt
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'status',
                                    child: Text('Status'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'payment status',
                                    child: Text('Payment status'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'log',
                                    child: Text('Log'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'receipt',
                                    child: Text('Receipt'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_create_fab',
        onPressed: navigateToAddOrderPage,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add), // Icon
        label: const Text(
          'Add Credit',
          style: TextStyle(fontSize: 14),
        ), // Text label
      ),
    );
  }

  void navigateToOrderItemPage({required String id}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderItemListPage(id: id), // Pass the id here
      ),
    );
  }

  Future<void> navigateToEditPage(Map item) async {
    final route = MaterialPageRoute(
      builder: (context) {
        return EditOrderPage(order: item);
      },
    );
    // await returns true when the edit page signals success
    final result = await Navigator.push(context, route);
    if (result == true) {
      setState(() {
        isLoading = true;
      });
      fetchData();
    }
  }

  Future<void> navigateToAddOrderPage() async {
    final route = MaterialPageRoute(
      builder: (context) {
        return const AddOrderPage();
      },
    );
    await Navigator.push(context, route);
    setState(() {
      isLoading = true;
    });
    fetchData();
  }

  Future<void> deleteById(id) async {
    if (id == null || id.toString().isEmpty) {
      errorMessage('Invalid id');
      return;
    }
    final uri = Uri.parse('$ordersEndpoint$id/');
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      final filtered = items
          .where((item) => item['id'].toString() != id.toString())
          .toList();
      setState(() {
        items = filtered;
      });
      successMessage("Order deleted successfully");
    } else {
      errorMessage("Failed to delete order (${response.statusCode})");
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse(ordersEndpoint);
      final response = await http.get(uri);
      // debugPrint('Orders fetch status: ${response.statusCode}');
      // debugPrint('Orders fetch body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> result = [];

        if (body is List) {
          result = body;
        } else if (body is Map && body['results'] is List) {
          result = List<dynamic>.from(body['results']);
        } else if (body is Map && body['data'] is List) {
          result = List<dynamic>.from(body['data']);
        } else {
          // if single object, wrap it
          result = [body];
        }

        setState(() {
          items = result;
          // print(items);
        });
      } else {
        errorMessage('Failed to load orders (${response.statusCode})');
      }
    } catch (e) {
      errorMessage('Network error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // }
  String _extractCustomerName(dynamic item) {
    try {
      final customer = item['customer'];
      if (customer is Map) {
        return (customer['name'] ?? 'Anonymos').toString();
      }
      // sometimes backend returns product_name at root
      if (item['customer_name'] != null)
        return item['customer_name'].toString();
      // fallback to product_id if no name available
      if (item['customer'] != null)
        return 'customer #${item['customer'].toString()}';
    } catch (_) {}
    return 'Anonymos';
  }

  String _extractReceipt(dynamic item) {
    try {
      final receipt = item['receipt'];
      return (receipt ?? 'Unnamed Receipt').toString();
    } catch (_) {}
    return 'Unnamed Receipt';
  }

  String _extractCredit(dynamic item) {
    try {
      final credit = item['credit'];
      return (credit ?? 'Unnamed credit').toString();
    } catch (_) {}
    return 'Unnamed credit';
  }

  String _extractOrderDate(dynamic item) {
    try {
      final order_date = item['order_date'];
      return (order_date ?? 'Unnamed order_date').toString();
    } catch (_) {}
    return 'Date not available';
  }

  String _extractStatus(dynamic item) {
    try {
      final status = item['status'];
      return (status ?? 'Unnamed status').toString();
    } catch (_) {}
    return 'Unnamed Receipt';
  }

  String _extractTotalAmount(dynamic item) {
    try {
      final total_amount = item['total_amount'];
      return (total_amount ?? 'Unnamed total_amount').toString();
    } catch (_) {}
    return 'Unnamed Receipt';
  }

  void successMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void errorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
