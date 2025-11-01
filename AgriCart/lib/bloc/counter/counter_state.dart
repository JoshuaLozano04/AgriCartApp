import 'package:equatable/equatable.dart';

class CounterState extends Equatable {
  final int value;

  const CounterState({this.value = 0});

  @override
  List<Object> get props => [value];
}

