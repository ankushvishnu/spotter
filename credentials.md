# Spotter Supabase Credentials

## ⚠️ IMPORTANT: Keep these credentials secret!

### Your Supabase Project Details:

**Project URL:**
```
https://wflqpizdtuiiaicfuuby.supabase.co
```

**Anon/Public Key:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmbHFwaXpkdHVpaWFpY2Z1dWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzM2NjksImV4cCI6MjA4ODcwOTY2OX0.TG8fw3HTK2Ar8shwpfC81rd9E25jFjp8icsc5XXfClQ
```

### Update main.dart:

Replace this code in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

With:

```dart
await Supabase.initialize(
  url: 'https://wflqpizdtuiiaicfuuby.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmbHFwaXpkdHVpaWFpY2Z1dWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzM2NjksImV4cCI6MjA4ODcwOTY2OX0.TG8fw3HTK2Ar8shwpfC81rd9E25jFjp8icsc5XXfClQ',
);
```

---

## 🔒 Security Notes:

1. **Never commit these credentials to Git**
2. Add `.env` files to `.gitignore`
3. For production, use environment variables
4. The anon key is safe to use in mobile apps (RLS protects your data)
5. Never expose your service_role key in client apps

---

## Next Steps:

1. Copy these credentials
2. Update `lib/main.dart`
3. Run `flutter pub get`
4. Run `flutter run`
5. Click "Run All Tests" button