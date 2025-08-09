import 'package:flutter/material.dart';

void main() {
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
}

class Sleep {
  final String name;
  final TimeOfDay startTime;
  final int durationMinutes;
  bool isDone;

  Sleep({
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    this.isDone = false,
  });
}

class PolyphasicHome extends StatefulWidget {
  const PolyphasicHome({super.key});

  @override
  State<PolyphasicHome> createState() => _PolyphasicHomeState();
}

class _PolyphasicHomeState extends State<PolyphasicHome> {
  SleepCycle? activeCycle;
  final List<SleepCycle> savedCycles = [];
  DateTime lastResetDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkAndResetDailyTasks();
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
                          subtitle: Text('${sleep.startTime.format(context)} - ${sleep.durationMinutes}min'),
                        )),
                    ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            sleeps.add(Sleep(
                              name: sleeps.isEmpty ? 'Core' : 'Nap ${sleeps.length}',
                              startTime: time,
                              durationMinutes: 90,
                            ));
                          });
                        }
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
                TextButton(
                  onPressed: () {
                    if (cycleName.isNotEmpty && sleeps.isNotEmpty) {
                      setState(() {
                        savedCycles.add(SleepCycle(name: cycleName, sleeps: sleeps));
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
    _checkAndResetDailyTasks();

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
                          return Card(
                            child: ListTile(
                              title: Text(cycle.name),
                              subtitle: Text('${cycle.sleeps.length} sleep blocks'),
                              onTap: () {
                                setState(() {
                                  activeCycle = cycle;
                                });
                              },
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
