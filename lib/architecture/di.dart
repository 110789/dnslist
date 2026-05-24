import 'package:flutter/widgets.dart';

abstract class ArchitectureContainer {
  T getService<T>();
  void registerService<T>(T service);
  void registerFactory<T>(T Function() factory);
  void registerLazySingleton<T>(T Function() factory);
}

class DefaultArchitectureContainer implements ArchitectureContainer {
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  @override
  T getService<T>() {
    final service = _services[T];
    if (service != null) return service as T;

    final factory = _factories[T];
    if (factory != null) {
      final instance = factory();
      _services[T] = instance;
      return instance as T;
    }

    throw Exception('Service $T not registered');
  }

  @override
  void registerService<T>(T service) {
    _services[T] = service;
  }

  @override
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  @override
  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      final instance = factory();
      _services[T] = instance;
      return instance;
    };
  }
}

class ArchitectureProvider extends InheritedWidget {
  final ArchitectureContainer container;

  const ArchitectureProvider({
    super.key,
    required this.container,
    required super.child,
  });

  static ArchitectureContainer? of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ArchitectureProvider>();
    return provider?.container;
  }

  @override
  bool updateShouldNotify(ArchitectureProvider oldWidget) {
    return container != oldWidget.container;
  }
}