import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({super.key});

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  final List<String> items = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry'
  ];
  List<String> selectedItems = [];

  void toggleSelection(String item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        if (selectedItems.length < 3) {
          selectedItems.add(item);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Priority Multi-Select")),
      body: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            hint: const Text("Select up to 3 items"),
            items: items.map((item) {
              int index = selectedItems.indexOf(item);
              return DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Text(item),
                    const Spacer(),
                    if (index != -1)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Text(
                          (index + 1).toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (index == -1)
                      const Icon(Icons.circle_outlined, color: Colors.grey),
                  ],
                ),
                onTap: () => toggleSelection(item),
              );
            }).toList(),
            onChanged: (_) {}, // Do nothing on dropdown selection
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              width: 200,
            ),
          ),
        ),
      ),
    );
  }
}
