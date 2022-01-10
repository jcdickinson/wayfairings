public sealed class ToastAxis {
    public GtkLayerShell.Edge Edge { get; private set; }
    public int Margin { get; private set; }

    public ToastAxis (GtkLayerShell.Edge edge, int margin) {
        Edge = edge;
        Margin = margin;
    }

}