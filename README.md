# Server Sent Events client package.

This package provides support for bi-directional communication through Server Sent Events and corresponding POST requests. It's platform-independent, and can be used on both the command-line and the browser.

## lingfeishengtian's Changes

The main thing I change here is the dependency on RegEx. Currently, there is a bug in RegEx that causes stack overflow when built with Dart AOT. In addition, using RegEx in the scenario that was used here is a bit of an overkill. So I replaced it with a simple string search.

## Usage

A simple usage example:

```dart
import 'package:sse_client/sse_client.dart';

void main() {
  final sseClient = SseClient.connect(Uri.parse('http://localhost:5000/stream?channel=messages'));

  sseClient.stream.listen((String? event) {
    print(event);
  });                                   
}
```
