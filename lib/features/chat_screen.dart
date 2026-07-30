// import 'package:flutter/material.dart';
// // import '../services/local_llm_service.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isLoading = false;
//   bool _isLLMReady = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeLLM();
//     _addWelcomeMessage();
//   }

//   Future<void> _initializeLLM() async {
//     setState(() {
//       _isLoading = true;
//     });

//     final success = await LocalLLMService.initialize();

//     setState(() {
//       _isLoading = false;
//       _isLLMReady = success;
//     });

//     if (success) {
//       _addSystemMessage(
//         "✅ Local AI model loaded successfully! I'm ready to help with your nutrition and wellness questions.",
//       );
//     } else {
//       _addSystemMessage(
//         "❌ Could not load the AI model. Please check if gemma_2b.gguf is in the aimodels folder.",
//       );
//     }
//   }

//   void _addWelcomeMessage() {
//     _messages.add(
//       ChatMessage(
//         text:
//             "👋 Hello! I'm your personal nutrition AI assistant powered by Gemma 2B running locally on your device.\n\nI can help you with:\n• Meal planning and nutrition advice\n• Workout recommendations\n• General wellness guidance\n• Personalized health tips\n\nWhat would you like to know?",
//         isUser: false,
//         timestamp: DateTime.now(),
//       ),
//     );
//   }

//   void _addSystemMessage(String message) {
//     setState(() {
//       _messages.add(
//         ChatMessage(
//           text: message,
//           isUser: false,
//           isSystem: true,
//           timestamp: DateTime.now(),
//         ),
//       );
//     });
//     _scrollToBottom();
//   }

//   void _sendMessage() async {
//     final message = _messageController.text.trim();
//     if (message.isEmpty || !_isLLMReady) return;

//     // Add user message
//     setState(() {
//       _messages.add(
//         ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
//       );
//       _isLoading = true;
//     });

//     _messageController.clear();
//     _scrollToBottom();

//     try {
//       // Generate AI response
//       final response = await LocalLLMService.generateResponse(message);

//       setState(() {
//         _messages.add(
//           ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
//         );
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _messages.add(
//           ChatMessage(
//             text: "Sorry, I encountered an error: ${e.toString()}",
//             isUser: false,
//             isSystem: true,
//             timestamp: DateTime.now(),
//           ),
//         );
//         _isLoading = false;
//       });
//     }

//     _scrollToBottom();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'AI Nutrition Chat',
//               style: TextStyle(
//                 color: Color(0xFFFF8A50),
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             Text(
//               _isLLMReady ? 'Gemma 2B • Ready' : 'Loading...',
//               style: TextStyle(
//                 color: _isLLMReady ? Colors.green : Colors.orange,
//                 fontSize: 12,
//                 fontWeight: FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline, color: Color(0xFFFF8A50)),
//             onPressed: _showModelInfo,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 return ChatBubble(message: _messages[index]);
//               },
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Color(0xFFFF8A50),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'AI is thinking...',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     enabled: _isLLMReady && !_isLoading,
//                     decoration: InputDecoration(
//                       hintText: _isLLMReady
//                           ? 'Ask about nutrition, meals, workouts...'
//                           : 'Loading AI model...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                     maxLines: null,
//                     textInputAction: TextInputAction.send,
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 FloatingActionButton(
//                   onPressed: _isLLMReady && !_isLoading ? _sendMessage : null,
//                   backgroundColor: _isLLMReady && !_isLoading
//                       ? const Color(0xFFFF8A50)
//                       : Colors.grey.shade300,
//                   elevation: 0,
//                   mini: true,
//                   child: Icon(
//                     Icons.send,
//                     color: _isLLMReady && !_isLoading
//                         ? Colors.white
//                         : Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showModelInfo() {
//     final info = LocalLLMService.getModelInfo();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('AI Model Information'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInfoRow('Model', info['modelName']),
//             _buildInfoRow('Size', info['modelSize']),
//             _buildInfoRow('Status', _isLLMReady ? 'Ready' : 'Not Ready'),
//             const SizedBox(height: 16),
//             const Text(
//               'Capabilities:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             ...info['capabilities'].map<Widget>(
//               (capability) => Padding(
//                 padding: const EdgeInsets.only(left: 8, bottom: 4),
//                 child: Text('• $capability'),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 60,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// class ChatMessage {
//   final String text;
//   final bool isUser;
//   final bool isSystem;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.text,
//     required this.isUser,
//     this.isSystem = false,
//     required this.timestamp,
//   });
// }

// class ChatBubble extends StatelessWidget {
//   final ChatMessage message;

//   const ChatBubble({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         mainAxisAlignment: message.isUser
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!message.isUser) ...[
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: message.isSystem
//                     ? Colors.blue.shade100
//                     : const Color(0xFFFF8A50).withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(
//                 message.isSystem ? Icons.info : Icons.smart_toy,
//                 size: 18,
//                 color: message.isSystem ? Colors.blue : const Color(0xFFFF8A50),
//               ),
//             ),
//             const SizedBox(width: 12),
//           ],
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: message.isUser
//                     ? const Color(0xFFFF8A50)
//                     : message.isSystem
//                     ? Colors.blue.shade50
//                     : Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.05),
//                     blurRadius: 5,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     message.text,
//                     style: TextStyle(
//                       color: message.isUser ? Colors.white : Colors.black87,
//                       fontSize: 16,
//                       height: 1.4,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     _formatTime(message.timestamp),
//                     style: TextStyle(
//                       color: message.isUser
//                           ? Colors.white.withValues(alpha: 0.7)
//                           : Colors.grey.shade500,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (message.isUser) ...[
//             const SizedBox(width: 12),
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(Icons.person, size: 18, color: Colors.grey.shade600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   String _formatTime(DateTime time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//   }
// }
