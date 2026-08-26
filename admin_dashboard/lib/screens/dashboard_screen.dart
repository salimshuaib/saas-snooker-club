import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:admin_dashboard/data/admin_repository.dart';
import 'package:admin_dashboard/widgets/create_club_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SaaS Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Clubs Overview'),
                  selected: true,
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Platform Settings'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Registered Clubs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Onboard New Club'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CreateClubDialog(),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: clubsAsync.when(
                      data: (clubs) {
                        if (clubs.isEmpty) {
                          return const Center(child: Text('No clubs found.'));
                        }
                        return SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Club Name')),
                              DataColumn(label: Text('Owner')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('App Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: clubs.map((club) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(club.clubName)),
                                  DataCell(Text('${club.ownerName}\n(${club.ownerEmail})')),
                                  DataCell(Text(DateFormat('MMM d, yyyy').format(club.createdAt))),
                                  DataCell(
                                    Switch(
                                      value: club.isActive,
                                      activeColor: Colors.green,
                                      onChanged: (val) {
                                        ref.read(adminRepositoryProvider).toggleClubStatus(club.id, val);
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Club?'),
                                            content: Text('Are you sure you want to delete ${club.clubName}? This will instantly lock them out.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          )
                                        );
                                        
                                        if (confirm == true) {
                                          await ref.read(adminRepositoryProvider).deleteClub(club);
                                        }
                                      },
                                    )
                                  ),
                                ]
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Center(child: Text('Error: $err')),
                    )
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
