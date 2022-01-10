public abstract class AbstractToast : Gtk.Window {
    private uint _close_timeout;
    protected Gtk.Box _content;
    public bool closed { get; private set; }
    public AbstractToast ? previous { get; set; }
    public weak AbstractToast ? next { get; set; }

    construct
    {
        resizable = false;
        decorated = false;
        vexpand = true;
        closed = false;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        
        _content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        _content.get_style_context ().add_class ("content");
        add (_content);
    }

    protected void clear_timeout() {
        if( _closed ) return;
        if( _close_timeout != 0 ){
            Source.remove (_close_timeout);
            _close_timeout = 0;
        }
    }

    protected void set_timeout(uint duration) {
        if( _closed ) return;
        clear_timeout ();
        _close_timeout = GLib.Timeout.add (duration, () => {
            _close_timeout = 0;
            _closed = true;
            timeout_close ();
            return false;
        });
    }

    protected virtual void timeout_close() {
        close ();
        destroy ();
    }

}