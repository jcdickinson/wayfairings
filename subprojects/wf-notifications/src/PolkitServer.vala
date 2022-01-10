public class PolkitServer : PolkitAgent.Listener {
    private sealed class PolkitAuthn : Authn {
        public string cookie;
        public bool was_cancelled;
        private unowned SourceFunc _fn;
        private unowned GLib.Cancellable ? _cancellable;

        private PolkitIdentity _selected_identity;
        private PolkitAgent.Session _session;
        ulong _error;
        ulong _request;
        ulong _info;
        ulong _complete;


        public PolkitAuthn (GLib.Cancellable ? cancellable, SourceFunc fn) {
            _cancellable = cancellable;
            if( cancellable != null )
                cancellable.cancelled.connect (cancel);
            _fn = fn;
        }

        public override void authenticate(string response) {
            _session.response (response);
        }

        public void cancel() {
            was_cancelled = true;
            cancelled ();
        }

        private void destroy_session() {
            if( _session != null ){
                SignalHandler.disconnect (_session, _error);
                SignalHandler.disconnect (_session, _complete);
                SignalHandler.disconnect (_session, _request);
                SignalHandler.disconnect (_session, _info);
                _session = null;
            }
        }

        private void create_session() {
            destroy_session ();
            _session = new PolkitAgent.Session (_selected_identity.identity, cookie);
            _error = _session.show_error.connect (message => show_error (message));
            _complete = _session.completed.connect (on_completed);
            _request = _session.request.connect ((message, echo) => request (message, echo));
            _info = _session.show_info.connect (message => show_info (message));
            _session.initiate ();
        }

        public override void select_identity(AuthnIdentity identity) {
            destroy_session ();
            _selected_identity = (PolkitIdentity) identity;
            create_session ();
        }

        private void on_completed(bool gained_authorization) {
            if( !gained_authorization || _cancellable.is_cancelled ()){
                if( !was_cancelled ){
                    show_error ("Authentication failed. Please try again.");
                }
                create_session ();
            } else {
                completed ();
            }
        }

    }

    private sealed class PolkitIdentity : AuthnIdentity {
        public Polkit.Identity identity;
    }

    internal delegate void AuthenticationRequest(Authn notification) throws Polkit.Error;

    internal AuthenticationRequest authentication_request;

    private Gee.HashMap<uint, PolkitAuthn> _pending;
    private uint _id_factory;

    public PolkitServer () {
        _pending = new Gee.HashMap<uint, PolkitAuthn> ();
    }

    public override async bool initiate_authentication(string action_id, string message, string icon_name,
                                                       Polkit.Details details, string cookie, GLib.List<Polkit.Identity> identities, GLib.Cancellable ? cancellable) throws Polkit.Error {
        if( identities == null ){
            return false;
        }

        var self = Environment.get_user_name ();

        var idents = new Gee.ArrayList<AuthnIdentity>();
        foreach(unowned var ident in identities){
            if( ident == null ) continue;
            var unix_user = ident as Polkit.UnixUser;
            var unix_group = ident as Polkit.UnixGroup;
            if( unix_user != null ){
                unowned Posix.Passwd ? user = Posix.getpwuid (unix_user.get_uid ());
                if( user != null ){
                    idents.add (new AuthnIdentity () {
                        name = user.pw_name,
                        is_group = true,
                        is_self = user.pw_name == self
                    });
                }
            } else if( unix_group != null ){
                unowned Posix.Group ? group = Posix.getgrgid (unix_group.get_gid ());
                if( group != null ){
                    idents.add (new AuthnIdentity () {
                        name = group.gr_name,
                        is_group = true
                    });
                }
            } else {
                idents.add (new AuthnIdentity () {
                    name = ident.to_string()
                });
            }
        }

        var id = ++_id_factory;
        var pending = new PolkitAuthn (cancellable, initiate_authentication.callback)
        {
            id = id,
            message = message,
            icon_name = icon_name,
            cookie = cookie,
            identities = idents
        };
        authentication_request (pending);
        yield;

        if( pending.was_cancelled ){
            throw new Polkit.Error.CANCELLED ("Authentication dialog was dismissed by the user");
        }

        return true;
    }

}
