import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import 'category_item.dart';

class CategoryGrid extends StatelessWidget {
  final Function(String category) onCategorySelected;

  const CategoryGrid({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        CategoryItem(
          icon: Image.asset(
            AppAssets.getImage('CellphoneS_Icon.png'),
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          title: "Phone",
          onTap: () => onCategorySelected("Điện thoại di động"),
        ),
        CategoryItem(
          icon: const Icon(Icons.laptop, size: 50, color: Colors.white),
          title: "Laptop",
          onTap: () => onCategorySelected("Máy tính xách tay"),
        ),
        CategoryItem(
          icon: const Icon(Icons.watch, size: 50, color: Colors.white),
          title: "Watch",
          onTap: () => onCategorySelected("Đồng hồ"),
        ),
        CategoryItem(
          icon: const Icon(Icons.headphones, size: 50, color: Colors.white),
          title: "Headphone",
          onTap: () => onCategorySelected("Tai nghe"),
        ),
      ],
    );
  }
}
