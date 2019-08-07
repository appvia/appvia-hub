class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role
end
