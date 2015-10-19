class JsonParser < Lotus::Routing::Parsing::Parser
  def mime_types
    ['application/json', 'application/vnd.api+json']
  end

  def parse(body)
    parsed = JSON.parse(body)

    if parsed.is_a?(Array)
      { request_data: parsed }
    else
      parsed
    end
  rescue JSON::ParserError => e
    {terrible_hack: e}
  end
end
