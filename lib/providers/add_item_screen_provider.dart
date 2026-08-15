import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class AddItemScreenProvider extends ChangeNotifier {
  // Form State
  String _itemName = '';
  String _selectedCategory = ItemCategory.grocery;
  int _quantity = 1;
  String _selectedUnit = 'pcs';
  bool _isSubmitting = false;
  bool _categoryAutoDetected = false;

  // Getters
  String get itemName => _itemName;
  String get selectedCategory => _selectedCategory;
  int get quantity => _quantity;
  String get selectedUnit => _selectedUnit;
  bool get isSubmitting => _isSubmitting;
  bool get categoryAutoDetected => _categoryAutoDetected;

  // Methods
  void setItemName(String name) {
    _itemName = name;
    notifyListeners();
  }

  void setCategory(String category, {bool autoDetected = false}) {
    _selectedCategory = category;
    _categoryAutoDetected = autoDetected;
    notifyListeners();
  }

  void setQuantity(int qty) {
    _quantity = qty;
    notifyListeners();
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  void reset() {
    _itemName = '';
    _selectedCategory = ItemCategory.grocery;
    _quantity = 1;
    _selectedUnit = 'pcs';
    _isSubmitting = false;
    _categoryAutoDetected = false;
    notifyListeners();
  }
}
