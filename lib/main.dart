import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PolyphasicApp());
}

class PolyphasicApp extends StatelessWidget {
  const PolyphasicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polyphasic',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.redAccent.shade200,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
      ),
      home: const PolyphasicHome(),
    );
  }
}

class SleepCycle {
  final String name;
  final List<Sleep> sleeps;

  SleepCycle({required this.name, required this.sleeps});

  Map<String, dynamic> toJson() => {
        'name': name,
        'sleeps': sleeps.map((s) => s.toJson()).toList(),
      };

  factory SleepCycle.fromJson(Map<String, dynamic> json) => SleepCycle(
        name: json['name'],
        sleeps: (json['sleeps'] as List).map((s) => Sleep.fromJson(s)).toList(),
      );
}

enum SleepType { core, nap }

class Sleep {
  final String name;
  final TimeOfDay startTime;
  final int durationMinutes;
  final SleepType type;
  bool isDone;

  Sleep({
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    required this.type,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'hour': startTime.hour,
        'minute': startTime.minute,
        'durationMinutes': durationMinutes,
        'type': type.toString(),
        'isDone': isDone,
      };

  factory Sleep.fromJson(Map<String, dynamic> json) => Sleep(
        name: json['name'],
        startTime: TimeOfDay(hour: json['hour'], minute: json['minute']),
        durationMinutes: json['durationMinutes'],
        type: SleepType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => SleepType.nap),
        isDone: json['isDone'] ?? false,
      );
}

class AddSleepBlockDialog extends StatefulWidget {
  final void Function(Sleep sleep) onAdd;

  const AddSleepBlockDialog({super.key, required this.onAdd});

  @override
  State<AddSleepBlockDialog> createState() => _AddSleepBlockDialogState();
}

class _AddSleepBlockDialogState extends State<AddSleepBlockDialog> {
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  TimeOfDay _selectedTime = TimeOfDay.now();
  SleepType _selectedType = SleepType.nap;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _durationController = TextEditingController(text: '90');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sleep Block'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Block Name'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<SleepType>(
              segments: const [
                ButtonSegment(
                  value: SleepType.core,
                  label: Text('Core Sleep'),
                ),
                ButtonSegment(
                  value: SleepType.nap,
                  label: Text('Nap'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<SleepType> selection) {
                setState(() {
                  _selectedType = selection.first;
                  if (_nameController.text.isEmpty) {
                    _nameController.text = _selectedType == SleepType.core
                        ? 'Core Sleep'
                        : 'Nap';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'Enter sleep duration',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final duration = int.tryParse(_durationController.text) ?? 90;
            
            if (name.isNotEmpty && duration > 0) {
              widget.onAdd(Sleep(
                name: name,
                startTime: _selectedTime,
                durationMinutes: duration,
                type: _selectedType,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class PolyphasicHome extends StatefulWidget {
  const PolyphasicHome({super.key});

  @override
  State<PolyphasicHome> createState() => _PolyphasicHomeState();
}

class _PolyphasicHomeState extends State<PolyphasicHome> {
  static const String _cyclesKey = 'sleep_cycles';
  static const String _activeCycleKey = 'active_cycle';
  static const String _lastResetKey = 'last_reset_date';

  SleepCycle? activeCycle;
  List<SleepCycle> savedCycles = [];
  DateTime lastResetDate = DateTime.now();
  late SharedPreferences prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadData();
    _checkAndResetDailyTasks();
    setState(() => _isLoading = false);
  }

  void _loadData() {
    final String? cyclesJson = prefs.getString(_cyclesKey);
    final String? activeCycleJson = prefs.getString(_activeCycleKey);
    final String? lastResetString = prefs.getString(_lastResetKey);

    if (cyclesJson != null) {
      final List<dynamic> decoded = jsonDecode(cyclesJson);
      savedCycles = decoded.map((json) => SleepCycle.fromJson(json)).toList();
    }

    if (activeCycleJson != null) {
      activeCycle = SleepCycle.fromJson(jsonDecode(activeCycleJson));
    }

    if (lastResetString != null) {
      lastResetDate = DateTime.parse(lastResetString);
    }
  }

  Future<void> _saveData() async {
    await prefs.setString(_cyclesKey, jsonEncode(savedCycles.map((c) => c.toJson()).toList()));
    await prefs.setString(_lastResetKey, lastResetDate.toIso8601String());
    
    if (activeCycle != null) {
      await prefs.setString(_activeCycleKey, jsonEncode(activeCycle!.toJson()));
    } else {
      await prefs.remove(_activeCycleKey);
    }
  }

  void _checkAndResetDailyTasks() {
    final now = DateTime.now();
    if (now.day != lastResetDate.day) {
      setState(() {
        if (activeCycle != null) {
          for (var sleep in activeCycle!.sleeps) {
            sleep.isDone = false;
          }
        }
        lastResetDate = now;
        _saveData();
      });
    }
  }

  void _createNewCycle() {
    showDialog(
      context: context,
      builder: (context) {
        String cycleName = '';
        List<Sleep> sleeps = [];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Sleep Cycle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Cycle Name'),
                      onChanged: (value) => cycleName = value,
                    ),
                    const SizedBox(height: 16),
                    ...sleeps.map((sleep) => ListTile(
                          title: Text(sleep.name),
                          subtitle: Text(
                              '${sleep.type.name.toUpperCase()} - ${sleep.startTime.format(context)} - ${sleep.durationMinutes}min'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() => sleeps.remove(sleep));
                            },
                          ),
                        )),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddSleepBlockDialog(
                            onAdd: (sleep) {
                              setState(() => sleeps.add(sleep));
                            },
                          ),
                        );
                      },
                      child: const Text('Add Sleep Block'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (cycleName.isNotEmpty && sleeps.isNotEmpty) {
                      final newCycle = SleepCycle(name: cycleName, sleeps: sleeps);
                      setState(() {
                        savedCycles.add(newCycle);
                        _saveData();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polyphasic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewCycle,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeCycle == null) ...[
              Text(
                'Saved Sleep Cycles',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: savedCycles.isEmpty
                    ? const Center(child: Text('No sleep cycles created yet'))
                    : ListView.builder(
                        itemCount: savedCycles.length,
                        itemBuilder: (context, index) {
                          final cycle = savedCycles[index];
                          return Dismissible(
                            key: Key(cycle.name),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                savedCycles.removeAt(index);
                                _saveData();
                              });
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(cycle.name),
                                subtitle: Text('${cycle.sleeps.length} sleep blocks'),
                                onTap: () {
                                  setState(() {
                                    activeCycle = cycle;
                                    _saveData();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activeCycle!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        activeCycle = null;
                        _saveData();
                      });
                    },
                    child: const Text('Change Cycle'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: activeCycle!.sleeps.length,
                  itemBuilder: (context, index) {
                    final sleep = activeCycle!.sleeps[index];
                    return Card(
                      child: CheckboxListTile(
                        title: Text(sleep.name),
                        subtitle: Text('${sleep.startTime.format(context)} - ${sleep.durationMinutes}min'),
                        value: sleep.isDone,
                        onChanged: (value) {
                          setState(() {
                            sleep.isDone = value ?? false;
                            _saveData();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
