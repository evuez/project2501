# Project2501

An Elixir client for Firefox's [Marionette](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/Protocol).

## Installation

Add `project2501` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:project2501, "~> 0.1.0"}]
end
```

Then configure the `host` and `port` of the server:

```elixir
config :project2501,
  host: 'localhost',
  port: 2828
```

## Example

Start Firefox with Marionette running:

    firefox --marionette

Then from `iex`:

```elixir
iex> Project2501.order("Navigate", %{url: "http://example.org"})
%Project2501.Wire.Response{error: nil, message_id: 829347167, result: %{}}

iex> Project2501.order("TakeScreenshot")
%Project2501.Wire.Response{error: nil, message_id: 392313200, result: %{"value" => ...}}
```
