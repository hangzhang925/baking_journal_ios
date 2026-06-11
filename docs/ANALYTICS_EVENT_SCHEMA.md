# Analytics Event Schema

This document is the source of truth for Firebase Analytics / GA4 events emitted by Bready.

## Naming Rules

- Use lowercase `snake_case` event and parameter names.
- Event and parameter names must start with a letter and use only letters, numbers, and underscores.
- Do not use reserved names or reserved prefixes such as `firebase_`, `ga_`, or `google_`.
- Keep event names stable. Put variable details in parameters instead of creating many event-name variants.
- Do not send user-authored content such as recipe names, notes, ingredient names, or free-form text.
- Do not manually attach generic device/app metadata to every event. Firebase / GA4 stores that as built-in event context.

References:

- [Firebase Analytics: Log events](https://firebase.google.com/docs/analytics/ios/events)
- [Firebase Analytics: DebugView](https://firebase.google.com/docs/analytics/debugview)
- [GA4 event naming rules](https://support.google.com/analytics/answer/13316687)
- [Firebase Analytics parameter limits](https://firebase.google.com/docs/reference/cpp/group/parameter-names)
- [GA4 BigQuery export schema](https://support.google.com/analytics/answer/7029846)

## Built-In Event Context

Custom events should only carry product-specific parameters. Firebase / GA4 automatically stores common app and device context alongside each event, including:

| Context | Where it appears in BigQuery export | Notes |
| --- | --- | --- |
| App instance identifier | `user_pseudo_id` | Pseudonymous app-instance identifier. Do not send your own device ID. |
| Platform | `platform` | For this app, expected value is `IOS`. |
| Bundle ID | `app_info.id` | Expected value is `com.openbakery.bready`. |
| Firebase app ID | `app_info.firebase_app_id` | Comes from `GoogleService-Info.plist`. |
| App version | `app_info.version` | The app short bundle version. |
| Device category | `device.category` | Example values include mobile and tablet. |
| Device model | `device.mobile_model_name` / `device.mobile_marketing_name` | GA4-managed device metadata. |
| OS | `device.operating_system` | For this app, expected value is iOS. |
| OS version | `device.operating_system_version` | iOS version. |
| Language | `device.language` | OS language. |

In GA4 reports, use these as built-in dimensions or comparisons. In BigQuery, query them as top-level columns or nested records instead of adding duplicate event parameters.

## Events

### `nav_tab_click`

Fires when the user taps a bottom navigation tab.

| Parameter | Type | Required | Allowed values | Description |
| --- | --- | --- | --- | --- |
| `tab_name` | string | yes | `formula`, `history`, `starter`, `settings` | The bottom navigation tab the user tapped. |

Example:

```swift
Analytics.logEvent("nav_tab_click", parameters: [
    "tab_name": "formula"
])
```
