import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tinkoff_acquiring_sdk/models/tinkoff_receipt.dart';
import 'package:tinkoff_acquiring_sdk/tinkoff_acquiring_models.dart';

import 'models/tinkoff_shop.dart';

/// Maps Dart-styled enum .toString() to other-languages-styled
/// (Dart) "TinkoffLanguage.RU" -> (Others) RU
/// etc...
String? _mapEnumToString(dynamic value) => value?.toString()?.split('.')?.last;

/// Due to some inconsistencies introduced in language handling of SDK iOS and Android versions it has to be mapped explicitly
String? _mapLanguageToPlatform(TinkoffLanguage value) => Platform.isIOS
    ? _mapEnumToString(value)?.toLowerCase()
    : _mapEnumToString(value);

/// Internal enum that handles SDK initialization status
enum TinkoffAcquiringSdkStatus {
  NOT_INITIALIZED,
  INITIALIZATION_ERROR,
  INITIALIZED
}

/// Native versions of SDK call handler
class TinkoffAcquiringSdk {
  static const MethodChannel _channel =
      const MethodChannel('eu.nk2/tinkoff_acquiring_sdk');

  /// Enable usage of test Tinkoff API servers
  final bool isDeveloperMode;

  /// Enable logging
  final bool isDebug;

  /// Terminal key given to you by Tinkoff
  final String terminalKey;

  /// Public key given to you by Tinkoff
  final String publicKey;

  /// (!) Android specific
  /// Enables google pay and calls its initialization routine
  final bool enableGooglePay;

  /// Require an address from user when collecting a payment
  final bool requireAddress;

  /// Require a phone from user when collecting a payment
  final bool requirePhone;

  TinkoffAcquiringSdkStatus _status = TinkoffAcquiringSdkStatus.NOT_INITIALIZED;

  TinkoffAcquiringSdk({
    this.isDeveloperMode = false,
    this.isDebug = false,
    required this.terminalKey,
    required this.publicKey,
    this.enableGooglePay = false,
    this.requireAddress = false,
    this.requirePhone = false,
  })  : assert(terminalKey != null),
        assert(publicKey != null),
        assert(!enableGooglePay || (enableGooglePay && Platform.isAndroid));

  /// Initialize SDK
  ///
  /// Must be called once, otherwise
  /// - if [exceptAlreadyInitialized] is [true] then throw [TinkoffError]
  ///   else do nothing
  Future<TinkoffAcquiringInitializationResponse> initialize(
      {bool exceptAlreadyInitialized = true}) async {
    if (_status != TinkoffAcquiringSdkStatus.INITIALIZED) {
      if (exceptAlreadyInitialized)
        throw TinkoffError(
            message:
                'Plugin was already initialized when the initialize() was called.');
    }

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('initialize', {
      'isDeveloperMode': this.isDeveloperMode,
      'isDebug': this.isDebug,
      'terminalKey': this.terminalKey,
      'publicKey': this.publicKey.replaceAll('\n', ''), //iOS shits about it
      'enableGooglePay': this.enableGooglePay,
      'requireAddress': this.requireAddress,
      'requirePhone': this.requirePhone,
    });

    final TinkoffAcquiringInitializationResponse status =
        TinkoffAcquiringInitializationResponse.fromJson(
            response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringInitializationStatus.RESULT_ERROR) {
      _status = TinkoffAcquiringSdkStatus.INITIALIZATION_ERROR;
      throw TinkoffError(message: status.error);
    }

    if (status.status ==
        TinkoffAcquiringInitializationStatus.FLUTTER_NOT_INITIALIZED) {
      _status = TinkoffAcquiringSdkStatus.INITIALIZATION_ERROR;
      throw TinkoffError(
          message:
              'Flutter was not initialized when the initialize() was called.');
    }

    _status = TinkoffAcquiringSdkStatus.INITIALIZED;
    if (status.status ==
        TinkoffAcquiringInitializationStatus.PLUGIN_ALREADY_INITIALIZED) {
      if (exceptAlreadyInitialized)
        throw TinkoffError(
            message:
                'Plugin was already initialized when the initialize() was called.');
    }

    return status;
  }

  /// Open card attachment process screen
  Future<TinkoffCommonResponse> openAttachCardScreen(
      {required String customerId,
      TinkoffCheckType? checkType,
      String? email,
      bool? enableSecureKeyboard,
      bool? enableCameraCardScanner,
      TinkoffDarkThemeMode? darkThemeMode,
      required TinkoffLanguage language}) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(customerId != null);
    assert(language != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openAttachCardScreen', {
      'customerId': customerId,
      'checkType': checkType != null ? _mapEnumToString(checkType) : null,
      'email': email,
      'enableSecureKeyboard': enableSecureKeyboard,
      'enableCameraCardScanner': enableCameraCardScanner,
      'darkThemeMode': _mapEnumToString(darkThemeMode),
      'language': _mapLanguageToPlatform(language)
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }

