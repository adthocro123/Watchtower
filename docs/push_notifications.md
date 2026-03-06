# Push Notifications Setup

This project uses Web Push (VAPID) for assignment reminders and test notifications.

## 1) Generate VAPID Keys

Run in Rails console or runner:

```ruby
keys = Webpush.generate_key
puts keys.public_key
puts keys.private_key
```

## 2) Configure Environment Variables

Set these values for your app process:

- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`
- `VAPID_SUBJECT` (recommended, e.g. `mailto:you@example.com`)

Without these, the notification UI will show unavailable/not configured.

## 3) Browser Requirements

- Must be secure context (`https://` or `http://localhost`)
- Must support `ServiceWorker`, `Notification`, and `PushManager`
- User must grant notification permission

## 4) Verify End-to-End

1. Open `Scouting Schedule`
2. Click `Enable Push Notifications`
3. Click `Send Test Notification`
4. Confirm notification appears

If no notification appears:

- open browser console and check status text from `push-subscription` controller
- ensure VAPID env vars are present in Rails process
- verify browser supports Push API on your platform/build
