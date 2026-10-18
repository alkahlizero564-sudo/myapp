# My apps: خطوات التشغيل

## 1) إنشاء المشروع
```
flutter create --org com.myapps --project-name my_apps --platforms=android my_apps
```
ثم انسخ الملفات فوق المشروع بنفس المسارات:

```
pubspec.yaml
lib/main.dart
lib/theme.dart
lib/services/store.dart
lib/services/util.dart
lib/services/ai_service.dart
lib/services/github_service.dart
lib/services/workflow_template.dart
lib/services/supabase_service.dart
lib/services/build_service.dart
lib/screens/keys_screen.dart
lib/screens/apps_screen.dart
lib/screens/build_screen.dart
lib/screens/preview_screen.dart
```
وبعدها: `flutter pub get`

## 2) تعديل android/app/src/main/AndroidManifest.xml
قبل وسم `<application` أضف:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```
وداخل وسم `<application` أضف السمة التالية (تحتاجها المعاينة الفعلية لأنها تعمل على 127.0.0.1):
```xml
android:usesCleartextTraffic="true"
```

## 3) المفاتيح المطلوبة
- **GitHub Token:** من Settings > Developer settings > Personal access tokens (classic) بصلاحيتي `repo` و `workflow`.
- **اسم المستودع:** `myapp`. إن لم يكن موجوداً ينشئه التطبيق **خاصاً (private)** تلقائياً.
- **Supabase Access Token:** من Account > Access Tokens. و**Project Ref** من رابط مشروعك.
- **Gemini / Claude:** مفاتيح API الخاصة بك.

## 4) ملاحظات مهمة
- **اسم الحزمة ثابت لكل تطبيق** (`com.myapps.app1` و `com.myapps.app2`)، ومفتاح التوقيع يُنشأ مرة واحدة لكل تطبيق ويُحفظ في المجلد `keys/` داخل المستودع. لذلك **أبقِ المستودع خاصاً دائماً**، واحتفظ بنسخة من مجلد `keys/` في مكان آمن: لو ضاع المفتاح فلن تتحدث النسخ فوق بعضها.
- اسم نموذج Gemini في `ai_service.dart` هو `gemini-3.8-flash`. إن تغيّر الاسم عند Google عدّل الثابت `geminiModel`.
- أي كود SQL يحتوي أمر حذف (`drop table` أو `truncate` أو `delete from`) يرفضه التطبيق قبل تنفيذه.
- الكود لم يُترجَم ولم يُجرَّب على جهاز، فقد يحتاج تصحيحات صغيرة عند أول `flutter run`. أرسل لي أي خطأ يظهر وأصلحه.
