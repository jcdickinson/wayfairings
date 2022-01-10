
public abstract class Authn {
    public signal void cancelled();
    public signal void completed();
    public signal void request(string message, bool echo);
    public signal void show_error(string message);
    public signal void show_info(string message);

    public abstract void authenticate(string password);
    public abstract void select_identity(AuthnIdentity identity);

    public uint id;
    public string message;
    public string icon_name;
    public Gee.List<AuthnIdentity> identities;
}

public class AuthnIdentity {
    public string name;
    public bool is_group;
    public bool is_self;
}