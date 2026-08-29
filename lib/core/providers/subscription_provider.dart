import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class SubscriptionState {
  final bool isActive;
  final String? qrCodeUrl;
  final double price;
  final String? upiId;
  final String? supportPhone;
  final String? supportEmail;
  final String? suspensionMessage;

  const SubscriptionState({
    this.isActive = true,
    this.qrCodeUrl,
    this.price = 0,
    this.upiId,
    this.supportPhone,
    this.supportEmail,
    this.suspensionMessage,
  });
}

final subscriptionStateProvider = Provider<SubscriptionState>((ref) {
  final clubProfile = ref.watch(clubProfileProvider).value;
  final platformConfig = ref.watch(platformConfigProvider).value;

  final rawUpi = platformConfig?.upiId;
  final upiId = (rawUpi != null && rawUpi.isNotEmpty) ? rawUpi : '9643061442@ptaxis';
  
  final price = clubProfile?.subscriptionPrice ?? platformConfig?.subscriptionPrice ?? 2999.0;

  return SubscriptionState(
    isActive: clubProfile?.isActive ?? true, // default to true if no club yet, routing handles no-club
    qrCodeUrl: platformConfig?.paymentQrUrl,
    price: price,
    upiId: upiId,
    supportPhone: platformConfig?.supportPhone,
    supportEmail: platformConfig?.supportEmail,
    suspensionMessage: clubProfile?.suspensionMessage,
  );
});
