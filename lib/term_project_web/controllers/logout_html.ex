defmodule TermProjectWeb.LogoutHTML do
  use TermProjectWeb, :html

  import TermProjectWeb.ErrorHelpers

  use PhoenixHTMLHelpers

  embed_templates "page_html/*"
end