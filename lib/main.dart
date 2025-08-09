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

class PolyphasicHome extends StatefulWidget {
  const PolyphasicHome({super.key});

  @override
  State<PolyphasicHome> createState() => _PolyphasicHomeState();
}

class _PolyphasicHomeState extends State<PolyphasicHome> {
  final List<String> _sleepLogs = [];

  void _logSleep() {
    final today = DateTime.now();
    final formattedDate = "${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}";

    if (!_sleepLogs.contains(formattedDate)) {
      setState(() {
        _sleepLogs.add(formattedDate);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep logged for today')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already logged for today!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polyphasic'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _logSleep,
              child: const Text('Log Today\'s Sleep'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sleep Logs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _sleepLogs.isEmpty
                  ? Center(
                      child: Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sleepLogs.length,
                      itemBuilder: (context, index) {
                        final date = _sleepLogs[index];
                        return Card(
                          color: Colors.black87,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.bedtime, color: Colors.redAccent),
                            title: Text(
                              date,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
