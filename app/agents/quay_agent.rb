class QuayAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, quay_access_token:, org:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @quay_access_token = quay_access_token
    @org = org
  end

  # `robots` is expected to be an array of hashes, of the form:
  # [
  #   { name: '<name>', permission: 'admin|none|read|write' },
  #   ...
  # ]
  def create_repository(name, visibility: 'public', robots: [])
    path = repo_path name
    body = {
      namespace: @org,
      name: name,
      spec: {
        robots: robots,
        visibility: visibility
      }
    }
    client.put do |req|
      add_quay_access_token_header req
      req.url path
      req.body = body
    end.body
  end

  def delete_repository(name)
    path = repo_path name
    client.delete do |req|
      add_quay_access_token_header req
      req.url path
    end.body
  end

  def create_robot_token(name, description)
    path = robot_path name
    body = {
      namespace: @org,
      name: name,
      spec: {
        description: description
      }
    }
    client.put do |req|
      add_quay_access_token_header req
      req.url path
      req.body = body
    end.body
  end

  def delete_robot_token(name)
    path = robot_path name
    client.delete do |req|
      add_quay_access_token_header req
      req.url path
    end.body
  end

  def get_repo_status(name)
    path = repo_status_path name
    client.get do |req|
      add_quay_access_token_header req
      req.url path
    end.body
  end

  def vuln_url(name, digest)
    "https://quay.io/repository/#{@org}/#{name}/manifest/#{digest}?tab=vulnerabilities"
  end

  private

  def add_quay_access_token_header(req)
    req.headers['X-Quay-Api-Token'] = @quay_access_token
  end

  def repo_path(name)
    "registry/#{@org}/#{name}"
  end

  def repo_status_path(name)
    "registry/#{@org}/#{name}/status?limit=5"
  end

  def robot_path(name)
    "robots/#{@org}/#{name}"
  end
end
