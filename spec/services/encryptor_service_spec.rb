require 'rails_helper'

describe EncryptorService, type: :service do
  let(:secret_key_base) { SecureRandom.base64(100) }
  let(:string) { 'my secret string' }

  before do
    @service = EncryptorService.new(secret_key_base)
  end

  it 'should encrypt and decrypt a string as expected' do
    expect(@service.decrypt(@service.encrypt(string))).to eq string
  end

  it 'should be tied to that specific secret key' do
    other_secret_key_base = SecureRandom.base64(100)
    other_service = EncryptorService.new(other_secret_key_base)

    expect(other_service.decrypt(other_service.encrypt(string))).to eq string
    expect(@service.decrypt(other_service.encrypt(string))).to eq nil
    expect(other_service.decrypt(@service.encrypt(string))).to eq nil
  end
end
