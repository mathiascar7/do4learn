import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  _AdminApprovalPageState createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _approveAdmin(String adminId) async {
    try {
      await _firestore.collection('pending_admins').doc(adminId).update({
        'approved': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Admin approved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Approval')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('pending_admins').where('approved', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending admins.'));
          }

          final admins = snapshot.data!.docs;
          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final adminId = admin.id;
              final adminName = admin['name'];
              return ListTile(
                title: Text(adminName),
                trailing: IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () => _approveAdmin(adminId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
