{% set uses_db='DATABASE_URL' in env %}
{% set has_hosts='HOSTS' in env %}

{loglevel, {{ env['LOGLEVEL'] or 3 }} }.

{% if has_hosts %}
{% set host_names=env.get('HOSTS', '').split(',') %}
{hosts, ["{{ env['XMPP_DOMAIN'] or "chat.thegeoffrey.co" }}"
    {%- for host in host_names -%}
    ,"{{host}}"
    {%- endfor -%}
    ] }.
{% else %}
{hosts, ["{{ env['XMPP_DOMAIN'] or "chat.thegeoffrey.co" }}"] }.
{% endif %}


{listen,
 [

  { 80, ejabberd_cowboy, [
      {num_acceptors, 10},
      {max_connections, 2048},
      {modules, [
          {"localhost", "/api", mongoose_api, [{handlers, [mongoose_api_metrics,
                                                           mongoose_api_users]}]},
          {"_", "/http-bind", mod_bosh},
          {"_", "/ws-xmpp", mod_websockets}
      ]}
  ]},

  { 5000, ejabberd_c2s, [
            {access, c2s},
            {shaper, c2s_shaper},
            {max_stanza_size, 65536}
               ]}
 ]}.

{s2s_default_policy, deny }.

{outgoing_s2s_port, 5269 }.

{sm_backend, {mnesia, []} }.

{auth_method, [external, anonymous]}.
{auth_opts, [
             {extauth_program, "/usr/lib/mongooseim/bin/ext_auth"}
%%                        {allow_multiple_connections, false},
%%                        {anonymous_protocol, sasl_anon}
            ]}.


{%if uses_db -%}
{%- set protocol = env['DATABASE_URL'].split(':', 1)[0] %}
{%- set db_url = env['DATABASE_URL'].split('//', 1)[1] -%}
{odbc_server, {pgsql, "{{db_url.rsplit('/', 1)[0].rsplit(':', 1)[0].rsplit("@", 1)[1]}}", {{db_url.rsplit('/', 1)[0].rsplit(':', 1)[1]}}, "{{db_url.rsplit('/', 1)[1]}}", "{{db_url.rsplit('@', 1)[0].split(":")[0]}}", "{{db_url.rsplit('@', 1)[0].split(":")[1]}}"}}.
{pgsql_users_number_estimate, true}.
{%- endif %}


{shaper, normal, {maxrate, 1000}}.

{shaper, fast, {maxrate, 50000}}.

{max_fsm_queue, 1000}.

{acl, local, {user_regexp, ""}}.

%% Maximum number of simultaneous sessions allowed for a single user:
{access, max_user_sessions, [{10, all}]}.

%% Maximum number of offline messages that users can have:
{access, max_user_offline_messages, [{5000, admin}, {100, all}]}.

%% This rule allows access only for local users:
{access, local, [{allow, local}]}.

%% Only non-blocked users can use c2s connections:
{access, c2s, [{deny, blocked},
           {allow, all}]}.

%% For C2S connections, all users except admins use the "normal" shaper
{access, c2s_shaper, [{none, admin},
              {normal, all}]}.

%% All S2S connections use the "fast" shaper
{access, s2s_shaper, [{fast, all}]}.

%% Admins of this server are also admins of the MUC service:
{access, muc_admin, [{allow, admin}]}.

%% Only accounts of the local ejabberd server can create rooms:
{access, muc_create, [{allow, local}]}.

%% All users are allowed to use the MUC service:
{access, muc, [{allow, all}]}.

%% In-band registration allows registration of any possible username.
%% To disable in-band registration, replace 'allow' with 'deny'.
{access, register, [{allow, all}]}.

%% By default the frequency of account registrations from the same IP
%% is limited to 1 account every 10 minutes. To disable, specify: infinity
{registration_timeout, infinity}.

%% Default settings for MAM.
%% To set non-standard value, replace 'default' with 'allow' or 'deny'.
%% Only user can access his/her archive by default.
%% An online user can read room's archive by default.
%% Only an owner can change settings and purge messages by default.
%% Empty list (i.e. `[]`) means `[{deny, all}]`.
{access, mam_set_prefs, [{default, all}]}.
{access, mam_get_prefs, [{default, all}]}.
{access, mam_lookup_messages, [{default, all}]}.
{access, mam_purge_single_message, [{default, all}]}.
{access, mam_purge_multiple_messages, [{default, all}]}.

%% 1 command of the specified type per second.
{shaper, mam_shaper, {maxrate, 1}}.
%% This shaper is primeraly for Mnesia overload protection during stress testing.
%% The limit is 1000 operations of each type per second.
{shaper, mam_global_shaper, {maxrate, 1000}}.

{access, mam_set_prefs_shaper, [{mam_shaper, all}]}.
{access, mam_get_prefs_shaper, [{mam_shaper, all}]}.
{access, mam_lookup_messages_shaper, [{mam_shaper, all}]}.
{access, mam_purge_single_message_shaper, [{mam_shaper, all}]}.
{access, mam_purge_multiple_messages_shaper, [{mam_shaper, all}]}.

{access, mam_set_prefs_global_shaper, [{mam_global_shaper, all}]}.
{access, mam_get_prefs_global_shaper, [{mam_global_shaper, all}]}.
{access, mam_lookup_messages_global_shaper, [{mam_global_shaper, all}]}.
{access, mam_purge_single_message_global_shaper, [{mam_global_shaper, all}]}.
{access, mam_purge_multiple_messages_global_shaper, [{mam_global_shaper, all}]}.


{language, "en"}.

