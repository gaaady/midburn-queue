require "spec_helper"

RSpec.describe MidburnQueue do
  def app
    MidburnQueue
  end

  describe "POST status" do
    it 'should return 403 code' do
      Resque.redis.set "queue_is_open", "false"
      post "/status"
      expect(last_response.status).to eq 403
    end

    it 'should return open code' do
      Resque.redis.set "queue_is_open", "true"
      post "/status"
      expect(last_response.status).to eq 200
      expect(last_response.body).to include('register')
    end
  end
end
