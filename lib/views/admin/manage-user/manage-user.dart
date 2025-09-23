import 'package:flutter/material.dart';

class ManageUser extends StatefulWidget {
  const ManageUser({super.key});

  @override
  State<ManageUser> createState() => _ManageUserState();
}

class _ManageUserState extends State<ManageUser>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage User"),
        leading: BackButton(),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    
    body: ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: Text("Dire mag design", 
          style: TextStyle(
          ),),
        ),
      ],
      // child: Text("Manage User"),
    ),
    );
  }
}