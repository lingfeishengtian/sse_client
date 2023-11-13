import 'dart:async';
import 'dart:convert';

typedef RetryIndicator = void Function(Duration retry);

class EventSourceTransformer implements StreamTransformer<List<int>, Event> {
  RetryIndicator? retryIndicator;

  EventSourceTransformer({this.retryIndicator});

  @override
  Stream<Event> bind(Stream<List<int>> stream) {
    late StreamController<Event> controller;
    controller = StreamController(onListen: () {
      // the event we are currently building
      var currentEvent = Event();
      // This stream will receive chunks of data that is not necessarily a
      // single event. So we build events on the fly and broadcast the event as
      // soon as we encounter a double newline, then we start a new one.
      stream
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen((String line) {
        if (line.isEmpty) {
          // event is done
          // strip ending newline from data
          if (currentEvent.data != null) {
            var match = currentEvent.data!.split('\n');
            currentEvent.data = match[0];
          }
          controller.add(currentEvent);
          currentEvent = Event();
          return;
        }
        final ind = line.indexOf(':');
        final match = [line.substring(0, ind), line.substring(ind + 1)];
        var field = match[0];
        var value = match[1];
        if (field.isEmpty) {
          // lines starting with a colon are to be ignored
          return;
        }
        switch (field) {
          case 'event':
            currentEvent.event = value;
            break;
          case 'data':
            currentEvent.data = (currentEvent.data ?? '') + value + '\n';
            break;
          case 'id':
            currentEvent.id = value;
            break;
          case 'retry':
            if (retryIndicator != null) {
              retryIndicator!(Duration(milliseconds: int.parse(value)));
            }
            break;
        }
      });
    });
    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, Event, RS, RT>(this);
}

class Event implements Comparable<Event> {
  Event({this.id, this.event, this.data});

  Event.message({this.id, this.data}) : event = 'message';

  /// An identifier that can be used to allow a client to replay
  /// missed Events by returning the Last-Event-Id header.
  /// Return empty string if not required.
  String? id;

  /// The name of the event. Return empty string if not required.
  String? event;

  /// The payload of the event.
  String? data;

  @override
  int compareTo(Event other) => id!.compareTo(other.id!);
}
