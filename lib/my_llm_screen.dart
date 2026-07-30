// import 'package:corecare/providers/llm_pro.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/providers/llm_pro.dart';
// import 'package:upgrade/providers/llm_pro.dart';

class MyLLmScreen extends ConsumerStatefulWidget {
  const MyLLmScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyLLmScreenState();
}

class _MyLLmScreenState extends ConsumerState<MyLLmScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(llmProvider.notifier).textSearch();
            },
            icon: Icon(Icons.ac_unit),
          ),
        ],
      ),
    );
  }
}
