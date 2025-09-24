
# Set Up Logs | Sentry for Flutter

With Sentry Structured Logs, you can send text-based log information from your applications to Sentry. Once in Sentry, these logs can be viewed alongside relevant errors, searched by text-string, or searched using their individual attributes.

## [Requirements](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#requirements)

Logs for Flutter are supported in Sentry Flutter SDK version `9.0.0` and above.

## [Setup](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#setup)

To enable logging, you need to initialize the SDK with the `enableLogs` option set to `true`.

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = "https://examplePublicKey@o0.ingest.sentry.io/0
example-org / example-project
";
    // Enable logs to be sent to Sentry
    options.enableLogs = true;
  },
);
```

## [Usage](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#usage)

Once the feature is enabled on the SDK and the SDK is initialized, you can send logs using the `Sentry.logger` APIs.

The `logger` namespace exposes six methods that you can use to log messages at different log levels: `trace`, `debug`, `info`, `warning`, `error`, and `fatal`.

Aside from the primary logging methods, we've provided a format text function, `Sentry.logger.fmt`, that you can use to insert properties into to your log entries.

These properties will be sent to Sentry, and can be searched from within the Logs UI, and even added to the Logs views as a dedicated column.

When using the `fmt` function, you must use the `%s` placeholder for each value you want to insert.

```dart
Sentry.logger.fmt.error('Uh oh, something broke, here is the error: %s', [
  errorMsg
], attributes: {
  'additional_info': SentryLogAttribute.string('some info'),
});
Sentry.logger.fmt.info("%s added %s to cart.", [user.username, product.name]);
```

You can also pass additional attributes directly to the logging functions, avoiding the need to use the `fmt` function.

```dart
Sentry.logger.error('Uh oh, something broke, here is the error: $errorMsg',
    attributes: {
      'error': SentryLogAttribute.string(errorMsg),
      'some_info': SentryLogAttribute.string('some info'),
    });
Sentry.logger.info('User ${user.username} added ${product.name} to cart.', attributes: {
  'user': SentryLogAttribute.string(user.username),
  'product': SentryLogAttribute.string(product.name),
});
```

## [Options](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#options)

#### [beforeSendLog](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#beforesendlog)

To filter logs, or update them before they are sent to Sentry, you can use the `beforeSendLog` option.

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = "https://examplePublicKey@o0.ingest.sentry.io/0
example-org / example-project
";
    options.beforeSendLog = (log) {
      if (log.level == SentryLogLevel.info) {
        // Filter out all info logs
        return null;
      }

      return log;
    };
  },
);
```

The `beforeSend` function receives a log object, and should return the log object if you want it to be sent to Sentry, or `null` if you want to discard it.

## [Default Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#default-attributes)

The Flutter SDK automatically sets several default attributes on all log entries to provide context and improve debugging:

### [Core Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#core-attributes)

* `environment`: The environment set in the SDK if defined. This is sent from the SDK as `sentry.environment`.
* `release`: The release set in the SDK if defined. This is sent from the SDK as `sentry.release`.
* `trace.parent_span_id`: The span ID of the span that was active when the log was collected (only set if there was an active span). This is sent from the SDK as `sentry.trace.parent_span_id`.
* `sdk.name`: The name of the SDK that sent the log. This is sent from the SDK as `sentry.sdk.name`. This is sent from the SDK as `sentry.sdk.name`.
* `sdk.version`: The version of the SDK that sent the log. This is sent from the SDK as `sentry.sdk.version`. This is sent from the SDK as `sentry.sdk.version`.

### [Message Template Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#message-template-attributes)

If the log was paramaterized, Sentry adds the message template and parameters as log attributes.

* `message.template`: The parameterized template string. This is sent from the SDK as `sentry.message.template`.
* `message.parameter.X`: The parameters to fill the template string. X can either be the number that represent the parameter's position in the template string (`sentry.message.parameter.0`, `sentry.message.parameter.1`, etc) or the parameter's name (`sentry.message.parameter.item_id`, `sentry.message.parameter.user_id`, etc). This is sent from the SDK as `sentry.message.parameter.X`.

For example, with the following log:

```dart
Sentry.logger.fmt.info("%s added %s to cart.", ["John", "Product 1"]);
```

Sentry will add the following attributes:

* `message.template`: "%s added %s to cart."
* `message.parameter.0`: "John"
* `message.parameter.1`: "Product 1"

### [User Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#user-attributes)

* `user.id`: The user ID. Maps to id in the User payload, which is set by default by the SDKs.

If user information is available in the current scope, the following attributes are added to the log:

* `user.name`: The username. Maps to username in the User payload.
* `user.email`: The email address. Maps to email in the User payload.

### [Message Template Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#message-template-attributes)

If the log was paramaterized (like with `Sentry.logger().error("A %s log message", "formatted");`), Sentry adds the message template and parameters as log attributes.

### [Integration Attributes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#integration-attributes)

If a log is generated by an SDK integration, the SDK will set additional attributes to help you identify the source of the log.

* `origin`: The origin of the log. This is sent from the SDK as `sentry.origin`.

## [Troubleshooting](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#troubleshooting)

### [Missing Logs for Crashes](https://docs.sentry.io/platforms/dart/guides/flutter/logs.md#missing-logs-for-crashes)

Logs can get lost in certain crash scenarios, if the SDK can not send the logs before the app terminates. We are [currently working on improving](https://github.com/getsentry/sentry-dart/issues/3227) this to ensure that all logs are sent, at the latest on the next app restart.
