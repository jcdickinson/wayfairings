public sealed class NotificationToast : AbstractToast {

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

    private bool _shown;
    private Gtk.Label _summary;
    private Gtk.Label _body;

    construct {
        focus_on_map = false; 
        can_focus = false;
        accept_focus = false;
        default_width = 300;
        default_height = 20;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        skip_taskbar_hint = true;

        get_style_context ().add_class ("normal");
        get_style_context ().add_class ("notification");

        _content.orientation = Gtk.Orientation.VERTICAL;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        _content.pack_start (top_box, true, true, 0);

        var icon = new Gtk.Image.from_gicon (new ThemedIcon ("dialog-information"), Gtk.IconSize.LARGE_TOOLBAR);
        top_box.pack_start (icon, false, true, 0);

        var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        top_box.pack_start (title_box, true, true, 0);

        _summary = new Gtk.Label ("* title");
        _summary.get_style_context ().add_class ("title");
        _summary.set_alignment (0, 0.5f);
        title_box.pack_start (_summary, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        _summary.get_style_context ().add_class ("main_separator");
        title_box.pack_start (separator, false, true, 0);

        _body = new Gtk.Label ("* body")
        {
            lines = 2,
            use_markup = true,
            xalign = 0,
        };
        _body.get_style_context ().add_class ("body");
        _content.pack_start (_body, false, true, 0);

        enter_notify_event.connect (() => {
            clear_timeout ();
        });
        leave_notify_event.connect (() => {
            reset_timeout (true);
        });
    }

    private void reset_timeout(bool unhover) {
        set_timeout (unhover ? 1000 : 4000);
    }

    public void update(Notification toast) {
        if( closed ) return;

        _summary.set_text (toast.summary);
        _body.set_markup (fix_markup (toast.body));

        reset_timeout (false);

        if( !_shown ) show_all ();
    }

    private string fix_markup(string markup) {
        var text = markup;

        print ("%s", markup);
        try {
            text = entity_regex.replace (markup, markup.length, 0, "&amp;");
            text = tag_regex.replace (text, text.length, 0, "&lt;");
        } catch ( Error e ) {
            warning ("Invalid regex: %s", e.message);
        }
        print ("%s", markup);

        return text;
    }

}