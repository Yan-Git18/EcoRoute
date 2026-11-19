class ReportCommunitySummary {
  final int supportCount;
  final int ratingCount;
  final int ratingTotal;

  const ReportCommunitySummary({
    this.supportCount = 0,
    this.ratingCount = 0,
    this.ratingTotal = 0,
  });

  double? get averageRating =>
      ratingCount == 0 ? null : ratingTotal / ratingCount;
}

class ReportParticipation {
  final bool supported;
  final int? rating;

  const ReportParticipation({this.supported = false, this.rating});
}
