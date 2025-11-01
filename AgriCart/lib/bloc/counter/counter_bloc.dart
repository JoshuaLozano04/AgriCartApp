import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
  }

  void _onIncremented(
    CounterIncremented event,
    Emitter<CounterState> emit,
  ) {
    emit(CounterState(value: state.value + 1));
  }

  void _onDecremented(
    CounterDecremented event,
    Emitter<CounterState> emit,
  ) {
    emit(CounterState(value: state.value - 1));
  }

  void _onReset(
    CounterReset event,
    Emitter<CounterState> emit,
  ) {
    emit(const CounterState(value: 0));
  }
}

