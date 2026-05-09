import 'package:flutter/widgets.dart';

class AppStateContainer extends InheritedWidget {
  final Map<Type, ChangeNotifier> states;

  const AppStateContainer({
    super.key,
    required this.states,
    required super.child,
  });

  static AppStateContainer? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateContainer>();
  }

  T? getState<T extends ChangeNotifier>() {
    return states[T] as T?;
  }

  @override
  bool updateShouldNotify(AppStateContainer oldWidget) {
    return states != oldWidget.states;
  }
}

class StateProvider extends StatefulWidget {
  final Widget child;
  final Map<Type, ChangeNotifier> Function() createStates;

  const StateProvider({
    super.key,
    required this.child,
    required this.createStates,
  });

  @override
  State<StateProvider> createState() => _StateProviderState();
}

class _StateProviderState extends State<StateProvider> {
  late Map<Type, ChangeNotifier> _states;

  @override
  void initState() {
    super.initState();
    _states = widget.createStates();
  }

  @override
  void dispose() {
    for (final state in _states.values) {
      state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateContainer(
      states: _states,
      child: widget.child,
    );
  }
}