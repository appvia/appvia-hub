class QuayAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, quay_access_token:, org:, global_robot_name:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @quay_access_token = quay_access_token
    @org = org
    @global_robot_name = global_robot_name
  end

  def create_repository(name, visibility: 'public')
    path = repo_path name
    body = {
      namespace: @org,
      name: name,
      spec: {
        robots: [
          {
            name: @global_robot_name,
            permission: 'write'
          }
        ],
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

  def get_repo_status(name)
    path = repo_status_path name
    client.get do |req|
      add_quay_access_token_header req
      req.url path
    end.body
  end

  private

  def add_quay_access_token_header(req)
    req.headers['X-Quay-Api-Token'] = @quay_access_token
  end

  def repo_path(name)
    "registry/#{@org}/#{name}"
  end

  def repo_status_path(name)
    "registry/#{@org}/#{name}/status"
  end
end
