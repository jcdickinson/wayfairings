public sealed class ToastStack {
    public delegate AbstractToast ToastFactory();

    private Gee.HashMap<uint32, AbstractToast> _windows;
    private AbstractToast ? _tail;
    private uint32 _id_factory;
    public ToastAxis ? fixed_axis { get; set; }
    public ToastAxis variable_axis { get; private set; }

    public ToastStack (ToastAxis variable_axis) {
        this.variable_axis = variable_axis;
        _windows = new Gee.HashMap<uint, AbstractToast> ();
    }

    public AbstractToast ? get_toast (ref uint id, ToastFactory factory) {
        AbstractToast ? toast = null;
        if( id == 0 ){
            id = ++_id_factory;
            toast = factory ();
            add_toast (id, toast);
        } else if( _windows.has_key (id)){
            toast = _windows[id];
            if( toast.closed ) return null;
        } else {
            return null;
        }

        return toast;
    }

    private void add_toast(uint id, AbstractToast toast) {
        _windows[id] = toast;

        if( _tail != null ) _tail.next = toast;
        toast.previous = _tail;
        _tail = toast;
        toast.destroy.connect (() => remove_toast (id));
        if( GtkLayerShell.is_supported ())
        {
            GtkLayerShell.init_for_window (toast);
            GtkLayerShell.set_namespace(toast, string name_space);
            GtkLayerShell.set_keyboard_mode(toast, GtkLayerShell.KeyboardMode.ON_DEMAND);
        }
        if( fixed_axis != null )
            set_axis (toast, fixed_axis.Edge, fixed_axis.Margin);

        rearrange (toast);
    }

    private void remove_toast(uint id) {
        AbstractToast toast;
        if( !_windows.unset (id, out toast)) return;

        var next = toast.next;
        var previous = toast.previous;
        if( previous != null ){
            previous.next = next;
        }
        if( next != null ){
            next.previous = previous;
        }
        if( _tail == toast ){
            _tail = previous;
        }
        rearrange (next);
    }

    private void rearrange(AbstractToast ? toast) {
        if( toast == null ) return;

        while( toast.previous != null ){
            toast = toast.previous;
        }

        var ofs = variable_axis.Margin;
        while( toast != null ){
            var previous = toast.previous;

            if( previous != null ){
                int width, height;
                previous.get_size (out width, out height);
                switch( variable_axis.Edge ){
                case GtkLayerShell.Edge.TOP:
                case GtkLayerShell.Edge.BOTTOM:
                    ofs += height;
                    break;
                default:
                    ofs += width;
                    break;
                }
            }

            set_axis (toast, variable_axis.Edge, ofs);
            toast = toast.next;
        }
    }

    private void set_axis(AbstractToast toast, GtkLayerShell.Edge edge, int margin) {
        if( GtkLayerShell.is_supported ()){
            GtkLayerShell.set_anchor (toast, edge, true);
            GtkLayerShell.set_margin (toast, edge, margin);
        } else {
            // TODO: Compatability
        }
    }

}