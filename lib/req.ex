defmodule Esx.Req do

  # post request to elastic
  defp post_req(url, data, headers) do
    req_url = url |> to_charlist
    http_options = []
    options = []
    case :httpc.request(:post, {req_url, headers, 'application/json', data}, http_options, options) do
      {:ok, {{_, code, _}, resp_headers, body}} ->
        case code do
          200 ->
            :logger.info "POST request: #{req_url}"
            page = body |> :unicode.characters_to_list |> :erlang.list_to_binary
            {resp_headers, page}
          _ ->
            :logger.error "POST request error code #{code} :("
            nil
        end
      {:error, _, _} ->
        :logger.error "POST request: #{req_url} error"
        nil
      {:error, _} ->
        :logger.error "POST request: #{req_url} error"
        nil
    end
  end
  
  # search from es by post request
  def search(es_url, index) do
    headers = [{'content-type', 'application/json'}]
    data = "{\"query\" : {\"match_all\" : {}}, \"size\" : 10}"
    url = "http://#{es_url}/#{index}/_search" |> to_charlist
    data_page = post_req(url, data, headers)
    case data_page do
      nil -> 
        :logger.error "error parse result from: #{url}"
        []
      {:error, _, _} -> 
        :logger.error "error parse result from: #{url}"
        []
      {_, data_page} -> 
        case Poison.decode(data_page) do
          {:ok, value} -> save(index, value)
          {:error, _} -> []
        end
    end
  end

  # scroll request by scroll_id
  def scroll_req(es_url, scroll_id) do
    headers = [{'content-type', 'application/json'}]
    data = "{\"scroll\" : \"5m\", \"scroll_id\" : \"#{scroll_id}\"}"
    url = "http://#{es_url}/_search/scroll" |> to_charlist
    data_page = post_req(url, data, headers)
    case data_page do
      nil -> 
        :logger.error "error parse result from: #{url}"
        []
      {:error, _, _} -> 
        :logger.error "error parse result from: #{url}"
        []
      {_, data_page} -> 
        case Poison.decode(data_page) do
          {:ok, value} -> value
          {:error, _} -> nil
        end
    end
  end

  # scroll index
  def scroll_index_req(es_url, index) do
    headers = [{'content-type', 'application/json'}]
    data = "{\"query\" : {\"match_all\" : {}}, \"size\" : 1000}"
    url = "http://#{es_url}/#{index}/_search?scroll=5m" |> to_charlist
    data_page = post_req(url, data, headers)
    case data_page do
      nil -> 
        :logger.error "error parse result from: #{url}"
        []
      {:error, _, _} -> 
        :logger.error "error parse result from: #{url}"
        []
      {_, data_page} -> 
        case Poison.decode(data_page) do
          {:ok, value} -> value
          {:error, _} -> nil
        end
    end
  end

  # scroll API
  def scroll(es_url, index, scroll_id) do
    case scroll_id do
      nil -> 
        body = scroll_index_req(es_url, index)  
        case body do
          nil -> :logger.info "Data not found or nil :("
          _ ->
            save(index, body)
            scroll_size = body |> get_in(["hits", "hits"]) |> length
            scroll_id = body["_scroll_id"]
            cond do
              scroll_size > 0 -> scroll(es_url, index, scroll_id) 
              true -> :logger.info "Finished :)"
            end
        end
      _ ->
        body = scroll_req(es_url, scroll_id)
        case body do
          nil -> :logger.info "Data not found or nil :("
          _ ->
            save(index, body)
            scroll_size = body |> get_in(["hits", "hits"]) |> length
            scroll_id = body["_scroll_id"]
            cond do
              scroll_size > 0 -> scroll(es_url, index, scroll_id) 
              true -> :logger.info "Finished :)"
            end
        end
    end
  end

  # send results
  defp save(index, result) do
    result |> get_in(["hits", "hits"])
    #|> Flow.from_enumerable()
    #|> Flow.partition()
    #|> Flow.map(&save/1)
    |> Enum.map(&(Task.async(fn -> save_row(index, &1) end)))
    |> Task.yield_many(5000)
    |> Enum.map(fn {task, result} -> result || Task.shutdown(task, :brutal_kill) end)
  end

  # save results
  defp save_row(index, row) do
    File.write("./#{index}_dump.json", "#{Poison.encode!(row)}\n", [:append])
    :logger.info "write: #{Poison.encode!(row)}..." 
  end
end

