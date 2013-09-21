json.array!(@photos) do |photo|
  json.extract! photo, :name, :image, :description, :short_description, :published, :published_at, :order
  json.url photo_url(photo, format: :json)
end
