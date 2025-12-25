#if !Editor
@available(*, unavailable, message: "EditorEngine requires the Editor trait. Build with --traits Editor.")
public enum EditorEngine {}
#endif
