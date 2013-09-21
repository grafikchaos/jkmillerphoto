# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :photo do
    name "MyString"
    image "MyString"
    description "MyText"
    short_description "MyText"
    published false
    published_at "2013-09-19 21:45:35"
    order 1
  end
end
