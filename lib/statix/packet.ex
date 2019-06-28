defmodule Statix.Packet do
  @moduledoc false

  use Bitwise

  def build(:event, title, text, prefix, options) do
    title_len = title |> String.length() |> Integer.to_string()
    text_len = text |> String.length() |> Integer.to_string()

    [prefix, "_e{", title_len, ",", text_len, "}:", title, "|", text]
    |> set_ext_option("d", options[:timestamp])
    |> set_ext_option("h", options[:hostname])
    |> set_ext_option("k", options[:aggregation_key])
    |> set_ext_option("p", options[:priority])
    |> set_ext_option("s", options[:source_type_name])
    |> set_ext_option("t", options[:alert_type])
    |> set_option(:tags, options[:tags])
  end

  def build(:service_check, name, status, prefix, options) do
    [prefix, "_sc|", name]
    |> set_service_check_status(status)
    |> set_ext_option("d", options[:timestamp])
    |> set_ext_option("h", options[:hostname])
    |> set_option(:tags, options[:tags])
    |> set_ext_option("m", options[:message])
  end

  def build(name, key, val, prefix, options) do
    [prefix, key, ?:, val, ?|, metric_type(name)]
    |> set_option(:sample_rate, options[:sample_rate])
    |> set_option(:tags, options[:tags])
  end

  metrics = %{
    counter: "c",
    gauge: "g",
    histogram: "h",
    timing: "ms",
    set: "s"
  }

  for {name, type} <- metrics do
    defp metric_type(unquote(name)), do: unquote(type)
  end

  defp set_option(packet, _kind, nil) do
    packet
  end

  defp set_option(packet, :sample_rate, sample_rate) when is_float(sample_rate) do
    [packet | ["|@", :erlang.float_to_binary(sample_rate, [:compact, decimals: 2])]]
  end

  defp set_option(packet, :tags, []), do: packet

  defp set_option(packet, :tags, tags) when is_list(tags) do
    [packet | ["|#", Enum.join(tags, ",")]]
  end

  defp set_ext_option(packet, _opt_key, nil) do
    packet
  end

  defp set_ext_option(packet, opt_key, value) do
    [packet | [?|, opt_key, ?:, to_string(value)]]
  end

  defp set_service_check_status(packet, status) do
    stat =
      case status do
        "ok" -> ?0
        "warning" -> ?1
        "critical" -> ?2
        "unknown" -> ?3
        _ -> ?3
      end

    [packet | [?|, stat]]
  end
end
