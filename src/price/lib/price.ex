alias Nats.Client

defmodule Price do
  @derive [Poison.Encoder]
  defstruct [:product_id, :amount, :currency]
end

defmodule PriceService do
  @get_price "price.get"
  @set_price "price.set"

  def queue_group, do: "price-service"
  def get, do: @get_price
  def set, do: @set_price

  def receive_loop(pid) do
    receive_loop pid, Map.new
  end

  defp receive_loop(pid, prices) do
    new_prices =
      receive do
        msg ->
          {:msg, _, subject, reply, data} = msg
          product_price = Poison.decode!(data, as: %Price{})
          {out_msg, out_prices} =
            case subject do
              @get_price ->
                {get_price(product_price, prices), prices}
              @set_price ->
                set_price product_price, prices
            end
          if reply, do: Client.pub pid, reply, Poison.encode!(out_msg)
          out_prices
      end
    receive_loop pid, new_prices
  end

  defp get_price(product_price, prices) do
    IO.puts "Get price..."
    case product_price.product_id do
      nil -> %{:msg => "prodict_id is blank"}
      product_id -> Map.get prices, product_id, %Price{product_id: product_id}
    end
  end

  defp set_price(product_price, prices) do
    IO.puts "Set price..."
    case product_price.product_id do
      nil -> {%{:msg => "prodict_id is blank"}, prices}
      product_id ->
        {%{:msg => "price was set successfully!"},
          Map.update(prices, product_id, product_price, fn _ -> product_price end)}
    end
  end
end


IO.puts "Price service started..."
{:ok, pid} = Client.start_link
#receive do after 500 -> true end
Client.sub(pid, self(), PriceService.get, PriceService.queue_group);
Client.sub(pid, self(), PriceService.set, PriceService.queue_group);
PriceService.receive_loop(pid)
