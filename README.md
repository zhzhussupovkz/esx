# Esx 
Search and dump from elasticsearch cluster. Use erlang [http://erlang.org/doc/man/httpc.html](http://erlang.org/doc/man/httpc.html) module for requests

## Run esdump mix task

```elixir
defmodule Mix.Tasks.Esdump do
  use Mix.Task

  def run(args) do
    es = Enum.at(args, 0) # elasticsearch address host:port (192.168.0.1:9200)
    index = Enum.at(args, 1) # elasticsearch index name (for example: books)
    :logger.info "elasticsearch #{es}"
    :logger.info "index dump: #{index}" 
    with :ok <- File.mkdir_p(Path.dirname("./#{index}_dump.json")) do
      Esx.Req.scroll(es, index, nil)
    end
    pid = spawn fn -> 1 + 1 end
    {:ok, pid}
  end
end
```

## Examples
Dump elasticsearch data from host 192.168.0.5 port 11200 and index phones:
```console
mix esdump 192.168.0.5:11200 phones
```

Dump elasticsearch data from host 10.10.6.17 port 9200 and index books:
```console
mix esdump 10.10.6.17:9200 books
```
