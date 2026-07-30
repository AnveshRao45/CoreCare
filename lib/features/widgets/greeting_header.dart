import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  // final VoidCallback? onCustomizeTap;

  const GreetingHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    // this.onCustomizeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
             
           
            ],
          ),
       
          // GestureDetector(
          //   onTap: onCustomizeTap,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(20),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withValues(alpha: 0.05),
          //           blurRadius: 10,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.tune, size: 18, color: Colors.grey.shade600),
          //         const SizedBox(width: 6),
          //         Text(
          //           'Customize',
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w500,
          //             color: Colors.grey.shade600,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
      
    );
  }
}
