class TRange
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url,  type: String
  field :data, type: String

  validates :url, :data, presence: true
  validates :url, format: {
    with: URI::regexp(%w(http https))
  }

  belongs_to :user_store

  def res
    {data: data, created_at: created_at.getlocal("+08:00")}
  end
end
