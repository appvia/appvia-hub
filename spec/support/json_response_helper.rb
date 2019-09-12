module JsonResponseHelper
  def is_json_response?
    response.content_type == 'application/json'
  end

  def json_response
    JSON.parse(response.body)
  end

  def pluck_from_json_response(field)
    json_response.map { |h| h[field] }
  end
end
