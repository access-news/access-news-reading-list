# Access News Reading Lists

## Note on reloading the page when ads change

The notion is to reload when any content changes on the backend. Server Sent Events would have been more lightweight, but used Phoenix channels (i.e., websockets) as it would have to be set up anyway at one point.
The ads are currently images in `./assets/static/images` (and as a corollary, `./priv/static/images`), and a channel message ("load_ads") will be broadcasted manually to reload pages.

```elixir
%Phoenix.Socket{
  pubsub_server: Anrl.PubSub,
  topic:  "ads:changed",
  joined: true
}
|> Phoenix.Channel.broadcast("load_ads", %{})
```

> TODO: Only reload sections where content has changed.
>
> At the moment, the  entire webpage is reloaded, even
> if only the Safeway ads have been updated.

> TODO: How to automate page reloading?
>
> Look  into Webpack,  it  is surely  able to  monitor
> changes in `./assets`.
>
> On the  other hand, it  would probably be  better to
> move  on to  serving these  from a  CDN in  the long
> haul.

> TODO: How  to query  the ETS  table where  the channel
>       subscriptions are stored?
>
> Got it easy here, because only needed to send a broadcast, where the socket can be constructed above by hand (shouldn't even need a socket), instead of needing to save specific socket after join.
>
> The way to do the latter would be:
>
> ```elixir
> def join("ads:changed", payload, socket) do
>
>   send(self, :after_join)
>
>   {:ok, socket}
> end
>
> def handle_info(:after_join, socket) do
>
>   # Do whatever with `socket`, which will have
>   # `joined: true` at this point.
>
>   {:noreply, socket}
> end
> ```

### `Phoenix.Channel.(broadcast/3|push/3)`

Broadcasts only  need `:pubsub_server`  and `:topic`
from  the `Phoenix.Socket`  struct, and  pushes need
`:transport_pid`  and `:topic`.  The latter  answers
how are  sockets (clients?) identified.  (TODO: look
up the spec and dispel this confusion.)

A sample socket:

```elixir
%Phoenix.Socket{
  assigns: %{},
  channel: AnrlWeb.AdsChannel,
  channel_pid: #PID<0.453.0>,
  endpoint: AnrlWeb.Endpoint,
  handler: AnrlWeb.UserSocket,
  id: nil,
  join_ref: "5",
  joined: false,
  private: %{log_handle_in: :debug, log_join: :info},
  pubsub_server: Anrl.PubSub,
  ref: nil,
  serializer: Phoenix.Socket.V2.JSONSerializer,
  topic: "ads:changed",
  transport: :websocket,
  transport_pid: #PID<0.449.0>
}
```

`broadcast/3`  checks whether  `:joined` is  `true`;
seems superfluous, but it isn't (see [PR #3501](https://github.com/phoenixframework/phoenix/pull/3501)).

## Project start instructions

(Remainder from after project generation.)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
