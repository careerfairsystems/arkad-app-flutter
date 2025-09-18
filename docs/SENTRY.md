# Usage | Sentry for Flutter

Sentry's SDK hooks into your runtime environment and automatically reports errors, uncaught exceptions, and unhandled rejections as well as other types of errors depending on the platform.

Key terms:

* An *event* is one instance of sending data to Sentry. Generally, this data is an error or exception.
* An *issue* is a grouping of similar events.
* The reporting of an event is called *capturing*. When an event is captured, it’s sent to Sentry.

The most common form of capturing is to capture errors. What can be captured as an error varies by platform. In general, if you have something that looks like an exception, it can be captured. For some SDKs, you can also omit the argument to `captureException` and Sentry will attempt to capture the current exception. It is also useful for manual reporting of errors or messages to Sentry.

While capturing an event, you can also record the breadcrumbs that lead up to that event. Breadcrumbs are different from events: they will not create an event in Sentry, but will be buffered until the next event is sent. Learn more about breadcrumbs in our [Breadcrumbs documentation](https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/breadcrumbs.md).

## [Capturing Errors](https://docs.sentry.io/platforms/dart/guides/flutter/usage.md#capturing-errors)

### [FlutterError.onError](https://docs.sentry.io/platforms/dart/guides/flutter/usage.md#fluttererroronerror)

Flutter-specific errors, such as using `FlutterError.onError`, are captured automatically.

### [PlatformDispatcher.onError / runZonedGuarded](https://docs.sentry.io/platforms/dart/guides/flutter/usage.md#platformdispatcheronerror--runzonedguarded)

The SDK already runs your init `callback` on an error handler, such as [`runZonedGuarded`](https://api.flutter.dev/flutter/dart-async/runZonedGuarded.html) on Flutter versions prior to `3.3`, or [`PlatformDispatcher.onError`](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html) on Flutter versions 3.3 and higher, so that errors are automatically captured.

If you need a custom error handling zone which also provides automatic error reporting and breadcrumb tracking, use `Sentry.runZonedGuarded`. It wraps Dart's native [`runZonedGuarded`](https://api.flutter.dev/flutter/dart-async/runZonedGuarded.html) function with Sentry-specific functionality.

This function automatically records calls to `print()` as `Breadcrumbs` and can be configured using `SentryOptions.enablePrintBreadcrumbs`.

```dart
Sentry.runZonedGuarded(() async {
  WidgetsBinding.ensureInitialized();

  // Errors before init will not be handled by Sentry

  await SentryFlutter.init(
    (options) {
    ...
    },
    appRunner: () => runApp(MyApp()),
  );
}, (error, stackTrace) {
  // Automatically sends errors to Sentry, no need to do any
  // captureException calls on your part.
  // On top of that, you can do your own custom stuff in this callback.
});
```

## [Capturing Messages](https://docs.sentry.io/platforms/dart/guides/flutter/usage.md#capturing-messages)

Another common operation is to capture a bare message. A message is textual information that should be sent to Sentry. Typically, our SDKs don't automatically capture messages, but you can capture them manually.

Messages show up as issues on your issue stream, with the message as the issue name.

```dart
import 'package:sentry/sentry.dart';

await Sentry.captureMessage('Something went wrong');
```

