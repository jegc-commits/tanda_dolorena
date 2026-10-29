import 'package:flutter_test/flutter_test.dart';
import 'package:tanda_dolorena/modelos/participante.dart';
import 'package:tanda_dolorena/modelos/tanda.dart';
import 'package:tanda_dolorena/logica/resultado_aportacion.dart';
import 'package:tanda_dolorena/logica/resultado_cierre.dart';
import 'package:tanda_dolorena/logica/servicio_tanda.dart';

Tanda _crearTandaDePrueba() {
  return Tanda(
    participantes: [
      Participante(id: 'p1', nombre: 'Ana'),
      Participante(id: 'p2', nombre: 'Beto'),
      Participante(id: 'p3', nombre: 'Carla'),
    ],
    ordenTurnos: ['p1', 'p2', 'p3'],
    montoAportacion: 200,
  );
}

void main() {
  test('registrar una aportacion valida la agrega a la ronda actual', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    final resultado = servicio.registrarAportacion('p1');
    expect(resultado, ResultadoAportacion.registrada);
    expect(tanda.aportacionesRondaActual.contains('p1'), true);
  });

  test('un participante no puede aportar dos veces en la misma ronda', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    servicio.registrarAportacion('p1');
    final segundoIntento = servicio.registrarAportacion('p1');
    expect(segundoIntento, ResultadoAportacion.yaAporto);
  });

  test('alguien que no pertenece a la tanda no puede aportar', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    final resultado = servicio.registrarAportacion('desconocido');
    expect(resultado, ResultadoAportacion.participanteInvalido);
  });

  test('puedeCerrarRonda es falso si falta algun participante por aportar', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    servicio.registrarAportacion('p1');
    servicio.registrarAportacion('p2');
    expect(servicio.puedeCerrarRonda(), false);
  });

  test('puedeCerrarRonda es verdadero cuando todos ya aportaron', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    servicio.registrarAportacion('p1');
    servicio.registrarAportacion('p2');
    servicio.registrarAportacion('p3');
    expect(servicio.puedeCerrarRonda(), true);
  });

  test('cerrar la ronda entrega el turno al beneficiario y avanza', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    servicio.registrarAportacion('p1');
    servicio.registrarAportacion('p2');
    servicio.registrarAportacion('p3');
    final cierre = servicio.cerrarRondaYAvanzar();

    expect(cierre.resultado, ResultadoCierre.rondaCerrada);
    expect(cierre.beneficiario!.id, 'p1');
    expect(
      tanda.participantes.firstWhere((p) => p.id == 'p1').yaRecibioTurno,
      true,
    );
    expect(tanda.turnoActual, 1);
    expect(tanda.aportacionesRondaActual.isEmpty, true);
  });

  test('no se puede cerrar la ronda si algun participante no ha aportado', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    servicio.registrarAportacion('p1');
    servicio.registrarAportacion('p2');
    final cierre = servicio.cerrarRondaYAvanzar();

    expect(cierre.resultado, ResultadoCierre.faltanAportaciones);
    expect(cierre.beneficiario, isNull);
    expect(tanda.turnoActual, 0);
  });

  test('haTerminado es falso mientras queden turnos pendientes', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    expect(servicio.haTerminado(), false);
  });

  test('haTerminado es verdadero cuando todos ya recibieron su turno', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    for (final id in ['p1', 'p2', 'p3']) {
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      servicio.registrarAportacion('p3');
      servicio.cerrarRondaYAvanzar();
    }
    expect(servicio.haTerminado(), true);
  });

  test('no se puede aportar una vez que la tanda ha terminado', () {
    final tanda = _crearTandaDePrueba();
    final servicio = ServicioTanda(tanda);
    for (final id in ['p1', 'p2', 'p3']) {
      servicio.registrarAportacion('p1');
      servicio.registrarAportacion('p2');
      servicio.registrarAportacion('p3');
      servicio.cerrarRondaYAvanzar();
    }
    final resultado = servicio.registrarAportacion('p1');
    expect(resultado, ResultadoAportacion.tandaTerminada);
  });

  test(
    'simulacion completa: 3 vecinas completan una tanda de principio a fin',
    () {
      final tanda = _crearTandaDePrueba();
      final servicio = ServicioTanda(tanda);
      final beneficiarios = <String>[];

      while (!servicio.haTerminado()) {
        for (final p in tanda.participantes) {
          servicio.registrarAportacion(p.id);
        }
        final cierre = servicio.cerrarRondaYAvanzar();
        beneficiarios.add(cierre.beneficiario!.id);
      }

      expect(beneficiarios, ['p1', 'p2', 'p3']);
      expect(tanda.participantes.every((p) => p.yaRecibioTurno), true);
      expect(
        servicio.registrarAportacion('p1'),
        ResultadoAportacion.tandaTerminada,
      );
    },
  );
}
