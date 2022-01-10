public sealed class AuthnToast : AbstractToast {

    private static Regex entity_regex;
    private static Regex tag_regex;

    static construct {
        try {
            entity_regex = new Regex ("&(?!amp;|quot;|apos;|lt;|gt;)");
            tag_regex = new Regex ("<(?!\\/?[biu]>)");
        } catch ( GLib.RegexError e ) {
            critical ("failed to create regex: %s", e.message);
        }
    }
    
    private Gtk.Label _title;
    private Gtk.Label _request;
    private Gtk.Entry _entry;
    private unowned Authn _authn;

    construct {
        default_width = 300;
        default_height = 20;
        type_hint = Gdk.WindowTypeHint.DIALOG;

        get_style_context ().add_class ("normal");
        get_style_context ().add_class ("login");

        _content.orientation = Gtk.Orientation.VERTICAL;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        _content.pack_start (top_box, true, true, 0);

        var icon = new Gtk.Image.from_gicon (new ThemedIcon ("dialog-information"), Gtk.IconSize.LARGE_TOOLBAR);
        top_box.pack_start (icon, false, true, 0);

        var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        top_box.pack_start (title_box, true, true, 0);

        _title = new Gtk.Label ("* title");
        _title.get_style_context ().add_class ("title");
        _title.set_alignment (0, 0.5f);
        title_box.pack_start (_title, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        _title.get_style_context ().add_class ("main_separator");
        title_box.pack_start (separator, false, true, 0);

        _request = new Gtk.Label("* request")
        {
            lines = 2,
            use_markup = true,
            xalign = 0,
        };
        _request.get_style_context ().add_class ("body");
        _content.pack_start (_request, false, true, 0);

        _entry = new Gtk.Entry ();
        _entry.get_style_context ().add_class ("entry");
        _content.pack_start (_entry, false, true, 0);
    }
    
    public void begin(Authn authn)
    {
        _authn = authn;
        authn.request.connect(on_request);
        authn.show_info.connect(on_request);
        authn.completed.connect(done);
        authn.cancelled.connect(done);
        show_all();
    }

    private void on_request(string message)
    {
        _request.set_text(message);
    }

    private void done()
    {
        close();
        destroy();
    }
}