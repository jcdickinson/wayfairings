
[DBus (name = "org.freedesktop.Notifications")]
public sealed class NotificationServer : Object {
    public const string INTERFACE_NAME = "org.freedesktop.Notifications";
    public const string BUS_NAME = "org.freedesktop.Notifications";
    public const string OBJECT_PATH = "/org/freedesktop/Notifications";

    internal delegate uint32 NotificationUpdate(Notification notification) throws GLib.DBusError;

    internal NotificationUpdate notification_update;

    [DBus (name = "GetCapabilities")]
    public string[] get_capabilities() throws DBusError, IOError {
        return {
                   "body",
                   "body-markup",
        };
    }

    [DBus (name = "GetServerInformation")]
    public void get_server_information(out string name,
                                       out string vendor,
                                       out string version,
                                       out string spec_version) throws DBusError, IOError {
        name = "org.wayfairings.notify";
        vendor = "Wayfairings Notify";
        version = "0.0.1";
        spec_version = "1.2";
    }

    [DBus (name = "Notify")]
    public new uint32 notify(string app_name,
                             uint32 replaces_id,
                             string app_icon,
                             string summary,
                             string body,
                             string[] actions,
                             HashTable<string, Variant> hints,
                             int32 expire_timeout,
                             BusName sender) throws DBusError, IOError {
        var n = new Notification ()
        {
            id = replaces_id,
            app_name = app_name,
            app_icon = app_icon,
            summary = summary,
            body = body,
        };
        return notification_update (n);
    }

}