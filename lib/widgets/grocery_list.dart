import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});
  
  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  Widget? content;
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  Widget? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-be8b3-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );
    
    try {
      final response = await http.get(url);

      if (response.body == 'null') {
        print('response is null');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final Map<String, dynamic> listData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category =
            categories.entries
                .firstWhere(
                  (catItem) => catItem.value.title == item.value['category'],
                )
                .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('response is error');
      setState(() {
        _error = Center(child: Text('Something went wrong. Please try again later.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),);
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));

    if (newItem == null){
      return;
    }
    setState(() {

      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    final url = Uri.https(
      'flutter-prep-be8b3-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    http.delete(url);

    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) {
      print(_error == null);
      if (_isLoading) {
        content = const Center(child: CircularProgressIndicator(),);
      }else{
        content = Center(
          child: Text(
            'No item added',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      }
    }else{
      print('error found');
      content = _error;
      print('content: $content');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Groceries',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body:
          _groceryItems.isEmpty
              ? content
              : ListView(
                children: [
                  for (final item in _groceryItems)
                    Dismissible(
                      key: ValueKey(item),
                      onDismissed: (direction) => _removeItem(item),
                      background: Container(
                        color: Colors.red, // Background color while swiping
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: InkWell(
                        onTap: () {},
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.square, color: item.category.color),
                              SizedBox(width: 16),
                              Text(
                                item.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              Spacer(),
                              Text(
                                item.quantity.toString(),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
