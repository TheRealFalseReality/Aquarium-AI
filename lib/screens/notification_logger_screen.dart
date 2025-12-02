import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tank.dart';
import '../models/notification_log.dart';
import '../models/tank_notification.dart';
import '../models/tank_note.dart';
import '../providers/tank_provider.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../widgets/notification_reschedule_dialog.dart';
import '../l10n/app_localizations.dart';

class NotificationLoggerScreen extends ConsumerStatefulWidget {
  final Tank tank;

  const NotificationLoggerScreen({super.key, required this.tank});

  @override
  NotificationLoggerScreenState createState() => NotificationLoggerScreenState();
}

class NotificationLoggerScreenState extends ConsumerState<NotificationLoggerScreen> with SingleTickerProviderStateMixin {
  String? _expandedCategory;
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Tank _getCurrentTank() {
    // Get the latest tank state from the provider
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  void _addNote(BuildContext context) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddNoteSheet(tank: currentTank),
    );
  }

  void _editNote(BuildContext context, TankNote note) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddNoteSheet(
        tank: currentTank,
        existingNote: note,
      ),
    );
  }

  Future<void> _deleteNote(TankNote note) async {
    final currentTank = _getCurrentTank();
    final updatedNotes = currentTank.tankNotes
        .where((n) => n.id != note.id)
        .toList();
    
    final updatedTank = currentTank.copyWith(
      tankNotes: updatedNotes,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(tankProvider.notifier).updateTank(updatedTank);
    
    // Log note deletion
    AnalyticsService.logFeatureUsed(
      featureName: 'tank_note_deleted',
      parameters: {
        'tank_type': currentTank.type,
        'remaining_notes': updatedNotes.length,
      },
    );
  }

  void _addLogEntry(BuildContext context) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddLogEntrySheet(tank: currentTank),
    );
  }

  void _editLogEntry(BuildContext context, NotificationLog entry) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddLogEntrySheet(
        tank: currentTank,
        existingEntry: entry,
      ),
    );
  }

  Future<void> _deleteLogEntry(NotificationLog entry) async {
    final currentTank = _getCurrentTank();
    final updatedLogs = currentTank.notificationLogs
        .where((e) => e.id != entry.id)
        .toList();
    
    // Reschedule matching notifications based on remaining activity logs
    // (next most recent activity becomes the base)
    final updatedNotifications = await _notificationService.rescheduleMatchingNotifications(
      tankId: currentTank.id,
      tankName: currentTank.name,
      notifications: currentTank.notifications,
      activityLogs: updatedLogs,
      activityType: entry.type,
      activityCustomCategory: entry.customCategory,
    );
    
    // Update the tank with updated logs and notifications
    var updatedTank = currentTank.copyWith(
      notificationLogs: updatedLogs,
      updatedAt: DateTime.now(),
    );
    
    // Apply the updated notifications with new scheduledNextDate
    if (updatedNotifications.isNotEmpty) {
      final notificationsList = updatedTank.notifications.map((n) {
        final updated = updatedNotifications.firstWhere(
          (u) => u.id == n.id,
          orElse: () => n,
        );
        return updated;
      }).toList();
      updatedTank = updatedTank.copyWith(notifications: notificationsList);
    }
    
    await ref.read(tankProvider.notifier).updateTank(updatedTank);
    
    // Log notification log entry deletion
    AnalyticsService.logFeatureUsed(
      featureName: 'notification_log_deleted',
      parameters: {
        'category': entry.getDisplayName(),
        'tank_type': currentTank.type,
        'remaining_logs': updatedLogs.length,
      },
    );
    
    AnalyticsService.logTankAction(
      action: 'notification_log_deleted',
      tankType: currentTank.type,
    );
  }

  Map<String, List<NotificationLog>> _groupLogsByCategory(Tank tank) {
    final grouped = <String, List<NotificationLog>>{};
    for (var entry in tank.notificationLogs) {
      final category = entry.getDisplayName();
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(entry);
    }
    // Sort each group by date (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    });
    return grouped;
  }

  IconData _getCategoryIcon(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.dosing:
        return Icons.medication_liquid;
      case NotificationType.waterChange:
        return Icons.water_drop;
      case NotificationType.testing:
        return Icons.science;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.other:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.dosing:
        return Colors.purple;
      case NotificationType.waterChange:
        return Colors.blue;
      case NotificationType.testing:
        return Colors.teal;
      case NotificationType.maintenance:
        return Colors.brown;
      case NotificationType.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tank = _getCurrentTank();
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      title: '${tank.name} - ${l10n.activityLog}',
      child: Scaffold(
        appBar: AppBar(
          title: Text(tank.name),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.note_outlined),
                text: l10n.notesSection,
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: l10n.activitiesSection,
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNotesTab(context, tank),
            _buildActivitiesTab(context, tank),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              _addNote(context);
            } else {
              _addLogEntry(context);
            }
          },
          icon: const Icon(Icons.add),
          label: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return Text(_tabController.index == 0 ? l10n.addNote : l10n.addLogEntry);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.tankNotes.isEmpty) {
      return _buildNotesEmptyState(context);
    }

    // Sort notes by most recent first
    final sortedNotes = List<TankNote>.from(tank.tankNotes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      children: [
        Text(
          l10n.notesSection,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.noNotesDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        // Notes summary card
        _buildNotesSummaryCard(context, tank),
        const SizedBox(height: 16),
        // Notes list
        ...sortedNotes.map((note) => _buildNoteItem(context, note)),
      ],
    );
  }

  Widget _buildNotesEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noNotesYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noNotesDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _addNote(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstNote),
              style: FilledButton.styleFrom(
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

  Widget _buildNotesSummaryCard(BuildContext context, Tank tank) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final totalNotes = tank.tankNotes.length;
    // Get the most recent note using reduce for cleaner code
    final lastNote = tank.tankNotes.isNotEmpty
        ? tank.tankNotes.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.summarize, color: cs.primary),
        title: Text(
          l10n.notesSection,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text('$totalNotes ${totalNotes == 1 ? l10n.entry : l10n.entries}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        l10n.totalNotes,
                        totalNotes.toString(),
                        Icons.note,
                      ),
                    ),
                  ],
                ),
                if (lastNote != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.lastNote}: ${DateFormat('MMM d, yyyy').format(lastNote.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, TankNote note) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.note,
                    size: 20,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(note.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editNote(context, note);
                    } else if (value == 'delete') {
                      _showDeleteNoteDialog(context, note);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteNoteDialog(BuildContext context, TankNote note) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(note);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(BuildContext context, Tank tank) {
    final groupedLogs = _groupLogsByCategory(tank);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (tank.notificationLogs.isEmpty) {
      return _buildActivitiesEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      children: [
        Text(
          l10n.activitiesSection,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.activityLogDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        // Summary card
        _buildSummaryCard(context, tank),
        const SizedBox(height: 16),
        
        // Grouped entries
        ...groupedLogs.entries.map((entry) {
          final categoryName = entry.key;
          final logs = entry.value;
          final isExpanded = _expandedCategory == categoryName;
          final firstLog = logs.first;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(firstLog.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(firstLog.type),
                      color: _getCategoryColor(firstLog.type),
                    ),
                  ),
                  title: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${logs.length} ${logs.length == 1 ? l10n.entry : l10n.entries}'),
                  trailing: IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _expandedCategory = isExpanded ? null : categoryName;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _expandedCategory = isExpanded ? null : categoryName;
                    });
                  },
                ),
                if (isExpanded)
                  Column(
                    children: [
                      const Divider(height: 1),
                      ...logs.map((log) => _buildLogItem(context, log)),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivitiesEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noActivityLogsYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noActivityLogsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _addLogEntry(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstLogEntry),
              style: FilledButton.styleFrom(
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

  Widget _buildSummaryCard(BuildContext context, Tank tank) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final groupedLogs = _groupLogsByCategory(tank);
    final totalLogs = tank.notificationLogs.length;
    final lastLog = tank.notificationLogs.isNotEmpty
        ? tank.notificationLogs.reduce((a, b) => 
            a.loggedAt.isAfter(b.loggedAt) ? a : b)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.summarize, color: cs.primary),
        title: Text(
          l10n.activitySummary,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text('$totalLogs ${totalLogs == 1 ? l10n.entry : l10n.entries}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        l10n.totalLogs,
                        totalLogs.toString(),
                        Icons.history,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        l10n.categories,
                        groupedLogs.length.toString(),
                        Icons.category,
                      ),
                    ),
                  ],
                ),
                if (lastLog != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.lastActivity}: ${DateFormat('MMM d, yyyy').format(lastLog.loggedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, NotificationLog entry) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getCategoryColor(entry.type).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCategoryIcon(entry.type),
          size: 16,
          color: _getCategoryColor(entry.type),
        ),
      ),
      title: Text(
        dateFormat.format(entry.loggedAt),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: entry.notes != null && entry.notes!.isNotEmpty
          ? Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: cs.primary,
            onPressed: () => _editLogEntry(context, entry),
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context, entry),
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NotificationLog entry) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLogEntry),
        content: Text(l10n.deleteLogEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _deleteLogEntry(entry);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _AddLogEntrySheet extends ConsumerStatefulWidget {
  final Tank tank;
  final NotificationLog? existingEntry;

  const _AddLogEntrySheet({
    required this.tank,
    this.existingEntry,
  });

  @override
  _AddLogEntrySheetState createState() => _AddLogEntrySheetState();
}

class _AddLogEntrySheetState extends ConsumerState<_AddLogEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _customCategoryController = TextEditingController();
  final _notesController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  late DateTime _selectedDate;
  late NotificationType _selectedType;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      // Initialize with existing entry data
      _selectedType = widget.existingEntry!.type;
      _customCategoryController.text = widget.existingEntry!.customCategory ?? '';
      _notesController.text = widget.existingEntry!.notes ?? '';
      _selectedDate = widget.existingEntry!.loggedAt;
    } else {
      // Initialize with default values for new entry
      _selectedDate = DateTime.now();
      _selectedType = NotificationType.feeding;
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final NotificationLog entry;
      final isEditing = widget.existingEntry != null;
      
      // Extract trimmed values to avoid calling trim() multiple times
      final trimmedCustomCategory = _customCategoryController.text.trim();
      final trimmedNotes = _notesController.text.trim();
      
      // For 'other' type, use custom category or default to 'Other'
      final customCategory = _selectedType == NotificationType.other
          ? (trimmedCustomCategory.isNotEmpty ? trimmedCustomCategory : 'Other')
          : null;
      
      // Determine if we need to clear custom category (when switching from 'other' to another type)
      final shouldClearCustomCategory = _selectedType != NotificationType.other;
      
      List<NotificationLog> updatedLogs;
      
      if (isEditing) {
        // Update existing entry - loggedAt is included to allow users to correct/adjust the date
        entry = widget.existingEntry!.copyWith(
          type: _selectedType,
          customCategory: customCategory,
          loggedAt: _selectedDate,
          notes: trimmedNotes.isNotEmpty ? trimmedNotes : null,
          clearCustomCategory: shouldClearCustomCategory,
        );
        
        // Replace the existing entry in the list
        updatedLogs = widget.tank.notificationLogs.map((e) {
          return e.id == entry.id ? entry : e;
        }).toList();
        
        final updatedTank = widget.tank.copyWith(
          notificationLogs: updatedLogs,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        
        // Log notification log entry update
        AnalyticsService.logFeatureUsed(
          featureName: 'notification_log_updated',
          parameters: {
            'category': entry.getDisplayName(),
            'tank_type': widget.tank.type,
          },
        );
      } else {
        // Create new entry
        entry = NotificationLog.create(
          type: _selectedType,
          customCategory: customCategory,
          notes: trimmedNotes.isNotEmpty ? trimmedNotes : null,
        );
        
        updatedLogs = [...widget.tank.notificationLogs, entry];
        final updatedTank = widget.tank.copyWith(
          notificationLogs: updatedLogs,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        
        // Log notification log entry addition
        AnalyticsService.logFeatureUsed(
          featureName: 'notification_log_added',
          parameters: {
            'category': entry.getDisplayName(),
            'tank_type': widget.tank.type,
            'has_notes': entry.notes != null ? 'true' : 'false',
          },
        );
        
        AnalyticsService.logTankAction(
          action: 'notification_log_added',
          tankType: widget.tank.type,
        );
      }
      
      // Find matching notifications for this activity type
      final matchingNotifications = widget.tank.notifications.where((notification) {
        return notification.enabled &&
               notification.repeatFrequency != RepeatFrequency.none &&
               notification.matchesActivityLog(entry.type, entry.customCategory);
      }).toList();
      
      // Close the bottom sheet first
      if (mounted) {
        Navigator.pop(context);
      }
      
      // If there are matching notifications, ask user how to handle rescheduling
      if (matchingNotifications.isNotEmpty && mounted) {
        // Show dialog for the first matching notification
        // (typically there's only one notification per activity type)
        final matchingNotification = matchingNotifications.first;
        final rescheduleOption = await NotificationRescheduleDialog.show(
          context,
          matchingNotification,
        );
        
        if (rescheduleOption != null && mounted) {
          await _handleRescheduleOption(
            matchingNotification,
            entry,
            updatedLogs,
            rescheduleOption,
          );
        }
      }
    }
  }

  /// Handle the reschedule option selected by the user
  Future<void> _handleRescheduleOption(
    TankNotification notification,
    NotificationLog log,
    List<NotificationLog> updatedLogs,
    RescheduleOption option,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Get the latest tank state
    final currentTank = ref.read(tankProvider).tanks
        .firstWhere((t) => t.id == widget.tank.id, orElse: () => widget.tank);
    
    switch (option) {
      case RescheduleOption.rescheduleFromNow:
        // Reschedule based on the activity log date, using current time
        final updatedNotifications = await _notificationService.rescheduleMatchingNotifications(
          tankId: currentTank.id,
          tankName: currentTank.name,
          notifications: currentTank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
          useCurrentTime: true,
        );
        
        // Persist the updated notifications
        if (updatedNotifications.isNotEmpty) {
          final notificationsList = currentTank.notifications.map((n) {
            final updated = updatedNotifications.firstWhere(
              (u) => u.id == n.id,
              orElse: () => n,
            );
            return updated;
          }).toList();
          final updatedTank = currentTank.copyWith(
            notifications: notificationsList,
            updatedAt: DateTime.now(),
          );
          await ref.read(tankProvider.notifier).updateTank(updatedTank);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.notificationUpdated)),
          );
        }
        break;
        
      case RescheduleOption.keepOriginal:
        // Reschedule to same date as rescheduleFromNow but keep original notification time
        final updatedNotifications = await _notificationService.rescheduleMatchingNotifications(
          tankId: currentTank.id,
          tankName: currentTank.name,
          notifications: currentTank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
          useCurrentTime: false,  // Keep original time
        );
        
        // Persist the updated notifications
        if (updatedNotifications.isNotEmpty) {
          final notificationsList = currentTank.notifications.map((n) {
            final updated = updatedNotifications.firstWhere(
              (u) => u.id == n.id,
              orElse: () => n,
            );
            return updated;
          }).toList();
          final updatedTank = currentTank.copyWith(
            notifications: notificationsList,
            updatedAt: DateTime.now(),
          );
          await ref.read(tankProvider.notifier).updateTank(updatedTank);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.notificationUpdated)),
          );
        }
        break;
        
      case RescheduleOption.doNothing:
        // Don't reschedule - activity is already logged, just keep existing schedule
        break;
        
      case RescheduleOption.cancelAll:
        // Cancel - don't log activity and don't reschedule
        // Remove the log that was just added
        final logsWithoutNew = updatedLogs.where((l) => l.id != log.id).toList();
        final updatedTank = currentTank.copyWith(
          notificationLogs: logsWithoutNew,
          updatedAt: DateTime.now(),
        );
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        break;
    }
    
    AnalyticsService.logFeatureUsed(
      featureName: 'notification_reschedule_option',
      parameters: {
        'option': option.name,
        'notification_type': notification.type.name,
        'source': 'activity_logger',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingEntry != null;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? l10n.editLogEntry : l10n.addLogEntry,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: '${l10n.category} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Clear custom category when switching away from "Other"
                      if (value != NotificationType.other) {
                        _customCategoryController.clear();
                      }
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Custom category name (shown only when "Other" is selected)
              if (_selectedType == NotificationType.other) ...[
                TextFormField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: l10n.customCategoryOptional,
                    hintText: l10n.customCategoryHint,
                    helperText: l10n.customCategoryHelper,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
              ],
              
              // Date selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateAndTime,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  hintText: l10n.addNotesPlaceholder,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? l10n.updateLogEntry : l10n.saveLogEntry),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNoteSheet extends ConsumerStatefulWidget {
  final Tank tank;
  final TankNote? existingNote;

  const _AddNoteSheet({
    required this.tank,
    this.existingNote,
  });

  @override
  _AddNoteSheetState createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<_AddNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _contentController.text = widget.existingNote!.content;
      _selectedDate = widget.existingNote!.createdAt;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final trimmedContent = _contentController.text.trim();
      final isEditing = widget.existingNote != null;
      
      List<TankNote> updatedNotes;
      
      if (isEditing) {
        // Update existing note - createdAt is included to allow users to correct/adjust the date
        final updatedNote = widget.existingNote!.copyWith(
          content: trimmedContent,
          createdAt: _selectedDate,
          updatedAt: DateTime.now(),
        );
        
        // Replace the existing note in the list
        updatedNotes = widget.tank.tankNotes.map((n) {
          return n.id == updatedNote.id ? updatedNote : n;
        }).toList();
        
        final updatedTank = widget.tank.copyWith(
          tankNotes: updatedNotes,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        
        // Log note update
        AnalyticsService.logFeatureUsed(
          featureName: 'tank_note_updated',
          parameters: {
            'tank_type': widget.tank.type,
          },
        );
      } else {
        // Create new note with selected date
        final note = TankNote.create(
          content: trimmedContent,
          createdAt: _selectedDate,
        );
        
        updatedNotes = [...widget.tank.tankNotes, note];
        final updatedTank = widget.tank.copyWith(
          tankNotes: updatedNotes,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        
        // Log note addition
        AnalyticsService.logFeatureUsed(
          featureName: 'tank_note_added',
          parameters: {
            'tank_type': widget.tank.type,
            'total_notes': updatedNotes.length,
          },
        );
        
        AnalyticsService.logTankAction(
          action: 'tank_note_added',
          tankType: widget.tank.type,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingNote != null;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? l10n.editNote : l10n.addNote,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Note content
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: '${l10n.noteContent} *',
                  hintText: l10n.noteContentHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.noteRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Date selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateAndTime,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? l10n.updateNote : l10n.saveNote),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
