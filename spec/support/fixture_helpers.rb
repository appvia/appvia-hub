module FixtureHelpers
  RSpec.shared_context 'fixture helpers' do
    def load_json_fixture(path)
      JSON.parse file_fixture(path).read
    end
  end
end
