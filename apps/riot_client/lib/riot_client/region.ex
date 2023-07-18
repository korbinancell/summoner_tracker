defmodule RiotClient.Region do
  @moduledoc """
  Handle league & riot api regions
  """

  @type region :: String.t()

  @regions ~w(br1 eun1 euw1 jp1 kr la1 la2 na1 oc1 ph2 ru sg2 th2 tr1 tw2 vn2)

  @spec region?(region) :: boolean()
  def region?(region), do: region in @regions

  @spec to_region_group(region) :: String.t()
  def to_region_group(region) when region in ["na1", "br1", "la1", "la2"], do: "americas"
  def to_region_group(region) when region in ["kr", "jp1"], do: "asia"
  def to_region_group(region) when region in ["eun1", "euw1", "tr1", "ru"], do: "europe"
  def to_region_group(region) when region in ["oc1", "ph2", "sg2", "th2", "tw2", "vn2"], do: "sea"
end
