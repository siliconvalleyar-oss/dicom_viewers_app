import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/server_manager.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DicomAppState(),
      child: const DicomVisualApp(),
    ),
  );
}

class DicomVisualApp extends StatelessWidget {
  const DicomVisualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServerManager()..load(),
      child: Consumer<ServerManager>(
        builder: (context, _, _) => MaterialApp(
          title: 'DICOM Visual',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.blueGrey,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.blueGrey,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
