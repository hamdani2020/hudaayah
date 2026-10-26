/// A due vocabulary review item (from `/reviews/due/`).
class ReviewItem {
  final int id;
  final String itemType;
  final String contentRef;
  final String prompt;

  const ReviewItem({
    required this.id,
    required this.itemType,
    required this.contentRef,
    required this.prompt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
        id: j['id'] as int,
        itemType: j['item_type'] as String? ?? 'vocab',
        contentRef: j['content_ref'] as String? ?? '',
        prompt: j['prompt'] as String? ?? '',
      );
}
