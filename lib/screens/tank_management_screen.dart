import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../providers/tank_provider.dart';
import '../widgets/ad_component.dart';
import 'tank_creation_screen.dart';

class TankManagementScreen extends ConsumerWidget {
  const TankManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tankState = ref.watch(tankProvider);

    return MainLayout(
      title: 'My Tanks',
      bottomNavigationBar: const AdBanner(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TankCreationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tank'),
      ),
      child: tankState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tankState.error != null
              ? _buildErrorState(context, ref, tankState.error!)
              : tankState.tanks.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTankList(context, ref, tankState.tanks),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Tanks',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(tankProvider.notifier).clearError();
                // Trigger reload by creating a new notifier
                ref.invalidate(tankProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.water,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Tanks Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first custom tank to get started!\n\nDesign your perfect aquarium with custom names, types, and inhabitants.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TankCreationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Tank'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankList(BuildContext context, WidgetRef ref, List<Tank> tanks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tanks.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context, tanks.length);
        }
        
        final tank = tanks[index - 1];
        return _buildTankCard(context, ref, tank);
      },
    );
  }

  Widget _buildHeader(BuildContext context, int tankCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'Your Aquarium Collection',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You have $tankCount tank${tankCount == 1 ? '' : 's'} in your collection',
            style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTankCard(BuildContext context, WidgetRef ref, Tank tank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTankDetails(context, tank),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tank.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tank.type == 'freshwater' ? 'Freshwater' : 'Saltwater',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TankCreationScreen(existingTank: tank),
                            ),
                          );
                          break;
                        case 'delete':
                          _confirmDelete(context, ref, tank);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Inhabitants summary
              if (tank.inhabitants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No inhabitants added',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pets,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tank.inhabitants.length} type${tank.inhabitants.length == 1 ? '' : 's'} of fish',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tank.inhabitants.take(3).map((inhabitant) {
                        return Chip(
                          label: Text(
                            '${inhabitant.quantity}x ${inhabitant.customName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList()..addAll(
                        tank.inhabitants.length > 3
                            ? [
                                Chip(
                                  label: Text(
                                    '+${tank.inhabitants.length - 3} more',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                )
                              ]
                            : [],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              
              // Created date
              Text(
                'Created ${_formatDate(tank.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTankDetails(BuildContext context, Tank tank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tank.name, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tank.type == 'freshwater' ? 'Freshwater Tank' : 'Saltwater Tank',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                'Inhabitants (${tank.inhabitants.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (tank.inhabitants.isEmpty)
                const Text('No inhabitants added yet.')
              else
                ...tank.inhabitants.map((inhabitant) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(
                            '${inhabitant.quantity}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inhabitant.customName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                inhabitant.fishUnit,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              
              const SizedBox(height: 16),
              Text(
                'Created: ${_formatDateTime(tank.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tank.updatedAt != tank.createdAt)
                Text(
                  'Updated: ${_formatDateTime(tank.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TankCreationScreen(existingTank: tank),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Tank tank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tank', textAlign: TextAlign.center),
        content: Text('Are you sure you want to delete "${tank.name}"? This action cannot be undone.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(tankProvider.notifier).deleteTank(tank.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tank "${tank.name}" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}