{modules,
 [
  {mod_admin_extra, [{submods, [node, accounts, sessions, vcard,
                                roster, last, private, stanza, stats]}]},
  {mod_adhoc, []},
  {mod_disco, []},
  {mod_last, []},
  {mod_stream_management, []},
  {mod_muc, [
             {host, "muc.@HOST@"},
             {access, muc},
             {access_create, muc_create}
            ]},
  {mod_muc_log,
        [
        {outdir, "/tmp/muclogs"},
        {access_log, muc}
        ]},
  {mod_offline, [{access_max_user_messages, max_user_offline_messages}]},
  {mod_privacy, []},
  {mod_register, [
          {welcome_message, {""}},
          {ip_access, [{allow, "127.0.0.0/8"},
                   {deny, "0.0.0.0/0"}]},
          {access, register}
         ]},
  {mod_roster, []},
  {mod_sic, []},
  {mod_bosh, []},
  {mod_websockets, []},
  {mod_metrics, []},
  {mod_carboncopy, []}

  %%
  %% Message Archive Management (MAM) for registered users.
  %%

  %% A module for storing preferences in RDBMS (used by default).
  %% Enable for private message archives.
% {mod_mam_odbc_prefs, [pm]},
  %% Enable for multiuser message archives.
% {mod_mam_odbc_prefs, [muc]},
  %% Enable for both private and multiuser message archives.
  {mod_mam_odbc_prefs, [pm, muc]},

  %% A module for storing preferences in Mnesia (recommended).
  %% This module will be called each time, as a message is routed.
  %% That is why, Mnesia is better for this job.
% {mod_mam_mnesia_prefs, [pm, muc]},

  %% Mnesia back-end with optimized writes and dirty synchronious writes.
% {mod_mam_mnesia_dirty_prefs, [pm, muc]},

  %% A back-end for storing messages.
  %% Synchronious writer (used by default).
  %% This writer is easy to debug, but writing performance is low.
% {mod_mam_odbc_arch, [pm]},

  %% Enable the module with a custom writer.
% {mod_mam_odbc_arch, [no_writer, pm]},

  %% Asynchronious writer for RDBMS (recommended).
  %% Messages will be grouped and inserted all at once.
% {mod_mam_odbc_async_writer, [pm]},

  %% A pool of asynchronious writers (recommended).
  %% Messages will be grouped together based on archive id.
% {mod_mam_odbc_async_pool_writer, [pm]},

  %% A module for converting an archive id to an integer.
  %% Extract information using ODBC.
% {mod_mam_odbc_user, [pm, muc]},

  %% Cache information about users (recommended).
  %% Requires mod_mam_odbc_user or alternative.
% {mod_mam_cache_user, [pm, muc]},

  %% Enable MAM.
  {mod_mam, []},


  %%
  %% Message Archive Management (MAM) for multi-user chats (MUC).
  %% Enable XEP-0313 for "muc.@HOST@".
  %%

  %% A back-end for storing messages (default for MUC).
  %% Modules mod_mam_muc_* are optimized for MUC.
  %%
  %% Synchronious writer (used by default for MUC).
  %% This module is easy to debug, but performance is low.
% {mod_mam_muc_odbc_arch, []},
% {mod_mam_muc_odbc_arch, [no_writer]},

  %% Asynchronious writer for RDBMS (recommended for MUC).
  %% Messages will be grouped and inserted all at once.
% {mod_mam_muc_odbc_async_writer, []},
% {mod_mam_muc_odbc_async_pool_writer, []},

  %% Load mod_mam_odbc_user too.

  %% Enable MAM for MUC
 {mod_mam_muc, [{host, "muc.@HOST@"}]}


  %%
  %% MAM configuration examples
  %%

  %% Only MUC, no user-defined preferences, good performance.
% {mod_mam_odbc_user, [muc]},
% {mod_mam_cache_user, [muc]},
% {mod_mam_muc_odbc_arch, [no_writer]},
% {mod_mam_muc_odbc_async_pool_writer, []},
% {mod_mam_muc, [{host, "muc.@HOST@"}]}

  %% Only archives for c2c messages, good performance.
% {mod_mam_odbc_user, [pm]},
% {mod_mam_cache_user, [pm]},
% {mod_mam_mnesia_dirty_prefs, [pm]},
% {mod_mam_odbc_arch, [pm, no_writer]},
% {mod_mam_odbc_async_pool_writer, [pm]},
% {mod_mam, []}

  %% Basic configuration for c2c messages, bad performance, easy to debug.
% {mod_mam_odbc_user, [pm]},
% {mod_mam_odbc_prefs, [pm]},
% {mod_mam_odbc_arch, [pm]},
% {mod_mam, []}

  %% Cassandra c2c conversations.
  %% All queries MUST contain "with" element.
  %% No custom settings supported (always archive).
% {mod_mam_odbc_user, [pm]},
% {mod_mam_cache_user, [pm]},
% {mod_mam_con_ca_arch, [pm]},
% {mod_mam, []}

  %% Cassandra muc conversations.
  %% No custom settings supported (always archive).
% {mod_mam_odbc_user, [muc]},
% {mod_mam_cache_user, [muc]},
% {mod_mam_muc_ca_arch, []},
% {mod_mam_muc, [{host, "muc.@HOST@"}]}

 ]}.


%%
%% Enable modules with custom options in a specific virtual host
%%
%%{host_config, "localhost",
%% [{ {add, modules},
%%   [
%%    {mod_some_module, []}
%%   ]
%%  }
%% ]}.

%%%.
%%%'

%%% $Id$

%%% Local Variables:
%%% mode: erlang
%%% End:
%%% vim: set filetype=erlang tabstop=8 foldmarker=%%%',%%%. foldmethod=marker:
%%%.