  /// Open card payment process screen
  Future<TinkoffCommonResponse> openPaymentScreen({
    required String orderId,
    required String title,
    required String description,
    required double money,
    bool? recurrentPayment,
    required String customerId,
    TinkoffCheckType? checkType,
    String? email,
    bool? enableSecureKeyboard,
    bool? enableCameraCardScanner,
    TinkoffDarkThemeMode? darkThemeMode,
    required TinkoffLanguage language,
    List<TinkoffShop>? shops,
    TinkoffReceipt? receipt,
    bool emailRequired = false,
  }) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(orderId != null);
    assert(title != null);
    assert(description != null);
    assert(money != null);
    assert(customerId != null);
    assert(language != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openPaymentScreen', {
      'orderId': orderId,
      'title': title,
      'description': description,
      'money': money,
      'recurrentPayment': recurrentPayment,
      'customerId': customerId,
      'checkType': checkType != null ? _mapEnumToString(checkType) : null,
      'email': email,
      'enableSecureKeyboard': enableSecureKeyboard,
      'enableCameraCardScanner': enableCameraCardScanner,
      'darkThemeMode': _mapEnumToString(darkThemeMode),
      'language': _mapLanguageToPlatform(language),
      'emailRequired': emailRequired,
      'shops': shops?.map((item) => item.toMap())?.toList(),
      'receipt': receipt?.toMap(),
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }

  /// (!) Android-specific
  /// Open google pay payment process screen
  Future<TinkoffCommonResponse> openGooglePay(
      {required String orderId,
      required String title,
      required String description,
      required double money,
      bool? recurrentPayment,
      required String customerId,
      TinkoffCheckType? checkType,
      String? email,
      bool? enableSecureKeyboard,
      bool? enableCameraCardScanner,
      TinkoffDarkThemeMode? darkThemeMode,
      List<TinkoffShop>? shops,
      TinkoffReceipt? receipt,
      required TinkoffLanguage language}) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(Platform.isAndroid);
    assert(orderId != null);
    assert(title != null);
    assert(description != null);
    assert(money != null);
    assert(customerId != null);
    assert(language != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openGooglePay', {
      'orderId': orderId,
      'title': title,
      'description': description,
      'money': money,
      'recurrentPayment': recurrentPayment,
      'customerId': customerId,
      'checkType': checkType != null ? _mapEnumToString(checkType) : null,
      'email': email,
      'enableSecureKeyboard': enableSecureKeyboard,
      'enableCameraCardScanner': enableCameraCardScanner,
      'darkThemeMode': _mapEnumToString(darkThemeMode),
      'language': _mapLanguageToPlatform(language),
      'shops': shops?.map((item) => item.toMap())?.toList(),
      'receipt': receipt?.toMap(),
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }

  /// (!) iOS-specific
  /// Open apple pay payment process screen
  Future<TinkoffCommonResponse> openApplePay(
      {required String orderId,
      required String title,
      required String description,
      required double money,
      bool? recurrentPayment,
      required String customerId,
      TinkoffCheckType? checkType,
      String? email,
      required TinkoffLanguage language,
      List<TinkoffShop>? shops,
      TinkoffReceipt? receipt,
      bool emailRequired = false,
      required String merchantIdentifier}) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(Platform.isIOS);
    assert(orderId != null);
    assert(title != null);
    assert(description != null);
    assert(money != null);
    assert(customerId != null);
    assert(language != null);
    assert(merchantIdentifier != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openApplePay', {
      'orderId': orderId,
      'title': title,
      'description': description,
      'money': money,
      'recurrentPayment': recurrentPayment,
      'customerId': customerId,
      'checkType': checkType != null ? _mapEnumToString(checkType) : null,
      'email': email,
      'language': _mapLanguageToPlatform(language),
      'merchantIdentifier': merchantIdentifier,
      'shops': shops?.map((item) => item.toMap())?.toList(),
      'emailRequired': emailRequired,
      'receipt': receipt?.toMap(),
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }

  /// Open QR payment process screen
  Future<TinkoffCommonResponse> openPaymentQrScreen(
      {bool? enableSecureKeyboard,
      bool? enableCameraCardScanner,
      TinkoffDarkThemeMode? darkThemeMode,
      required TinkoffLanguage language}) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(language != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openPaymentQrScreen', {
      'enableSecureKeyboard': enableSecureKeyboard,
      'enableCameraCardScanner': enableCameraCardScanner,
      'darkThemeMode': _mapEnumToString(darkThemeMode),
      'language': _mapLanguageToPlatform(language)
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }

  /// Open saved cards screen
  Future<TinkoffCommonResponse> openSavedCardsScreen(
      {required String customerId,
      TinkoffCheckType? checkType,
      String? email,
      bool? enableSecureKeyboard,
      bool? enableCameraCardScanner,
      TinkoffDarkThemeMode? darkThemeMode,
      required TinkoffLanguage language}) async {
    assert(_status == TinkoffAcquiringSdkStatus.INITIALIZED);
    assert(customerId != null);
    assert(language != null);

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('openSavedCardsScreen', {
      'customerId': customerId,
      'checkType': checkType != null ? _mapEnumToString(checkType) : null,
      'email': email,
      'enableSecureKeyboard': enableSecureKeyboard,
      'enableCameraCardScanner': enableCameraCardScanner,
      'darkThemeMode': _mapEnumToString(darkThemeMode),
      'language': _mapLanguageToPlatform(language)
    });

    final TinkoffCommonResponse status =
        TinkoffCommonResponse.fromJson(response.cast<String, dynamic>());

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NO_ACTIVITY)
      throw TinkoffError(message: 'Plugin is running without activity.');

    if (status.status == TinkoffAcquiringCommonStatus.ERROR_NOT_INITIALIZED)
      throw TinkoffError(message: 'Plugin is not initialized.');

    if (status.error != null) throw TinkoffError(message: status.error);

    return status;
  }
}
