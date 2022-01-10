public class Application : Gtk.Application {
    private ToastStack _top_right;
    private ToastStack _top_middle;
    private PolkitServer _pk_server;
    private NotificationServer _not_server;

    public Application () {
        Object (
            application_id: "org.wayfairings.notifications",
            flags : ApplicationFlags.CAN_OVERRIDE_APP_ID
            );
    }

    construct {
        _top_right = new ToastStack (new ToastAxis (GtkLayerShell.Edge.TOP, 10))
        {
            fixed_axis = new ToastAxis (GtkLayerShell.Edge.RIGHT, 10)
        };
        _top_middle = new ToastStack (new ToastAxis (GtkLayerShell.Edge.TOP, 10));
    }

    protected override void activate() {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/org/wayfairings/notifications/style.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        //GtkLayerShell.is_supported ();
        start_notifications ();
        start_polkit();

        hold ();
    }

    private void start_notifications() {
        _not_server = new NotificationServer ();
        Bus.own_name (BusType.SESSION, NotificationServer.BUS_NAME, BusNameOwnerFlags.NONE, (connection) => {
            try {
                connection.register_object (NotificationServer.OBJECT_PATH, _not_server);
            } catch ( GLib.IOError e ) {
                critical ("failed to register notifications server: %s", e.message);
                quit();
            }
        }, () => {}, (con, name) => {
            critical ("failed to acquire bus: %s", name);
            quit();
        });

        _not_server.notification_update = notification_update;
    }

    private uint32 notification_update(Notification notification) throws GLib.DBusError {
        var toast = _top_right.get_toast (ref notification.id, () => new NotificationToast ()) as NotificationToast;
        if( toast == null ){
            throw new DBusError.FAILED ("");
        }

        toast.update (notification);
        return notification.id;
    }

    private void start_polkit() {
        _pk_server = new PolkitServer();
        var pid = Posix.getpid();

        Polkit.Subject? subject = null;
        try {
            subject = new Polkit.UnixSession.for_process_sync (pid, null);
        } catch (Error e) {
            critical ("failed to create polkit session: %s", e.message);
            quit();
            return;
        }

        if (subject == null) {
            critical ("failed to create polkit listener");
            quit();
        }

        try {
            PolkitAgent.register_listener (_pk_server, subject, null);
        } catch (Error e) {
            critical ("failed to create polkit listener: %s", e.message);
            quit();
            return;
        }

        _pk_server.authentication_request = notification_request;
    }

    private void notification_request(Authn authn) throws Polkit.Error {
        uint32 id = 0;
        var toast = (AuthnToast) _top_middle.get_toast (ref id, () => new AuthnToast ());

        toast.begin (authn);
    }

    public static int main(string[] args) {
        return new Application ().run (args);
    }

}