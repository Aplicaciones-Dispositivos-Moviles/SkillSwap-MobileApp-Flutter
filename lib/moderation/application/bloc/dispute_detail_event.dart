part of 'dispute_detail_bloc.dart';

sealed class DisputeDetailEvent {
  const DisputeDetailEvent();
}

class DisputeEvidenceRequested extends DisputeDetailEvent {
  final int disputeId;

  const DisputeEvidenceRequested(this.disputeId);
}

// [verify] true verifica el certificado (Upheld); false lo rechaza (Overturned).
class DisputeResolutionSubmitted extends DisputeDetailEvent {
  final bool verify;
  final String notes;

  const DisputeResolutionSubmitted({required this.verify, required this.notes});
}
