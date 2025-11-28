import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/fuga_cubit.dart';
import 'fuga_view.dart';

class FugaPage extends StatelessWidget {
  const FugaPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const FugaPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FugaCubit(),
      child: const FugaView(),
    );
  }
}
