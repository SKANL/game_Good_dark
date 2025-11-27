import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/game/game.dart';
import 'package:echo_world/l10n/l10n.dart';
import 'package:echo_world/loading/loading.dart';
import 'package:echo_world/lore/lore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import 'helpers.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    MockNavigator? navigator,
    PreloadCubit? preloadCubit,
    AudioCubit? audioCubit,
    GameBloc? gameBloc,
    LoreBloc? loreBloc,
    CheckpointBloc? checkpointBloc,
  }) {
    return pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: preloadCubit ?? MockPreloadCubit()),
          if (audioCubit != null) BlocProvider.value(value: audioCubit),
          if (gameBloc != null) BlocProvider.value(value: gameBloc),
          if (loreBloc != null) BlocProvider.value(value: loreBloc),
          if (checkpointBloc != null) BlocProvider.value(value: checkpointBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: navigator != null
              ? MockNavigatorProvider(navigator: navigator, child: widget)
              : widget,
        ),
      ),
    );
  }
}
