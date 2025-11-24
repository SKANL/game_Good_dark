import 'package:flame/components.dart';

/// Sistema de pooling de objetos para reducir la creación/destrucción de componentes.
///
/// Implementa el patrón Object Pool para mejorar el rendimiento al reutilizar
/// instancias de componentes en lugar de crearlas y destruirlas constantemente.
///
/// Uso típico:
/// ```dart
/// final pool = ComponentPool<ParticleSystemComponent>(
///   maxSize: 50,
///   factory: () => ParticleSystemComponent(...),
/// );
///
/// final particle = pool.acquire();
/// // Usar la partícula...
/// pool.release(particle);
/// ```
class ComponentPool<T extends Component> {
  ComponentPool({
    required this.factory,
    this.maxSize = 100,
    this.preloadSize = 0,
  }) {
    // Precargar objetos si se especificó
    if (preloadSize > 0) {
      for (var i = 0; i < preloadSize; i++) {
        _available.add(factory());
      }
    }
  }

  /// Función que crea nuevas instancias del componente
  final T Function() factory;

  /// Tamaño máximo del pool (para evitar memory leaks)
  final int maxSize;

  /// Número de objetos a precargar al inicializar el pool
  final int preloadSize;

  /// Lista de objetos disponibles para reutilizar
  final List<T> _available = [];

  /// Lista de objetos actualmente en uso (para debugging)
  final List<T> _inUse = [];

  /// Obtiene un objeto del pool (crea uno nuevo si no hay disponibles)
  T acquire() {
    T component;

    if (_available.isNotEmpty) {
      component = _available.removeLast();
    } else {
      component = factory();
    }

    _inUse.add(component);
    return component;
  }

  /// Devuelve un objeto al pool para reutilizarlo
  ///
  /// IMPORTANTE: El componente debe ser removido del parent antes de liberarlo
  void release(T component) {
    _inUse.remove(component);

    // Solo añadir al pool si no hemos alcanzado el tamaño máximo
    if (_available.length < maxSize) {
      _available.add(component);
    }
  }

  /// Libera todos los objetos del pool (útil para cleanup)
  void clear() {
    _available.clear();
    _inUse.clear();
  }

  /// Estadísticas del pool (para debugging/profiling)
  PoolStats get stats => PoolStats(
    available: _available.length,
    inUse: _inUse.length,
    maxSize: maxSize,
  );
}

/// Estadísticas del pool de objetos
class PoolStats {
  const PoolStats({
    required this.available,
    required this.inUse,
    required this.maxSize,
  });

  final int available;
  final int inUse;
  final int maxSize;

  double get utilization => (inUse / maxSize) * 100;

  @override
  String toString() =>
      'PoolStats(available: $available, inUse: $inUse, '
      'maxSize: $maxSize, utilization: ${utilization.toStringAsFixed(1)}%)';
}
