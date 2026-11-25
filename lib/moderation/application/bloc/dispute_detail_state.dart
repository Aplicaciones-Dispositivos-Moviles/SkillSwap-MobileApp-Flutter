part of 'dispute_detail_bloc.dart';

sealed class DisputeDetailState {
  const DisputeDetailState();
}

class DisputeDetailLoading extends DisputeDetailState {
  const DisputeDetailLoading();
}

class DisputeDetailError extends DisputeDetailState {
  final String message;

  const DisputeDetailError(this.message);
}

class DisputeDetailLoaded extends DisputeDetailState {
  final DisputeEvidence evidence;
  final bool submitting;
  final String? error; // error al enviar la decisión (la disputa sigue en pantalla)
  final bool outdated; // 409: ya se resolvió o el certificado cambió; la lista hay que recargarla

  const DisputeDetailLoaded(this.evidence, {this.submitting = false, this.error, this.outdated = false});
}

// La decisión se registró: la disputa queda resuelta
class DisputeResolved extends DisputeDetailState {
  final DisputeEvidence evidence;
  final Dispute resolved;

  const DisputeResolved(this.evidence, this.resolved);
}
