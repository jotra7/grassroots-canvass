import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/voter.dart';
import '../../models/contact_entry.dart';
import '../../models/enums/contact_method.dart';
import '../../models/enums/canvass_result.dart';
import '../../services/supabase_service.dart';
import '../../services/cache_service.dart';
import '../../providers/voter_provider.dart';
import '../../utils/adaptive_icons.dart';

class ContactHistoryScreen extends ConsumerStatefulWidget {
  final Voter voter;

  const ContactHistoryScreen({super.key, required this.voter});

  @override
  ConsumerState<ContactHistoryScreen> createState() => _ContactHistoryScreenState();
}

class _ContactHistoryScreenState extends ConsumerState<ContactHistoryScreen> {
  List<ContactEntry> _entries = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final cache = CacheService.instance;

    try {
      // Try to fetch from server first
      final entries = await SupabaseService.instance
          .fetchContactHistory(widget.voter.uniqueId);

      // Cache the results for offline use
      if (cache.isAvailable) {
        await cache.cacheContactHistory(widget.voter.uniqueId, entries);
      }

      setState(() {
        _entries = entries;
        _isLoading = false;
        _isOffline = false;
      });
    } catch (e) {
      // Server fetch failed - try to load from cache
      print('[ContactHistory] Server fetch failed: $e');

      if (cache.isAvailable) {
        try {
          final cachedEntries = await cache.getCachedContactHistory(widget.voter.uniqueId);
          setState(() {
            _entries = cachedEntries;
            _isLoading = false;
            _isOffline = true;
          });
          if (mounted && cachedEntries.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Showing cached history (offline)')),
            );
          }
          return;
        } catch (cacheError) {
          print('[ContactHistory] Cache fetch failed: $cacheError');
        }
      }

      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load history (offline)')),
        );
      }
    }
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<ContactEntry>(
      context: context,
      builder: (context) => _EditEntryDialog(
        visitorId: widget.voter.uniqueId,
      ),
    );

    if (entry != null) {
      final cache = CacheService.instance;

      try {
        // Try to save to server
        final savedEntry = await SupabaseService.instance.addContactEntry(entry);
        if (savedEntry != null) {
          setState(() {
            _entries.insert(0, savedEntry);
          });

          // Cache the entry
          if (cache.isAvailable) {
            await cache.cacheContactHistory(widget.voter.uniqueId, _entries);
          }

          // Update voter's result and increment contact count
          final updatedVoter = widget.voter.copyWith(
            lastContactAttempt: DateTime.now(),
            canvassResult: entry.result,
            lastContactMethod: entry.method,
            contactAttempts: widget.voter.contactAttempts + 1,
          );
          await ref.read(voterProvider.notifier).updateVoter(updatedVoter);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact entry added')),
            );
          }
        }
      } catch (e) {
        // Server save failed - queue for offline sync
        print('[ContactHistory] Server save failed, queueing: $e');

        if (cache.isAvailable) {
          await cache.addPendingContactEntry(entry);

          // Add to local display immediately
          setState(() {
            _entries.insert(0, entry.copyWith(id: 'pending_${DateTime.now().millisecondsSinceEpoch}'));
            _isOffline = true;
          });

          // Update voter's result locally and increment contact count
          final updatedVoter = widget.voter.copyWith(
            lastContactAttempt: DateTime.now(),
            canvassResult: entry.result,
            lastContactMethod: entry.method,
            contactAttempts: widget.voter.contactAttempts + 1,
          );
          await ref.read(voterProvider.notifier).updateVoter(updatedVoter);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entry saved locally (will sync when online)')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding entry: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _editEntry(ContactEntry entry, int index) async {
    final updatedEntry = await showDialog<ContactEntry>(
      context: context,
      builder: (context) => _EditEntryDialog(
        visitorId: widget.voter.visitorId,
        existingEntry: entry,
      ),
    );

    if (updatedEntry != null) {
      try {
        final success =
            await SupabaseService.instance.updateContactEntry(updatedEntry);
        if (success) {
          setState(() {
            _entries[index] = updatedEntry;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact entry updated')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating entry: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteEntry(ContactEntry entry, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this contact entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success =
            await SupabaseService.instance.deleteContactEntry(entry.id);
        if (success) {
          setState(() {
            _entries.removeAt(index);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact entry deleted')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
      }
    }
  }

  Color _getResultColor(CanvassResult result) {
    switch (result) {
      case CanvassResult.supportive:
      case CanvassResult.strongSupport:
      case CanvassResult.willingToVolunteer:
      case CanvassResult.requestedSign:
        return Colors.green;
      case CanvassResult.undecided:
      case CanvassResult.leaning:
      case CanvassResult.needsInfo:
      case CanvassResult.callbackRequested:
        return Colors.orange;
      case CanvassResult.opposed:
      case CanvassResult.stronglyOpposed:
      case CanvassResult.doNotContact:
      case CanvassResult.refused:
        return Colors.red;
      case CanvassResult.contacted:
      case CanvassResult.leftVoicemail:
      case CanvassResult.textSent:
      case CanvassResult.textReplied:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMethodIcon(ContactMethod method) {
    switch (method) {
      case ContactMethod.call:
        return Icons.phone;
      case ContactMethod.text:
        return Icons.message;
      case ContactMethod.door:
        return Icons.door_front_door;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text('${widget.voter.displayName} History'),
      ),
      body: Material(
        child: Stack(
          children: [
            _buildBody(),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _addEntry,
                child: Icon(AdaptiveIcons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contact history',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add an entry',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getResultColor(entry.result).withAlpha(40),
                            child: Icon(
                              _getMethodIcon(entry.method),
                              color: _getResultColor(entry.result),
                            ),
                          ),
                          title: Text(entry.result.displayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.method.displayName} - ${DateFormat('MMM d, yyyy h:mm a').format(entry.contactedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (entry.notes != null && entry.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    entry.notes!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editEntry(entry, index);
                              } else if (value == 'delete') {
                                _deleteEntry(entry, index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: entry.notes != null && entry.notes!.isNotEmpty,
                        ),
                      );
                    },
                  ),
                );
  }
}

class _EditEntryDialog extends StatefulWidget {
  final String visitorId;
  final ContactEntry? existingEntry;

  const _EditEntryDialog({
    required this.visitorId,
    this.existingEntry,
  });

  @override
  State<_EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<_EditEntryDialog> {
  late ContactMethod _method;
  late CanvassResult _result;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _method = widget.existingEntry?.method ?? ContactMethod.call;
    _result = widget.existingEntry?.result ?? CanvassResult.contacted;
    _notesController =
        TextEditingController(text: widget.existingEntry?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Contact Entry' : 'Add Contact Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Method'),
            const SizedBox(height: 8),
            SegmentedButton<ContactMethod>(
              segments: const [
                ButtonSegment(
                  value: ContactMethod.call,
                  label: Text('Call'),
                  icon: Icon(Icons.phone, size: 16),
                ),
                ButtonSegment(
                  value: ContactMethod.text,
                  label: Text('Text'),
                  icon: Icon(Icons.message, size: 16),
                ),
                ButtonSegment(
                  value: ContactMethod.door,
                  label: Text('Door'),
                  icon: Icon(Icons.door_front_door, size: 16),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (values) {
                setState(() => _method = values.first);
              },
            ),
            const SizedBox(height: 16),
            const Text('Result'),
            const SizedBox(height: 8),
            DropdownButtonFormField<CanvassResult>(
              value: _result,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: CanvassResult.values.map((result) {
                return DropdownMenuItem(
                  value: result,
                  child: Text(result.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _result = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Notes'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final entry = ContactEntry(
              id: widget.existingEntry?.id ?? '',
              visitorId: widget.visitorId,
              method: _method,
              result: _result,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
              contactedAt: widget.existingEntry?.contactedAt ?? DateTime.now(),
              contactedBy: widget.existingEntry?.contactedBy,
            );
            Navigator.pop(context, entry);
          },
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
