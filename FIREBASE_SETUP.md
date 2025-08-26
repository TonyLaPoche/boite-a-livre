# 🔥 Configuration Firebase pour Boîte à Livre

## 📋 Prérequis

1. **Compte Google** avec accès à [Firebase Console](https://console.firebase.google.com/)
2. **Projet Flutter** configuré et fonctionnel
3. **Xcode** (pour iOS) et **Android Studio** (pour Android)

## 🚀 Étapes de configuration

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur **"Créer un projet"**
3. Donnez un nom à votre projet (ex: "boite-a-livre")
4. Activez Google Analytics (recommandé)
5. Cliquez sur **"Créer le projet"**

### 2. Ajouter votre application iOS

1. Dans Firebase Console, cliquez sur l'icône iOS
2. Entrez votre **Bundle ID** : `com.antoineterrade.boite-a-livre`
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Remplacez le fichier `ios/Runner/GoogleService-Info.plist` par celui-ci

### 3. Ajouter votre application Android

1. Dans Firebase Console, cliquez sur l'icône Android
2. Entrez votre **Package name** : `com.antoineterrade.boite-a-livre`
3. Téléchargez le fichier `google-services.json`
4. Remplacez le fichier `android/app/google-services.json` par celui-ci

### 4. Activer l'authentification

1. Dans Firebase Console, allez dans **"Authentication"**
2. Cliquez sur **"Get started"**
3. Dans l'onglet **"Sign-in method"**, activez :
   - **Google** (avec votre projet Google Cloud)
   - **Apple** (pour iOS)

### 5. Configuration Google Cloud (pour Google Sign-In)

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet Firebase
3. Allez dans **"APIs & Services" > "Credentials"**
4. Créez un **OAuth 2.0 Client ID** pour iOS et Android
5. Copiez les **Client ID** et **Reversed Client ID**

### 6. Mise à jour des fichiers de configuration

#### iOS - Info.plist
Remplacez `VOTRE_REVERSED_CLIENT_ID` dans `ios/Runner/Info.plist` par votre vrai Reversed Client ID.

#### Android - google-services.json
Le fichier téléchargé contient déjà les bonnes informations.

## 🔧 Test de l'authentification

1. Lancez l'application : `flutter run`
2. Testez la connexion Google et Apple
3. Vérifiez dans Firebase Console que l'utilisateur apparaît

## ⚠️ Problèmes courants

### Erreur "Google Sign-In failed"
- Vérifiez que le Bundle ID/Package name correspond
- Assurez-vous que Google Sign-In est activé dans Firebase
- Vérifiez les permissions dans Google Cloud Console

### Erreur "Sign in with Apple not available"
- Vérifiez que vous testez sur un appareil iOS
- Assurez-vous que Sign in with Apple est activé dans Firebase

### Erreur de compilation
- Exécutez `flutter clean` puis `flutter pub get`
- Pour iOS : `cd ios && pod install`

## 📱 Configuration finale

Une fois configuré, votre application pourra :
- ✅ Se connecter avec Google
- ✅ Se connecter avec Apple (iOS)
- ✅ Stocker les données utilisateur dans Firebase
- ✅ Gérer l'état d'authentification

## 🆘 Support

Si vous rencontrez des problèmes :
1. Vérifiez la [documentation Firebase](https://firebase.flutter.dev/)
2. Consultez les [forums Flutter](https://flutter.dev/community)
3. Vérifiez les logs de l'application
