**ACCEPT**

Reviewed [belief-collision.diff](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-collision.diff):

- `BeliefGraphGeometry.captionFits` ([belief-collision.diff](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-collision.diff#L10-L15)) rejects captions within `4px` of any `nodeRect` or previously painted caption.
- `_EdgePainter.paint` ([belief-collision.diff](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-collision.diff#L23-L35)) draws the edge line and arrowheads first, then skips only colliding caption labels while preserving full relationship details in semantics and the detail list.
- Unit assertions ([belief-collision.diff](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-collision.diff#L45-L49)) cover adjacent fit, duplicate rejection, and `0 → 2` midpoint collision with intermediate node `1`.

No blocking bugs found.
